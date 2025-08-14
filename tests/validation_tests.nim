import std/[unittest]
import pkg/[pretty, chronicles]
import model_citizen
import model_citizen/zens/validations

proc run*() =
  test "zen validation - valid objects":
    var ctx = ZenContext.init(id = "test_ctx")
    var zen_obj = ZenValue[string].init(ctx = ctx, id = "test_obj")
    
    # Valid object should pass validation
    check zen_obj.valid == true
    
    # Object with value should pass validation  
    zen_obj.value = "test"
    check zen_obj.valid == true

  test "zen validation - invalid objects":
    var ctx = ZenContext.init(id = "test_ctx")
    var zen_obj = ZenValue[string].init(ctx = ctx, id = "test_obj")
    
    # Destroyed object should fail validation
    zen_obj.destroy()
    check zen_obj.valid == false
    
    # Nil object should fail validation
    var nil_obj: ZenValue[string] = nil
    check nil_obj.valid == false

  test "zen cross-validation - same context":
    var ctx = ZenContext.init(id = "test_ctx")
    var obj1 = ZenValue[string].init(ctx = ctx, id = "obj1")
    var obj2 = ZenValue[int].init(ctx = ctx, id = "obj2")
    
    # Objects from same context should validate together
    check obj1.valid(obj2) == true

  test "zen cross-validation - different contexts":
    var ctx1 = ZenContext.init(id = "ctx1")
    var ctx2 = ZenContext.init(id = "ctx2")
    var obj1 = ZenValue[string].init(ctx = ctx1, id = "obj1")
    var obj2 = ZenValue[int].init(ctx = ctx2, id = "obj2")
    
    # Objects from different contexts should fail cross-validation
    check obj1.valid(obj2) == false

  test "zen cross-validation - invalid objects":
    var ctx = ZenContext.init(id = "test_ctx")
    var obj1 = ZenValue[string].init(ctx = ctx, id = "obj1")
    var obj2 = ZenValue[int].init(ctx = ctx, id = "obj2")
    
    # Destroy one object
    obj2.destroy()
    
    # Should fail when one object is invalid
    check obj1.valid(obj2) == false
    
    # Should fail when both objects are invalid
    obj1.destroy()
    check obj1.valid(obj2) == false

  test "validation with nil references":
    var ctx = ZenContext.init(id = "test_ctx") 
    var valid_obj = ZenValue[string].init(ctx = ctx, id = "valid")
    var nil_obj: ZenValue[int] = nil
    
    # Valid object with nil should fail
    check valid_obj.valid(nil_obj) == false

when is_main_module:
  Zen.bootstrap
  run()