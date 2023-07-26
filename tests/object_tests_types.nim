import model_citizen

type
  ZenString* = ZenValue[string]

  Beep* = ref object of RootObj
    id*: string
    name_value*: ZenValue[string]

  Boop* = ref object of Beep
    state_value*: ZenString
    messages*: ZenSeq[string]

  Bloop* = ref object of Beep
    ageValue*: ZenValue[int]

Zen.register(Boop)
Zen.register(Bloop)
