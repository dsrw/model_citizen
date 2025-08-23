import model_citizen

proc test_sync_mode_defaults() =
  var ctx = ZenContext.init(id = "test")
  defer: ctx.close()
  
  # Test default sync_mode  
  var zen_val = ZenValue[int].init(ctx = ctx, id = "test1")
  echo "Default sync_mode: ", zen_val.sync_mode
  
  # Test explicit Yolo
  var zen_val2 = ZenValue[int].init(sync_mode = Yolo, ctx = ctx, id = "test2")
  echo "Explicit Yolo sync_mode: ", zen_val2.sync_mode
  
  # Test explicit FastLocal
  var zen_val3 = ZenValue[int].init(sync_mode = FastLocal, ctx = ctx, id = "test3")
  echo "Explicit FastLocal sync_mode: ", zen_val3.sync_mode

test_sync_mode_defaults()