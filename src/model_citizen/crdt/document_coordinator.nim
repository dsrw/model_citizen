## Y-CRDT Document Coordination System
##
## This module provides shared Y-CRDT document management for multi-context synchronization.
## Instead of each CRDT instance creating its own Y-CRDT document, this coordinator manages
## shared documents that can be synchronized across multiple ZenContexts.

import std/[tables, sets, locks, monotimes, hashes]
import model_citizen/[core, types]
import ./[crdt_types, ycrdt_futhark]

type
  DocumentId* = distinct string
    ## Unique identifier for a Y-CRDT document
    
  SyncChannel* = object
    ## Represents a sync channel between contexts for document sharing
    source_ctx*: string
    target_ctx*: string
    document_id*: DocumentId
    last_sync*: MonoTime
    state*: SyncChannelState
    
  SyncChannelState* = enum
    ## State of synchronization channel
    Connecting, Active, Disconnected, Error
    
  DocumentInfo* = object
    ## Information about a managed Y-CRDT document
    id*: DocumentId
    doc*: ptr YDoc_typedef
    owner_contexts*: HashSet[string]  ## Contexts that use this document
    sync_channels*: seq[SyncChannel]  ## Active sync channels
    created_at*: MonoTime
    last_modified*: MonoTime
    ref_count*: int  ## Reference counting for cleanup
    
  DocumentCoordinator* = ref object
    ## Central coordinator for Y-CRDT document management
    documents*: Table[DocumentId, DocumentInfo]
    context_documents*: Table[string, HashSet[DocumentId]]  ## Context -> Documents mapping
    lock*: Lock  ## Thread safety for multi-context access
    cleanup_threshold*: int  ## Cleanup unreferenced documents after this many refs
    
# Global document coordinator instance (thread-safe)
var global_coordinator {.threadvar.}: DocumentCoordinator

proc `$`*(id: DocumentId): string = string(id)
proc `==`*(a, b: DocumentId): bool = string(a) == string(b)
proc hash*(id: DocumentId): Hash = hash(string(id))

proc init_document_coordinator*(): DocumentCoordinator =
  ## Initialize a new document coordinator
  result = DocumentCoordinator()
  result.documents = init_table[DocumentId, DocumentInfo]()
  result.context_documents = init_table[string, HashSet[DocumentId]]()
  init_lock(result.lock)
  result.cleanup_threshold = 0  # Cleanup when ref_count reaches 0

proc get_global_coordinator*(): DocumentCoordinator =
  ## Get or create the global document coordinator instance
  if global_coordinator == nil:
    global_coordinator = init_document_coordinator()
  result = global_coordinator

proc generate_document_id*(ctx_id: string, object_type: string, object_id: string): DocumentId =
  ## Generate a unique document ID for a CRDT object
  ## Format: "ctx:{ctx_id}:type:{object_type}:id:{object_id}"
  DocumentId("ctx:" & ctx_id & ":type:" & object_type & ":id:" & object_id)

proc get_or_create_document*(coordinator: DocumentCoordinator,
                           doc_id: DocumentId,
                           ctx_id: string): ptr YDoc_typedef =
  ## Get existing document or create new one with proper coordination
  with_lock coordinator.lock:
    if doc_id in coordinator.documents:
      # Document exists, increment reference and add context if needed
      coordinator.documents[doc_id].ref_count += 1
      coordinator.documents[doc_id].owner_contexts.incl(ctx_id)
      coordinator.documents[doc_id].last_modified = get_mono_time()
      result = coordinator.documents[doc_id].doc
    else:
      # Create new document
      let y_doc = ydoc_new()
      let doc_info = DocumentInfo(
        id: doc_id,
        doc: y_doc,
        owner_contexts: [ctx_id].to_hash_set(),
        sync_channels: @[],
        created_at: get_mono_time(),
        last_modified: get_mono_time(),
        ref_count: 1
      )
      
      coordinator.documents[doc_id] = doc_info
      
      # Update context mapping
      if ctx_id notin coordinator.context_documents:
        coordinator.context_documents[ctx_id] = init_hash_set[DocumentId]()
      coordinator.context_documents[ctx_id].incl(doc_id)
      
      result = y_doc

proc release_document*(coordinator: DocumentCoordinator,
                      doc_id: DocumentId,
                      ctx_id: string) =
  ## Release reference to document and cleanup if no longer needed
  with_lock coordinator.lock:
    if doc_id in coordinator.documents:
      coordinator.documents[doc_id].ref_count -= 1
      
      # Remove context from owners if it's releasing
      coordinator.documents[doc_id].owner_contexts.excl(ctx_id)
      
      # Cleanup document if no references remain
      if coordinator.documents[doc_id].ref_count <= coordinator.cleanup_threshold:
        let doc_info = coordinator.documents[doc_id]
        
        # Clean up Y-CRDT document
        if doc_info.doc != nil:
          ydoc_destroy(doc_info.doc)
        
        # Remove from coordinator
        coordinator.documents.del(doc_id)
        
        # Update context mapping
        if ctx_id in coordinator.context_documents:
          coordinator.context_documents[ctx_id].excl(doc_id)
          if coordinator.context_documents[ctx_id].len == 0:
            coordinator.context_documents.del(ctx_id)

proc get_context_documents*(coordinator: DocumentCoordinator, ctx_id: string): HashSet[DocumentId] =
  ## Get all documents associated with a context
  with_lock coordinator.lock:
    if ctx_id in coordinator.context_documents:
      result = coordinator.context_documents[ctx_id]
    else:
      result = init_hash_set[DocumentId]()

proc create_sync_channel*(coordinator: DocumentCoordinator,
                        doc_id: DocumentId,
                        source_ctx: string,
                        target_ctx: string): bool =
  ## Create a sync channel between contexts for a document
  with_lock coordinator.lock:
    if doc_id notin coordinator.documents:
      return false
    
    let sync_channel = SyncChannel(
      source_ctx: source_ctx,
      target_ctx: target_ctx,
      document_id: doc_id,
      last_sync: get_mono_time(),
      state: Connecting
    )
    
    coordinator.documents[doc_id].sync_channels.add(sync_channel)
    result = true

proc get_document_info*(coordinator: DocumentCoordinator, doc_id: DocumentId): DocumentInfo =
  ## Get information about a document (read-only)
  with_lock coordinator.lock:
    if doc_id in coordinator.documents:
      result = coordinator.documents[doc_id]
    else:
      # Return empty document info
      result = DocumentInfo()

proc list_all_documents*(coordinator: DocumentCoordinator): seq[DocumentId] =
  ## List all managed document IDs
  with_lock coordinator.lock:
    result = @[]
    for doc_id in coordinator.documents.keys:
      result.add(doc_id)

proc cleanup_stale_documents*(coordinator: DocumentCoordinator, max_age_seconds: int = 3600) =
  ## Clean up documents that haven't been accessed recently
  let cutoff_time = get_mono_time() - init_duration(seconds = max_age_seconds)
  var to_remove: seq[DocumentId] = @[]
  
  with_lock coordinator.lock:
    for doc_id, doc_info in coordinator.documents:
      if doc_info.last_modified < cutoff_time and doc_info.ref_count <= 0:
        to_remove.add(doc_id)
    
    # Remove stale documents
    for doc_id in to_remove:
      let doc_info = coordinator.documents[doc_id]
      if doc_info.doc != nil:
        ydoc_destroy(doc_info.doc)
      coordinator.documents.del(doc_id)
      
      # Clean up context mappings
      for ctx_id in doc_info.owner_contexts:
        if ctx_id in coordinator.context_documents:
          coordinator.context_documents[ctx_id].excl(doc_id)
          if coordinator.context_documents[ctx_id].len == 0:
            coordinator.context_documents.del(ctx_id)

# Helper procedures for common operations
proc get_shared_document*(ctx_id: string, object_type: string, object_id: string): ptr YDoc_typedef =
  ## Convenience function to get a shared Y-CRDT document for a CRDT object
  let coordinator = get_global_coordinator()
  let doc_id = generate_document_id(ctx_id, object_type, object_id)
  result = coordinator.get_or_create_document(doc_id, ctx_id)

proc release_shared_document*(ctx_id: string, object_type: string, object_id: string) =
  ## Convenience function to release a shared Y-CRDT document
  let coordinator = get_global_coordinator()
  let doc_id = generate_document_id(ctx_id, object_type, object_id)
  coordinator.release_document(doc_id, ctx_id)