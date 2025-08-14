import src/model_citizen

echo "Starting HashSet debug test..."

try:
  echo "Creating context..."
  var ctx = ZenContext.init(id = "debug")
  echo "Context created successfully"
  
  echo "Creating ZenHashSet[string] with no network flags..."
  var s = ZenHashSet[string].init(ctx = ctx, flags = {})
  echo "ZenHashSet created successfully"
  
  echo "Adding item to HashSet..."
  s += "test"
  echo "Item added successfully"
  
  echo "Debug test completed successfully"
except Exception as e:
  echo "Error: ", e.msg
  echo "Traceback: ", e.getStackTrace()