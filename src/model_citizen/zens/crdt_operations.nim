import std/tables
import model_citizen/[core, types {.all.}]
import ./[contexts, validations, private]
import model_citizen/crdt/[crdt_types, crdt_zen_value]

# CRDT instance management for ZenValue types
var crdt_instances {.threadvar.}: Table[string, ref RootObj]

proc get_or_create_crdt_instance*[T](self: ZenValue[T]): CrdtZenValue[T] =
  ## Get existing CRDT instance or create new one for this ZenValue
  privileged
  private_access ZenObject[T, T]
  
  # Use ZenValue's ID as the key for CRDT instance lookup
  let key = self.id
  
  if key in crdt_instances:
    result = CrdtZenValue[T](crdt_instances[key])
  else:
    # Convert sync_mode to CrdtMode
    let crdt_mode = case self.sync_mode:
      of SyncMode.FastLocal: CrdtMode.FastLocal
      of SyncMode.WaitForSync: CrdtMode.WaitForSync  
      of SyncMode.Yolo: 
        # This shouldn't happen since we check != Yolo, but default to FastLocal for safety
        CrdtMode.FastLocal
    
    # Create new CRDT instance with same ID and current value
    result = CrdtZenValue[T].init(
      ctx = self.ctx,
      id = key, 
      mode = crdt_mode
    )
    
    # Initialize with current ZenValue's tracked value
    when compiles(self.tracked):
      result.local_value = self.tracked
      result.crdt_value = self.tracked
    
    # Store for future use
    crdt_instances[key] = result

proc get_or_create_crdt_seq_instance*[T](self: ZenSeq[T]): CrdtZenSeq[T] =
  ## Get existing CRDT instance or create new one for this ZenSeq
  privileged
  private_access ZenObject[seq[T], T]
  
  # Use ZenSeq's ID as the key for CRDT instance lookup
  let key = self.id
  
  if key in crdt_instances:
    result = CrdtZenSeq[T](crdt_instances[key])
  else:
    # Convert sync_mode to CrdtMode
    let crdt_mode = case self.sync_mode:
      of SyncMode.FastLocal: CrdtMode.FastLocal
      of SyncMode.WaitForSync: CrdtMode.WaitForSync  
      of SyncMode.Yolo: 
        # This shouldn't happen since we check != Yolo, but default to FastLocal for safety
        CrdtMode.FastLocal
    
    # Create new CRDT instance with same ID and current sequence
    result = CrdtZenSeq[T].init(
      ctx = self.ctx,
      id = key, 
      mode = crdt_mode
    )
    
    # Initialize with current ZenSeq's tracked value
    when compiles(self.tracked):
      result.local_seq = self.tracked
      result.crdt_seq = self.tracked
    
    # Store for future use
    crdt_instances[key] = result

proc get_or_create_crdt_set_instance*[T](self: ZenSet[T]): CrdtZenSet[T] =
  ## Get existing CRDT instance or create new one for this ZenSet
  privileged
  private_access ZenObject[HashSet[T], T]
  
  # Use ZenSet's ID as the key for CRDT instance lookup
  let key = self.id
  
  if key in crdt_instances:
    result = CrdtZenSet[T](crdt_instances[key])
  else:
    # Convert sync_mode to CrdtMode
    let crdt_mode = case self.sync_mode:
      of SyncMode.FastLocal: CrdtMode.FastLocal
      of SyncMode.WaitForSync: CrdtMode.WaitForSync  
      of SyncMode.Yolo: 
        # This shouldn't happen since we check != Yolo, but default to FastLocal for safety
        CrdtMode.FastLocal
    
    # Create new CRDT instance with same ID and current set
    result = CrdtZenSet[T].init(
      ctx = self.ctx,
      id = key, 
      mode = crdt_mode
    )
    
    # Initialize with current ZenSet's tracked value
    when compiles(self.tracked):
      result.local_set = self.tracked
      result.crdt_set = self.tracked
    
    # Store for future use
    crdt_instances[key] = result