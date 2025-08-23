## Y-CRDT Document Synchronization Protocol
##
## This module implements the network synchronization protocol for Y-CRDT documents
## across multiple ZenContexts. It extends the existing model_citizen networking 
## infrastructure to support CRDT-specific synchronization.

import std/[tables, sets, json, base64, times, strformat]
import pkg/flatty
import model_citizen/[core, types {.all.}]
import ./[crdt_types, document_coordinator, ycrdt_futhark]

type
  CrdtSyncKind* = enum
    ## Types of CRDT synchronization messages
    DocumentSync,      ## Regular sync update between peers
    DocumentRequest,   ## Request for missing document state
    DocumentResponse   ## Response to a document request
    
  CrdtSyncMessage* = object
    ## Message type for CRDT synchronization between contexts
    case kind*: CrdtSyncKind
    of DocumentSync:
      document_id*: DocumentId
      state_vector*: string    ## Base64 encoded Y-CRDT state vector
      update_data*: string     ## Base64 encoded Y-CRDT update
    of DocumentRequest:
      requested_doc_id*: DocumentId
      request_vector*: string  ## State vector of requesting context
    of DocumentResponse:
      response_doc_id*: DocumentId
      response_data*: string   ## Full document state or incremental update

  CrdtSyncManager* = ref object
    ## Manages CRDT synchronization for a ZenContext
    ctx*: ZenContext
    coordinator*: DocumentCoordinator
    active_syncs*: Table[string, CrdtSyncState]  ## Context ID -> sync state
    pending_requests*: Table[DocumentId, MonoTime]  ## Pending document requests
    last_sync_vectors*: Table[DocumentId, string]   ## Last known state vectors
    send_proc*: proc(ctx: ZenContext, target_ctx_id: string, message: CrdtSyncMessage) {.gcsafe.}  ## Message sending callback

  CrdtSyncState* = object
    ## State of CRDT synchronization with a remote context
    remote_ctx_id*: string
    connected_at*: MonoTime
    last_sync*: MonoTime
    documents*: HashSet[DocumentId]
    pending_updates*: seq[CrdtSyncMessage]

# Global sync manager per context
var context_sync_managers {.threadvar.}: Table[string, CrdtSyncManager]

# Forward declarations
proc send_crdt_message*(ctx: ZenContext, target_ctx_id: string, message: CrdtSyncMessage) {.gcsafe.}

proc init_crdt_sync_manager*(ctx: ZenContext): CrdtSyncManager =
  ## Initialize CRDT sync manager for a context
  result = CrdtSyncManager()
  result.ctx = ctx
  result.coordinator = get_global_coordinator()
  result.active_syncs = init_table[string, CrdtSyncState]()
  result.pending_requests = init_table[DocumentId, MonoTime]()
  result.last_sync_vectors = init_table[DocumentId, string]()

proc get_crdt_sync_manager*(ctx: ZenContext): CrdtSyncManager =
  ## Get or create CRDT sync manager for context
  if ctx.id notin context_sync_managers:
    context_sync_managers[ctx.id] = init_crdt_sync_manager(ctx)
  result = context_sync_managers[ctx.id]

proc extract_state_vector*(doc: ptr YDoc_typedef): string =
  ## Extract Y-CRDT state vector from document
  when defined(with_ycrdt):
    let txn = ydoc_read_transaction(doc)
    if txn != nil:
      defer: ytransaction_free(txn)
      let state_vector = ydoc_encode_state_vector(doc, txn)
      if state_vector.len > 0:
        result = encode(cast[string](state_vector))
      else:
        result = ""
    else:
      result = ""
  else:
    result = ""

proc create_update_from_state*(doc: ptr YDoc_typedef, remote_vector: string): string =
  ## Create Y-CRDT update based on remote state vector
  when defined(with_ycrdt):
    if remote_vector == "":
      return ""
      
    try:
      let decoded_vector = decode(remote_vector)
      let txn = ydoc_read_transaction(doc)
      if txn != nil:
        defer: ytransaction_free(txn)
        let update_data = ydoc_encode_state_as_update(doc, txn, decoded_vector.cstring)
        if update_data.len > 0:
          result = encode(cast[string](update_data))
        else:
          result = ""
      else:
        result = ""
    except:
      result = ""
  else:
    result = ""

proc apply_crdt_update*(doc: ptr YDoc_typedef, update_data: string): bool =
  ## Apply Y-CRDT update to document
  when defined(with_ycrdt):
    if update_data == "":
      return false
      
    try:
      let decoded_update = decode(update_data)
      let txn = ydoc_write_transaction_simple(doc)
      if txn != nil:
        defer: ytransaction_commit(txn)
        ydoc_apply_update(doc, txn, decoded_update.cstring, decoded_update.len.uint32)
        result = true
      else:
        result = false
    except:
      result = false
  else:
    result = false

proc sync_document_with_peer*(manager: CrdtSyncManager,
                             doc_id: DocumentId,
                             peer_ctx_id: string) =
  ## Synchronize a document with a remote peer
  let doc_info = manager.coordinator.get_document_info(doc_id)
  if doc_info.doc == nil:
    return
    
  # Extract current state vector
  let current_vector = extract_state_vector(doc_info.doc)
  let last_vector = manager.last_sync_vectors.get_or_default(doc_id, "")
  
  # Only sync if state has changed
  if current_vector != last_vector:
    manager.last_sync_vectors[doc_id] = current_vector
    
    # Create sync message
    let sync_msg = CrdtSyncMessage(
      kind: DocumentSync,
      document_id: doc_id,
      state_vector: current_vector,
      update_data: ""  # Will be filled by recipient
    )
    
    # Send sync message through existing subscription system
    send_crdt_message(manager.ctx, peer_ctx_id, sync_msg)

proc handle_crdt_sync_message*(manager: CrdtSyncManager,
                              sender_ctx_id: string,
                              message: CrdtSyncMessage) {.gcsafe.} =
  ## Handle incoming CRDT synchronization message
  case message.kind:
  of DocumentSync:
    # Handle document synchronization
    let doc_info = manager.coordinator.get_document_info(message.document_id)
    if doc_info.doc != nil:
      # Create update based on remote state vector
      let update = create_update_from_state(doc_info.doc, message.state_vector)
      if update != "":
        # Send update back to peer
        let response = CrdtSyncMessage(
          kind: DocumentResponse,
          response_doc_id: message.document_id,
          response_data: update
        )
        send_crdt_message(manager.ctx, sender_ctx_id, response)
    
  of DocumentRequest:
    # Handle request for document state
    let doc_info = manager.coordinator.get_document_info(message.requested_doc_id)
    if doc_info.doc != nil:
      let update = create_update_from_state(doc_info.doc, message.request_vector)
      let response = CrdtSyncMessage(
        kind: DocumentResponse,
        response_doc_id: message.requested_doc_id,
        response_data: update
      )
      send_crdt_message(manager.ctx, sender_ctx_id, response)
    
  of DocumentResponse:
    # Apply received update
    let doc_info = manager.coordinator.get_document_info(message.response_doc_id)
    if doc_info.doc != nil and message.response_data != "":
      discard apply_crdt_update(doc_info.doc, message.response_data)
      
      # Update sync state
      if sender_ctx_id in manager.active_syncs:
        manager.active_syncs[sender_ctx_id].last_sync = get_mono_time()

proc start_document_sync*(manager: CrdtSyncManager, doc_id: DocumentId) =
  ## Start synchronizing a document with all connected peers
  for peer_ctx_id in manager.active_syncs.keys:
    sync_document_with_peer(manager, doc_id, peer_ctx_id)

proc add_sync_peer*(manager: CrdtSyncManager, peer_ctx_id: string) =
  ## Add a new peer for CRDT synchronization
  let sync_state = CrdtSyncState(
    remote_ctx_id: peer_ctx_id,
    connected_at: get_mono_time(),
    last_sync: get_mono_time(),
    documents: init_hash_set[DocumentId](),
    pending_updates: @[]
  )
  manager.active_syncs[peer_ctx_id] = sync_state

proc remove_sync_peer*(manager: CrdtSyncManager, peer_ctx_id: string) =
  ## Remove a peer from CRDT synchronization
  if peer_ctx_id in manager.active_syncs:
    manager.active_syncs.del(peer_ctx_id)

proc sync_all_documents*(manager: CrdtSyncManager) =
  ## Synchronize all documents with all connected peers
  let all_docs = manager.coordinator.get_context_documents(manager.ctx.id)
  for doc_id in all_docs:
    start_document_sync(manager, doc_id)

proc cleanup_stale_requests*(manager: CrdtSyncManager, max_age_seconds: int = 30) =
  ## Clean up stale document requests
  let cutoff_time = get_mono_time() - init_duration(seconds = max_age_seconds)
  var to_remove: seq[DocumentId] = @[]
  
  for doc_id, request_time in manager.pending_requests:
    if request_time < cutoff_time:
      to_remove.add(doc_id)
  
  for doc_id in to_remove:
    manager.pending_requests.del(doc_id)

# Integration hooks for existing ZenContext subscription system
proc on_context_subscribed*(manager: CrdtSyncManager, remote_ctx_id: string) =
  ## Called when a new context subscribes - start CRDT sync
  add_sync_peer(manager, remote_ctx_id)
  sync_all_documents(manager)

proc on_context_unsubscribed*(manager: CrdtSyncManager, remote_ctx_id: string) =
  ## Called when a context unsubscribes - stop CRDT sync
  remove_sync_peer(manager, remote_ctx_id)

# Utility procedures for integration
proc enable_crdt_sync*(ctx: ZenContext) =
  ## Enable CRDT synchronization for a context
  let manager = get_crdt_sync_manager(ctx)
  # Hook into existing subscription events
  # This would need integration with the actual subscription system

proc get_document_sync_status*(ctx: ZenContext, doc_id: DocumentId): string =
  ## Get synchronization status for a document
  let manager = get_crdt_sync_manager(ctx)
  let doc_info = manager.coordinator.get_document_info(doc_id)
  if doc_info.doc != nil:
    let peers_count = manager.active_syncs.len
    let last_vector = manager.last_sync_vectors.get_or_default(doc_id, "none")
    result = &"Document {doc_id}: {peers_count} peers, last sync vector: {last_vector[0..min(10, last_vector.len-1)]}..."
  else:
    result = &"Document {doc_id}: not found"

# Implementation of forward-declared procedures
proc send_crdt_message*(ctx: ZenContext, target_ctx_id: string, message: CrdtSyncMessage) {.gcsafe.} =
  ## Send CRDT message through existing subscription system
  let manager = get_crdt_sync_manager(ctx)
  if manager.send_proc != nil:
    manager.send_proc(ctx, target_ctx_id, message)
  else:
    # Fallback if no send_proc is set (shouldn't happen in normal operation)
    discard