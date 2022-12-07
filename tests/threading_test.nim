import std / [locks, os]
import pkg / [print]
import model_citizen

var global_lock: Lock
global_lock.init_lock
var global_cond: Cond
global_cond.init_cond
var worker_thread: Thread[ZenContext]

proc start_worker(ctx: ZenContext) {.thread.} =
  Zen.thread_ctx = ctx
  ctx.recv
  var b = ZenValue[string](ctx["t1"])
  var working = true
  b.changes:
    if "scott".added:
      b.value = "marie"
    if "claire".added:
      b.value = "cal"
    if "vin".added:
      b.value = "banana"
    if "bacon".added:
      b.value = "ghetti"
    if "done".added:
      working = false

  global_cond.signal()
  while working:
    ctx.recv

when is_main_module:
  Zen.thread_ctx = ZenContext.init(name = "main")
  var ctx = ZenContext.init(name = "worker")
  Zen.thread_ctx.subscribe(ctx)
  ctx.subscribe(Zen.thread_ctx)

  var a = Zen.init("", id = "t1")
  global_lock.acquire()
  worker_thread.create_thread(start_worker, ctx)
  global_cond.wait(global_lock)
  global_lock.release()
  a.value = "scott"
  var remaining = 1000
  var working = true
  a.changes:
    if "marie".added:
      a.value = "claire"
    if "cal".added:
      a.value = "vin"
    if "banana".added:
      a.value = "bacon"
    if "ghetti".added:
      remaining -= 1
      if remaining == 0:
        a.value = "done"
        working = false
      else:
        a.value = "scott"

  while working:
    Zen.thread_ctx.recv

  worker_thread.join_thread
  echo "done"
