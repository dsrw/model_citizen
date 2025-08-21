
{.warning[UnusedImport]: off.}
{.hint[XDeclaredButNotUsed]: off.}
from std / macros import hint, warning, newLit, getSize

from std / os import parentDir

when not declared(ownSizeOf):
  macro ownSizeof(x: typed): untyped =
    newLit(x.getSize)

when not declared(StructYDoc):
  type
    StructYDoc* = object
else:
  static :
    hint("Declaration of " & "StructYDoc" & " already exists, not redeclaring")
when not declared(StructYArrayIter):
  type
    StructYArrayIter* = object
else:
  static :
    hint("Declaration of " & "StructYArrayIter" &
        " already exists, not redeclaring")
when not declared(StructUnquote):
  type
    StructUnquote* = object
else:
  static :
    hint("Declaration of " & "StructUnquote" &
        " already exists, not redeclaring")
when not declared(StructYUndoManager):
  type
    StructYUndoManager* = object
else:
  static :
    hint("Declaration of " & "StructYUndoManager" &
        " already exists, not redeclaring")
when not declared(StructTransaction):
  type
    StructTransaction* = object
else:
  static :
    hint("Declaration of " & "StructTransaction" &
        " already exists, not redeclaring")
when not declared(StructYMapIter):
  type
    StructYMapIter* = object
else:
  static :
    hint("Declaration of " & "StructYMapIter" &
        " already exists, not redeclaring")
when not declared(StructYSubscription):
  type
    StructYSubscription* = object
else:
  static :
    hint("Declaration of " & "StructYSubscription" &
        " already exists, not redeclaring")
when not declared(StructYJsonPathIter):
  type
    StructYJsonPathIter* = object
else:
  static :
    hint("Declaration of " & "StructYJsonPathIter" &
        " already exists, not redeclaring")
when not declared(StructTransactionInner):
  type
    StructTransactionInner* = object
else:
  static :
    hint("Declaration of " & "StructTransactionInner" &
        " already exists, not redeclaring")
when not declared(StructYWeakIter):
  type
    StructYWeakIter* = object
else:
  static :
    hint("Declaration of " & "StructYWeakIter" &
        " already exists, not redeclaring")
when not declared(StructStickyIndex):
  type
    StructStickyIndex* = object
else:
  static :
    hint("Declaration of " & "StructStickyIndex" &
        " already exists, not redeclaring")
when not declared(StructYXmlAttrIter):
  type
    StructYXmlAttrIter* = object
else:
  static :
    hint("Declaration of " & "StructYXmlAttrIter" &
        " already exists, not redeclaring")
when not declared(StructLinkSource):
  type
    StructLinkSource* = object
else:
  static :
    hint("Declaration of " & "StructLinkSource" &
        " already exists, not redeclaring")
when not declared(StructYXmlTreeWalker):
  type
    StructYXmlTreeWalker* = object
else:
  static :
    hint("Declaration of " & "StructYXmlTreeWalker" &
        " already exists, not redeclaring")
when not declared(StructTransactionMut):
  type
    StructTransactionMut* = object
else:
  static :
    hint("Declaration of " & "StructTransactionMut" &
        " already exists, not redeclaring")
when not declared(StructBranch):
  type
    StructBranch* = object
else:
  static :
    hint("Declaration of " & "StructBranch" & " already exists, not redeclaring")
type
  YDoc_typedef_1191182955 = StructYDoc ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:39:24
  Branch_1191182958 = StructBranch ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:50:26
  Transaction_1191182960 = StructTransaction ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:52:31
  TransactionMut_1191182962 = StructTransactionMut ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:53:34
  YWeakIter_1191182964 = StructYWeakIter ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:58:29
  YArrayIter_1191182966 = StructYArrayIter ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:63:30
  YMapIter_1191182968 = StructYMapIter ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:69:28
  YJsonPathIter_1191182970 = StructYJsonPathIter ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:74:33
  YXmlAttrIter_1191182972 = StructYXmlAttrIter ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:81:32
  YXmlTreeWalker_1191182974 = StructYXmlTreeWalker ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:89:34
  YUndoManager_1191182976 = StructYUndoManager ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:91:32
  LinkSource_1191182978 = StructLinkSource ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:92:30
  Unquote_1191182980 = StructUnquote ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:93:27
  StickyIndex_1191182982 = StructStickyIndex ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:94:31
  YSubscription_1191182984 = StructYSubscription ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:95:33
  TransactionInner_1191182986 = StructTransactionInner ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:330:33
  StructYOptions_1191182988 {.pure, inheritable, bycopy.} = object
    id*: uint64              ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:335:16
    guid*: cstring
    collection_id*: cstring
    encoding*: uint8
    skip_gc*: uint8
    auto_load*: uint8
    should_load*: uint8
  YOptions_1191182990 = StructYOptions_1191182989 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:377:3
  union_YOutputContent_1191182992 {.union, bycopy.} = object
    flag*: uint8             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:401:15
    num*: cdouble
    integer*: int64
    str*: cstring
    buf*: cstring
    array*: ptr StructYOutput_1191182995
    map*: ptr StructYMapEntry_1191182997
    y_type*: ptr Branch_1191182959
    y_doc*: ptr YDoc_typedef_1191182957
  StructYOutput_1191182994 {.pure, inheritable, bycopy.} = object
    tag*: int8               ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:420:16
    len*: uint32
    value*: union_YOutputContent_1191182993
  StructYMapEntry_1191182996 {.pure, inheritable, bycopy.} = object
    key*: cstring            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:461:16
    value*: ptr StructYOutput_1191182995
  YOutputContent_1191182998 = union_YOutputContent_1191182993 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:411:3
  YOutput_1191183000 = StructYOutput_1191182995 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:455:3
  YMapEntry_1191183002 = StructYMapEntry_1191182997 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:471:3
  StructYXmlAttr_1191183004 {.pure, inheritable, bycopy.} = object
    name*: cstring           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:477:16
    value*: ptr StructYOutput_1191182995
  YXmlAttr_1191183006 = StructYXmlAttr_1191183005 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:480:3
  StructYStateVector_1191183008 {.pure, inheritable, bycopy.} = object
    entries_count*: uint32   ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:493:16
    client_ids*: ptr uint64
    clocks*: ptr uint32
  YStateVector_1191183010 = StructYStateVector_1191183009 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:510:3
  StructYIdRange_1191183012 {.pure, inheritable, bycopy.} = object
    start*: uint32           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:512:16
    end_field*: uint32
  YIdRange_1191183021 = StructYIdRange_1191183013 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:515:3
  StructYIdRangeSeq_1191183023 {.pure, inheritable, bycopy.} = object
    len*: uint32             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:521:16
    seq*: ptr StructYIdRange_1191183013
  YIdRangeSeq_1191183025 = StructYIdRangeSeq_1191183024 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:532:3
  StructYDeleteSet_1191183027 {.pure, inheritable, bycopy.} = object
    entries_count*: uint32   ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:539:16
    client_ids*: ptr uint64
    ranges*: ptr StructYIdRangeSeq_1191183024
  YDeleteSet_1191183029 = StructYDeleteSet_1191183028 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:556:3
  StructYAfterTransactionEvent_1191183031 {.pure, inheritable, bycopy.} = object
    before_state*: StructYStateVector_1191183009 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:562:16
    after_state*: StructYStateVector_1191183009
    delete_set*: StructYDeleteSet_1191183028
  YAfterTransactionEvent_1191183033 = StructYAfterTransactionEvent_1191183032 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:575:3
  StructYSubdocsEvent_1191183035 {.pure, inheritable, bycopy.} = object
    added_len*: uint32       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:577:16
    removed_len*: uint32
    loaded_len*: uint32
    added*: ptr ptr YDoc_typedef_1191182957
    removed*: ptr ptr YDoc_typedef_1191182957
    loaded*: ptr ptr YDoc_typedef_1191182957
  YSubdocsEvent_1191183037 = StructYSubdocsEvent_1191183036 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:584:3
  YTransaction_1191183039 = StructTransactionInner ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:591:33
  StructYPendingUpdate_1191183041 {.pure, inheritable, bycopy.} = object
    missing*: StructYStateVector_1191183009 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:598:16
    update_v1*: cstring
    update_len*: uint32
  YPendingUpdate_1191183043 = StructYPendingUpdate_1191183042 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:612:3
  StructYMapInputData_1191183045 {.pure, inheritable, bycopy.} = object
    keys*: ptr cstring       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:614:16
    values*: ptr StructYInput_1191183048
  StructYInput_1191183047 {.pure, inheritable, bycopy.} = object
    tag*: int8               ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:641:16
    len*: uint32
    value*: union_YInputContent_1191183054
  YMapInputData_1191183049 = StructYMapInputData_1191183046 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:617:3
  Weak_1191183051 = LinkSource_1191182979 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:619:20
  union_YInputContent_1191183053 {.union, bycopy.} = object
    flag*: uint8             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:621:15
    num*: cdouble
    integer*: int64
    str*: cstring
    buf*: cstring
    values*: ptr StructYInput_1191183048
    map*: StructYMapInputData_1191183046
    doc*: ptr YDoc_typedef_1191182957
    weak*: ptr Weak_1191183052
  YInputContent_1191183055 = union_YInputContent_1191183054 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:631:3
  YInput_1191183057 = StructYInput_1191183048 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:676:3
  StructYDeltaIn_1191183059 {.pure, inheritable, bycopy.} = object
    tag*: uint8              ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:694:16
    len*: uint32
    attributes*: ptr StructYInput_1191183048
    insert*: ptr StructYInput_1191183048
  YDeltaIn_1191183061 = StructYDeltaIn_1191183060 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:722:3
  StructYChunk_1191183063 {.pure, inheritable, bycopy.} = object
    data*: StructYOutput_1191182995 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:727:16
    fmt_len*: uint32
    fmt*: ptr StructYMapEntry_1191182997
  YChunk_1191183065 = StructYChunk_1191183064 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:741:3
  StructYTextEvent_1191183067 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:748:16
    txn*: ptr TransactionMut_1191182963
  YTextEvent_1191183069 = StructYTextEvent_1191183068 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:751:3
  StructYMapEvent_1191183071 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:758:16
    txn*: ptr TransactionMut_1191182963
  YMapEvent_1191183073 = StructYMapEvent_1191183072 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:761:3
  StructYArrayEvent_1191183075 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:768:16
    txn*: ptr TransactionMut_1191182963
  YArrayEvent_1191183077 = StructYArrayEvent_1191183076 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:771:3
  StructYXmlEvent_1191183079 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:779:16
    txn*: ptr TransactionMut_1191182963
  YXmlEvent_1191183081 = StructYXmlEvent_1191183080 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:782:3
  StructYXmlTextEvent_1191183083 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:790:16
    txn*: ptr TransactionMut_1191182963
  YXmlTextEvent_1191183085 = StructYXmlTextEvent_1191183084 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:793:3
  StructYWeakLinkEvent_1191183087 {.pure, inheritable, bycopy.} = object
    inner*: pointer          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:799:16
    txn*: ptr TransactionMut_1191182963
  YWeakLinkEvent_1191183089 = StructYWeakLinkEvent_1191183088 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:802:3
  union_YEventContent_1191183091 {.union, bycopy.} = object
    text*: StructYTextEvent_1191183068 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:804:15
    map*: StructYMapEvent_1191183072
    array*: StructYArrayEvent_1191183076
    xml_elem*: StructYXmlEvent_1191183080
    xml_text*: StructYXmlTextEvent_1191183084
    weak*: StructYWeakLinkEvent_1191183088
  YEventContent_1191183093 = union_YEventContent_1191183092 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:811:3
  StructYEvent_1191183095 {.pure, inheritable, bycopy.} = object
    tag*: int8               ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:813:16
    content*: union_YEventContent_1191183092
  YEvent_1191183097 = StructYEvent_1191183096 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:829:3
  union_YPathSegmentCase_1191183099 {.union, bycopy.} = object
    key*: cstring            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:831:15
    index*: uint32
  YPathSegmentCase_1191183101 = union_YPathSegmentCase_1191183100 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:834:3
  StructYPathSegment_1191183103 {.pure, inheritable, bycopy.} = object
    tag*: cschar             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:845:16
    value*: union_YPathSegmentCase_1191183100
  YPathSegment_1191183105 = StructYPathSegment_1191183104 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:861:3
  StructYDeltaAttr_1191183107 {.pure, inheritable, bycopy.} = object
    key*: cstring            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:866:16
    value*: StructYOutput_1191182995
  YDeltaAttr_1191183109 = StructYDeltaAttr_1191183108 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:875:3
  StructYDeltaOut_1191183111 {.pure, inheritable, bycopy.} = object
    tag*: uint8              ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:897:16
    len*: uint32
    attributes_len*: uint32
    attributes*: ptr StructYDeltaAttr_1191183108
    insert*: ptr StructYOutput_1191182995
  YDeltaOut_1191183113 = StructYDeltaOut_1191183112 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:929:3
  StructYEventChange_1191183115 {.pure, inheritable, bycopy.} = object
    tag*: uint8              ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:948:16
    len*: uint32
    values*: ptr StructYOutput_1191182995
  YEventChange_1191183117 = StructYEventChange_1191183116 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:971:3
  StructYEventKeyChange_1191183119 {.pure, inheritable, bycopy.} = object
    key*: cstring            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:987:16
    tag*: cschar
    old_value*: ptr StructYOutput_1191182995
    new_value*: ptr StructYOutput_1191182995
  YEventKeyChange_1191183121 = StructYEventKeyChange_1191183120 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1012:3
  StructYUndoManagerOptions_1191183123 {.pure, inheritable, bycopy.} = object
    capture_timeout_millis*: int32 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1014:16
  YUndoManagerOptions_1191183125 = StructYUndoManagerOptions_1191183124 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1016:3
  StructYUndoEvent_1191183127 {.pure, inheritable, bycopy.} = object
    kind*: cschar            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1023:16
    origin*: cstring
    origin_len*: uint32
    meta*: pointer
  YUndoEvent_1191183129 = StructYUndoEvent_1191183128 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1052:3
  YStickyIndex_1191183131 = StickyIndex_1191182983 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1066:21
  union_YBranchIdVariant_1191183133 {.union, bycopy.} = object
    clock*: uint32           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1068:15
    name*: ptr uint8
  YBranchIdVariant_1191183135 = union_YBranchIdVariant_1191183134 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1080:3
  StructYBranchId_1191183137 {.pure, inheritable, bycopy.} = object
    client_or_len*: int64    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1091:16
    variant*: union_YBranchIdVariant_1191183134
  YBranchId_1191183139 = StructYBranchId_1191183138 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:1098:3
  StructYEvent_1191183096 = (when declared(StructYEvent):
    when ownSizeof(StructYEvent) != ownSizeof(StructYEvent_1191183095):
      static :
        warning("Declaration of " & "StructYEvent" &
            " exists but with different size")
    StructYEvent
  else:
    StructYEvent_1191183095)
  StructYXmlTextEvent_1191183084 = (when declared(StructYXmlTextEvent):
    when ownSizeof(StructYXmlTextEvent) != ownSizeof(StructYXmlTextEvent_1191183083):
      static :
        warning("Declaration of " & "StructYXmlTextEvent" &
            " exists but with different size")
    StructYXmlTextEvent
  else:
    StructYXmlTextEvent_1191183083)
  StructYPendingUpdate_1191183042 = (when declared(StructYPendingUpdate):
    when ownSizeof(StructYPendingUpdate) != ownSizeof(StructYPendingUpdate_1191183041):
      static :
        warning("Declaration of " & "StructYPendingUpdate" &
            " exists but with different size")
    StructYPendingUpdate
  else:
    StructYPendingUpdate_1191183041)
  YDeltaOut_1191183114 = (when declared(YDeltaOut):
    when ownSizeof(YDeltaOut) != ownSizeof(YDeltaOut_1191183113):
      static :
        warning("Declaration of " & "YDeltaOut" &
            " exists but with different size")
    YDeltaOut
  else:
    YDeltaOut_1191183113)
  YArrayIter_1191182967 = (when declared(YArrayIter):
    when ownSizeof(YArrayIter) != ownSizeof(YArrayIter_1191182966):
      static :
        warning("Declaration of " & "YArrayIter" &
            " exists but with different size")
    YArrayIter
  else:
    YArrayIter_1191182966)
  StructYAfterTransactionEvent_1191183032 = (when declared(
      StructYAfterTransactionEvent):
    when ownSizeof(StructYAfterTransactionEvent) !=
        ownSizeof(StructYAfterTransactionEvent_1191183031):
      static :
        warning("Declaration of " & "StructYAfterTransactionEvent" &
            " exists but with different size")
    StructYAfterTransactionEvent
  else:
    StructYAfterTransactionEvent_1191183031)
  YJsonPathIter_1191182971 = (when declared(YJsonPathIter):
    when ownSizeof(YJsonPathIter) != ownSizeof(YJsonPathIter_1191182970):
      static :
        warning("Declaration of " & "YJsonPathIter" &
            " exists but with different size")
    YJsonPathIter
  else:
    YJsonPathIter_1191182970)
  StructYDeltaAttr_1191183108 = (when declared(StructYDeltaAttr):
    when ownSizeof(StructYDeltaAttr) != ownSizeof(StructYDeltaAttr_1191183107):
      static :
        warning("Declaration of " & "StructYDeltaAttr" &
            " exists but with different size")
    StructYDeltaAttr
  else:
    StructYDeltaAttr_1191183107)
  YStickyIndex_1191183132 = (when declared(YStickyIndex):
    when ownSizeof(YStickyIndex) != ownSizeof(YStickyIndex_1191183131):
      static :
        warning("Declaration of " & "YStickyIndex" &
            " exists but with different size")
    YStickyIndex
  else:
    YStickyIndex_1191183131)
  YChunk_1191183066 = (when declared(YChunk):
    when ownSizeof(YChunk) != ownSizeof(YChunk_1191183065):
      static :
        warning("Declaration of " & "YChunk" & " exists but with different size")
    YChunk
  else:
    YChunk_1191183065)
  YXmlAttr_1191183007 = (when declared(YXmlAttr):
    when ownSizeof(YXmlAttr) != ownSizeof(YXmlAttr_1191183006):
      static :
        warning("Declaration of " & "YXmlAttr" &
            " exists but with different size")
    YXmlAttr
  else:
    YXmlAttr_1191183006)
  StructYXmlAttr_1191183005 = (when declared(StructYXmlAttr):
    when ownSizeof(StructYXmlAttr) != ownSizeof(StructYXmlAttr_1191183004):
      static :
        warning("Declaration of " & "StructYXmlAttr" &
            " exists but with different size")
    StructYXmlAttr
  else:
    StructYXmlAttr_1191183004)
  YOutputContent_1191182999 = (when declared(YOutputContent):
    when ownSizeof(YOutputContent) != ownSizeof(YOutputContent_1191182998):
      static :
        warning("Declaration of " & "YOutputContent" &
            " exists but with different size")
    YOutputContent
  else:
    YOutputContent_1191182998)
  YOutput_1191183001 = (when declared(YOutput):
    when ownSizeof(YOutput) != ownSizeof(YOutput_1191183000):
      static :
        warning("Declaration of " & "YOutput" &
            " exists but with different size")
    YOutput
  else:
    YOutput_1191183000)
  YXmlTextEvent_1191183086 = (when declared(YXmlTextEvent):
    when ownSizeof(YXmlTextEvent) != ownSizeof(YXmlTextEvent_1191183085):
      static :
        warning("Declaration of " & "YXmlTextEvent" &
            " exists but with different size")
    YXmlTextEvent
  else:
    YXmlTextEvent_1191183085)
  YMapEvent_1191183074 = (when declared(YMapEvent):
    when ownSizeof(YMapEvent) != ownSizeof(YMapEvent_1191183073):
      static :
        warning("Declaration of " & "YMapEvent" &
            " exists but with different size")
    YMapEvent
  else:
    YMapEvent_1191183073)
  YArrayEvent_1191183078 = (when declared(YArrayEvent):
    when ownSizeof(YArrayEvent) != ownSizeof(YArrayEvent_1191183077):
      static :
        warning("Declaration of " & "YArrayEvent" &
            " exists but with different size")
    YArrayEvent
  else:
    YArrayEvent_1191183077)
  StructYPathSegment_1191183104 = (when declared(StructYPathSegment):
    when ownSizeof(StructYPathSegment) != ownSizeof(StructYPathSegment_1191183103):
      static :
        warning("Declaration of " & "StructYPathSegment" &
            " exists but with different size")
    StructYPathSegment
  else:
    StructYPathSegment_1191183103)
  TransactionMut_1191182963 = (when declared(TransactionMut):
    when ownSizeof(TransactionMut) != ownSizeof(TransactionMut_1191182962):
      static :
        warning("Declaration of " & "TransactionMut" &
            " exists but with different size")
    TransactionMut
  else:
    TransactionMut_1191182962)
  YSubscription_1191182985 = (when declared(YSubscription):
    when ownSizeof(YSubscription) != ownSizeof(YSubscription_1191182984):
      static :
        warning("Declaration of " & "YSubscription" &
            " exists but with different size")
    YSubscription
  else:
    YSubscription_1191182984)
  StickyIndex_1191182983 = (when declared(StickyIndex):
    when ownSizeof(StickyIndex) != ownSizeof(StickyIndex_1191182982):
      static :
        warning("Declaration of " & "StickyIndex" &
            " exists but with different size")
    StickyIndex
  else:
    StickyIndex_1191182982)
  YPathSegmentCase_1191183102 = (when declared(YPathSegmentCase):
    when ownSizeof(YPathSegmentCase) != ownSizeof(YPathSegmentCase_1191183101):
      static :
        warning("Declaration of " & "YPathSegmentCase" &
            " exists but with different size")
    YPathSegmentCase
  else:
    YPathSegmentCase_1191183101)
  Branch_1191182959 = (when declared(Branch):
    when ownSizeof(Branch) != ownSizeof(Branch_1191182958):
      static :
        warning("Declaration of " & "Branch" & " exists but with different size")
    Branch
  else:
    Branch_1191182958)
  StructYArrayEvent_1191183076 = (when declared(StructYArrayEvent):
    when ownSizeof(StructYArrayEvent) != ownSizeof(StructYArrayEvent_1191183075):
      static :
        warning("Declaration of " & "StructYArrayEvent" &
            " exists but with different size")
    StructYArrayEvent
  else:
    StructYArrayEvent_1191183075)
  TransactionInner_1191182987 = (when declared(TransactionInner):
    when ownSizeof(TransactionInner) != ownSizeof(TransactionInner_1191182986):
      static :
        warning("Declaration of " & "TransactionInner" &
            " exists but with different size")
    TransactionInner
  else:
    TransactionInner_1191182986)
  YIdRange_1191183022 = (when declared(YIdRange):
    when ownSizeof(YIdRange) != ownSizeof(YIdRange_1191183021):
      static :
        warning("Declaration of " & "YIdRange" &
            " exists but with different size")
    YIdRange
  else:
    YIdRange_1191183021)
  YEventKeyChange_1191183122 = (when declared(YEventKeyChange):
    when ownSizeof(YEventKeyChange) != ownSizeof(YEventKeyChange_1191183121):
      static :
        warning("Declaration of " & "YEventKeyChange" &
            " exists but with different size")
    YEventKeyChange
  else:
    YEventKeyChange_1191183121)
  YPathSegment_1191183106 = (when declared(YPathSegment):
    when ownSizeof(YPathSegment) != ownSizeof(YPathSegment_1191183105):
      static :
        warning("Declaration of " & "YPathSegment" &
            " exists but with different size")
    YPathSegment
  else:
    YPathSegment_1191183105)
  StructYUndoManagerOptions_1191183124 = (when declared(
      StructYUndoManagerOptions):
    when ownSizeof(StructYUndoManagerOptions) !=
        ownSizeof(StructYUndoManagerOptions_1191183123):
      static :
        warning("Declaration of " & "StructYUndoManagerOptions" &
            " exists but with different size")
    StructYUndoManagerOptions
  else:
    StructYUndoManagerOptions_1191183123)
  YMapInputData_1191183050 = (when declared(YMapInputData):
    when ownSizeof(YMapInputData) != ownSizeof(YMapInputData_1191183049):
      static :
        warning("Declaration of " & "YMapInputData" &
            " exists but with different size")
    YMapInputData
  else:
    YMapInputData_1191183049)
  union_YPathSegmentCase_1191183100 = (when declared(union_YPathSegmentCase):
    when ownSizeof(union_YPathSegmentCase) != ownSizeof(union_YPathSegmentCase_1191183099):
      static :
        warning("Declaration of " & "union_YPathSegmentCase" &
            " exists but with different size")
    union_YPathSegmentCase
  else:
    union_YPathSegmentCase_1191183099)
  YEvent_1191183098 = (when declared(YEvent):
    when ownSizeof(YEvent) != ownSizeof(YEvent_1191183097):
      static :
        warning("Declaration of " & "YEvent" & " exists but with different size")
    YEvent
  else:
    YEvent_1191183097)
  YIdRangeSeq_1191183026 = (when declared(YIdRangeSeq):
    when ownSizeof(YIdRangeSeq) != ownSizeof(YIdRangeSeq_1191183025):
      static :
        warning("Declaration of " & "YIdRangeSeq" &
            " exists but with different size")
    YIdRangeSeq
  else:
    YIdRangeSeq_1191183025)
  YEventChange_1191183118 = (when declared(YEventChange):
    when ownSizeof(YEventChange) != ownSizeof(YEventChange_1191183117):
      static :
        warning("Declaration of " & "YEventChange" &
            " exists but with different size")
    YEventChange
  else:
    YEventChange_1191183117)
  YMapIter_1191182969 = (when declared(YMapIter):
    when ownSizeof(YMapIter) != ownSizeof(YMapIter_1191182968):
      static :
        warning("Declaration of " & "YMapIter" &
            " exists but with different size")
    YMapIter
  else:
    YMapIter_1191182968)
  union_YBranchIdVariant_1191183134 = (when declared(union_YBranchIdVariant):
    when ownSizeof(union_YBranchIdVariant) != ownSizeof(union_YBranchIdVariant_1191183133):
      static :
        warning("Declaration of " & "union_YBranchIdVariant" &
            " exists but with different size")
    union_YBranchIdVariant
  else:
    union_YBranchIdVariant_1191183133)
  YUndoManagerOptions_1191183126 = (when declared(YUndoManagerOptions):
    when ownSizeof(YUndoManagerOptions) != ownSizeof(YUndoManagerOptions_1191183125):
      static :
        warning("Declaration of " & "YUndoManagerOptions" &
            " exists but with different size")
    YUndoManagerOptions
  else:
    YUndoManagerOptions_1191183125)
  StructYInput_1191183048 = (when declared(StructYInput):
    when ownSizeof(StructYInput) != ownSizeof(StructYInput_1191183047):
      static :
        warning("Declaration of " & "StructYInput" &
            " exists but with different size")
    StructYInput
  else:
    StructYInput_1191183047)
  YInput_1191183058 = (when declared(YInput):
    when ownSizeof(YInput) != ownSizeof(YInput_1191183057):
      static :
        warning("Declaration of " & "YInput" & " exists but with different size")
    YInput
  else:
    YInput_1191183057)
  YWeakLinkEvent_1191183090 = (when declared(YWeakLinkEvent):
    when ownSizeof(YWeakLinkEvent) != ownSizeof(YWeakLinkEvent_1191183089):
      static :
        warning("Declaration of " & "YWeakLinkEvent" &
            " exists but with different size")
    YWeakLinkEvent
  else:
    YWeakLinkEvent_1191183089)
  LinkSource_1191182979 = (when declared(LinkSource):
    when ownSizeof(LinkSource) != ownSizeof(LinkSource_1191182978):
      static :
        warning("Declaration of " & "LinkSource" &
            " exists but with different size")
    LinkSource
  else:
    LinkSource_1191182978)
  Unquote_1191182981 = (when declared(Unquote):
    when ownSizeof(Unquote) != ownSizeof(Unquote_1191182980):
      static :
        warning("Declaration of " & "Unquote" &
            " exists but with different size")
    Unquote
  else:
    Unquote_1191182980)
  StructYBranchId_1191183138 = (when declared(StructYBranchId):
    when ownSizeof(StructYBranchId) != ownSizeof(StructYBranchId_1191183137):
      static :
        warning("Declaration of " & "StructYBranchId" &
            " exists but with different size")
    StructYBranchId
  else:
    StructYBranchId_1191183137)
  YXmlAttrIter_1191182973 = (when declared(YXmlAttrIter):
    when ownSizeof(YXmlAttrIter) != ownSizeof(YXmlAttrIter_1191182972):
      static :
        warning("Declaration of " & "YXmlAttrIter" &
            " exists but with different size")
    YXmlAttrIter
  else:
    YXmlAttrIter_1191182972)
  YXmlEvent_1191183082 = (when declared(YXmlEvent):
    when ownSizeof(YXmlEvent) != ownSizeof(YXmlEvent_1191183081):
      static :
        warning("Declaration of " & "YXmlEvent" &
            " exists but with different size")
    YXmlEvent
  else:
    YXmlEvent_1191183081)
  StructYUndoEvent_1191183128 = (when declared(StructYUndoEvent):
    when ownSizeof(StructYUndoEvent) != ownSizeof(StructYUndoEvent_1191183127):
      static :
        warning("Declaration of " & "StructYUndoEvent" &
            " exists but with different size")
    StructYUndoEvent
  else:
    StructYUndoEvent_1191183127)
  YBranchIdVariant_1191183136 = (when declared(YBranchIdVariant):
    when ownSizeof(YBranchIdVariant) != ownSizeof(YBranchIdVariant_1191183135):
      static :
        warning("Declaration of " & "YBranchIdVariant" &
            " exists but with different size")
    YBranchIdVariant
  else:
    YBranchIdVariant_1191183135)
  StructYStateVector_1191183009 = (when declared(StructYStateVector):
    when ownSizeof(StructYStateVector) != ownSizeof(StructYStateVector_1191183008):
      static :
        warning("Declaration of " & "StructYStateVector" &
            " exists but with different size")
    StructYStateVector
  else:
    StructYStateVector_1191183008)
  YSubdocsEvent_1191183038 = (when declared(YSubdocsEvent):
    when ownSizeof(YSubdocsEvent) != ownSizeof(YSubdocsEvent_1191183037):
      static :
        warning("Declaration of " & "YSubdocsEvent" &
            " exists but with different size")
    YSubdocsEvent
  else:
    YSubdocsEvent_1191183037)
  StructYTextEvent_1191183068 = (when declared(StructYTextEvent):
    when ownSizeof(StructYTextEvent) != ownSizeof(StructYTextEvent_1191183067):
      static :
        warning("Declaration of " & "StructYTextEvent" &
            " exists but with different size")
    StructYTextEvent
  else:
    StructYTextEvent_1191183067)
  YXmlTreeWalker_1191182975 = (when declared(YXmlTreeWalker):
    when ownSizeof(YXmlTreeWalker) != ownSizeof(YXmlTreeWalker_1191182974):
      static :
        warning("Declaration of " & "YXmlTreeWalker" &
            " exists but with different size")
    YXmlTreeWalker
  else:
    YXmlTreeWalker_1191182974)
  YUndoEvent_1191183130 = (when declared(YUndoEvent):
    when ownSizeof(YUndoEvent) != ownSizeof(YUndoEvent_1191183129):
      static :
        warning("Declaration of " & "YUndoEvent" &
            " exists but with different size")
    YUndoEvent
  else:
    YUndoEvent_1191183129)
  StructYXmlEvent_1191183080 = (when declared(StructYXmlEvent):
    when ownSizeof(StructYXmlEvent) != ownSizeof(StructYXmlEvent_1191183079):
      static :
        warning("Declaration of " & "StructYXmlEvent" &
            " exists but with different size")
    StructYXmlEvent
  else:
    StructYXmlEvent_1191183079)
  YDeltaIn_1191183062 = (when declared(YDeltaIn):
    when ownSizeof(YDeltaIn) != ownSizeof(YDeltaIn_1191183061):
      static :
        warning("Declaration of " & "YDeltaIn" &
            " exists but with different size")
    YDeltaIn
  else:
    YDeltaIn_1191183061)
  Weak_1191183052 = (when declared(Weak):
    when ownSizeof(Weak) != ownSizeof(Weak_1191183051):
      static :
        warning("Declaration of " & "Weak" & " exists but with different size")
    Weak
  else:
    Weak_1191183051)
  YDoc_typedef_1191182957 = (when declared(YDoc_typedef):
    when ownSizeof(YDoc_typedef) != ownSizeof(YDoc_typedef_1191182955):
      static :
        warning("Declaration of " & "YDoc_typedef" &
            " exists but with different size")
    YDoc_typedef
  else:
    YDoc_typedef_1191182955)
  YTextEvent_1191183070 = (when declared(YTextEvent):
    when ownSizeof(YTextEvent) != ownSizeof(YTextEvent_1191183069):
      static :
        warning("Declaration of " & "YTextEvent" &
            " exists but with different size")
    YTextEvent
  else:
    YTextEvent_1191183069)
  YInputContent_1191183056 = (when declared(YInputContent):
    when ownSizeof(YInputContent) != ownSizeof(YInputContent_1191183055):
      static :
        warning("Declaration of " & "YInputContent" &
            " exists but with different size")
    YInputContent
  else:
    YInputContent_1191183055)
  YTransaction_1191183040 = (when declared(YTransaction):
    when ownSizeof(YTransaction) != ownSizeof(YTransaction_1191183039):
      static :
        warning("Declaration of " & "YTransaction" &
            " exists but with different size")
    YTransaction
  else:
    YTransaction_1191183039)
  StructYOptions_1191182989 = (when declared(StructYOptions):
    when ownSizeof(StructYOptions) != ownSizeof(StructYOptions_1191182988):
      static :
        warning("Declaration of " & "StructYOptions" &
            " exists but with different size")
    StructYOptions
  else:
    StructYOptions_1191182988)
  YEventContent_1191183094 = (when declared(YEventContent):
    when ownSizeof(YEventContent) != ownSizeof(YEventContent_1191183093):
      static :
        warning("Declaration of " & "YEventContent" &
            " exists but with different size")
    YEventContent
  else:
    YEventContent_1191183093)
  StructYDeltaIn_1191183060 = (when declared(StructYDeltaIn):
    when ownSizeof(StructYDeltaIn) != ownSizeof(StructYDeltaIn_1191183059):
      static :
        warning("Declaration of " & "StructYDeltaIn" &
            " exists but with different size")
    StructYDeltaIn
  else:
    StructYDeltaIn_1191183059)
  YDeltaAttr_1191183110 = (when declared(YDeltaAttr):
    when ownSizeof(YDeltaAttr) != ownSizeof(YDeltaAttr_1191183109):
      static :
        warning("Declaration of " & "YDeltaAttr" &
            " exists but with different size")
    YDeltaAttr
  else:
    YDeltaAttr_1191183109)
  YMapEntry_1191183003 = (when declared(YMapEntry):
    when ownSizeof(YMapEntry) != ownSizeof(YMapEntry_1191183002):
      static :
        warning("Declaration of " & "YMapEntry" &
            " exists but with different size")
    YMapEntry
  else:
    YMapEntry_1191183002)
  YDeleteSet_1191183030 = (when declared(YDeleteSet):
    when ownSizeof(YDeleteSet) != ownSizeof(YDeleteSet_1191183029):
      static :
        warning("Declaration of " & "YDeleteSet" &
            " exists but with different size")
    YDeleteSet
  else:
    YDeleteSet_1191183029)
  StructYWeakLinkEvent_1191183088 = (when declared(StructYWeakLinkEvent):
    when ownSizeof(StructYWeakLinkEvent) != ownSizeof(StructYWeakLinkEvent_1191183087):
      static :
        warning("Declaration of " & "StructYWeakLinkEvent" &
            " exists but with different size")
    StructYWeakLinkEvent
  else:
    StructYWeakLinkEvent_1191183087)
  YWeakIter_1191182965 = (when declared(YWeakIter):
    when ownSizeof(YWeakIter) != ownSizeof(YWeakIter_1191182964):
      static :
        warning("Declaration of " & "YWeakIter" &
            " exists but with different size")
    YWeakIter
  else:
    YWeakIter_1191182964)
  YPendingUpdate_1191183044 = (when declared(YPendingUpdate):
    when ownSizeof(YPendingUpdate) != ownSizeof(YPendingUpdate_1191183043):
      static :
        warning("Declaration of " & "YPendingUpdate" &
            " exists but with different size")
    YPendingUpdate
  else:
    YPendingUpdate_1191183043)
  StructYMapEvent_1191183072 = (when declared(StructYMapEvent):
    when ownSizeof(StructYMapEvent) != ownSizeof(StructYMapEvent_1191183071):
      static :
        warning("Declaration of " & "StructYMapEvent" &
            " exists but with different size")
    StructYMapEvent
  else:
    StructYMapEvent_1191183071)
  union_YEventContent_1191183092 = (when declared(union_YEventContent):
    when ownSizeof(union_YEventContent) != ownSizeof(union_YEventContent_1191183091):
      static :
        warning("Declaration of " & "union_YEventContent" &
            " exists but with different size")
    union_YEventContent
  else:
    union_YEventContent_1191183091)
  StructYEventChange_1191183116 = (when declared(StructYEventChange):
    when ownSizeof(StructYEventChange) != ownSizeof(StructYEventChange_1191183115):
      static :
        warning("Declaration of " & "StructYEventChange" &
            " exists but with different size")
    StructYEventChange
  else:
    StructYEventChange_1191183115)
  StructYIdRange_1191183013 = (when declared(StructYIdRange):
    when ownSizeof(StructYIdRange) != ownSizeof(StructYIdRange_1191183012):
      static :
        warning("Declaration of " & "StructYIdRange" &
            " exists but with different size")
    StructYIdRange
  else:
    StructYIdRange_1191183012)
  StructYIdRangeSeq_1191183024 = (when declared(StructYIdRangeSeq):
    when ownSizeof(StructYIdRangeSeq) != ownSizeof(StructYIdRangeSeq_1191183023):
      static :
        warning("Declaration of " & "StructYIdRangeSeq" &
            " exists but with different size")
    StructYIdRangeSeq
  else:
    StructYIdRangeSeq_1191183023)
  StructYMapInputData_1191183046 = (when declared(StructYMapInputData):
    when ownSizeof(StructYMapInputData) != ownSizeof(StructYMapInputData_1191183045):
      static :
        warning("Declaration of " & "StructYMapInputData" &
            " exists but with different size")
    StructYMapInputData
  else:
    StructYMapInputData_1191183045)
  YOptions_1191182991 = (when declared(YOptions):
    when ownSizeof(YOptions) != ownSizeof(YOptions_1191182990):
      static :
        warning("Declaration of " & "YOptions" &
            " exists but with different size")
    YOptions
  else:
    YOptions_1191182990)
  YBranchId_1191183140 = (when declared(YBranchId):
    when ownSizeof(YBranchId) != ownSizeof(YBranchId_1191183139):
      static :
        warning("Declaration of " & "YBranchId" &
            " exists but with different size")
    YBranchId
  else:
    YBranchId_1191183139)
  union_YOutputContent_1191182993 = (when declared(union_YOutputContent):
    when ownSizeof(union_YOutputContent) != ownSizeof(union_YOutputContent_1191182992):
      static :
        warning("Declaration of " & "union_YOutputContent" &
            " exists but with different size")
    union_YOutputContent
  else:
    union_YOutputContent_1191182992)
  Transaction_1191182961 = (when declared(Transaction):
    when ownSizeof(Transaction) != ownSizeof(Transaction_1191182960):
      static :
        warning("Declaration of " & "Transaction" &
            " exists but with different size")
    Transaction
  else:
    Transaction_1191182960)
  YStateVector_1191183011 = (when declared(YStateVector):
    when ownSizeof(YStateVector) != ownSizeof(YStateVector_1191183010):
      static :
        warning("Declaration of " & "YStateVector" &
            " exists but with different size")
    YStateVector
  else:
    YStateVector_1191183010)
  StructYMapEntry_1191182997 = (when declared(StructYMapEntry):
    when ownSizeof(StructYMapEntry) != ownSizeof(StructYMapEntry_1191182996):
      static :
        warning("Declaration of " & "StructYMapEntry" &
            " exists but with different size")
    StructYMapEntry
  else:
    StructYMapEntry_1191182996)
  StructYChunk_1191183064 = (when declared(StructYChunk):
    when ownSizeof(StructYChunk) != ownSizeof(StructYChunk_1191183063):
      static :
        warning("Declaration of " & "StructYChunk" &
            " exists but with different size")
    StructYChunk
  else:
    StructYChunk_1191183063)
  StructYEventKeyChange_1191183120 = (when declared(StructYEventKeyChange):
    when ownSizeof(StructYEventKeyChange) != ownSizeof(StructYEventKeyChange_1191183119):
      static :
        warning("Declaration of " & "StructYEventKeyChange" &
            " exists but with different size")
    StructYEventKeyChange
  else:
    StructYEventKeyChange_1191183119)
  StructYDeltaOut_1191183112 = (when declared(StructYDeltaOut):
    when ownSizeof(StructYDeltaOut) != ownSizeof(StructYDeltaOut_1191183111):
      static :
        warning("Declaration of " & "StructYDeltaOut" &
            " exists but with different size")
    StructYDeltaOut
  else:
    StructYDeltaOut_1191183111)
  StructYSubdocsEvent_1191183036 = (when declared(StructYSubdocsEvent):
    when ownSizeof(StructYSubdocsEvent) != ownSizeof(StructYSubdocsEvent_1191183035):
      static :
        warning("Declaration of " & "StructYSubdocsEvent" &
            " exists but with different size")
    StructYSubdocsEvent
  else:
    StructYSubdocsEvent_1191183035)
  YAfterTransactionEvent_1191183034 = (when declared(YAfterTransactionEvent):
    when ownSizeof(YAfterTransactionEvent) != ownSizeof(YAfterTransactionEvent_1191183033):
      static :
        warning("Declaration of " & "YAfterTransactionEvent" &
            " exists but with different size")
    YAfterTransactionEvent
  else:
    YAfterTransactionEvent_1191183033)
  union_YInputContent_1191183054 = (when declared(union_YInputContent):
    when ownSizeof(union_YInputContent) != ownSizeof(union_YInputContent_1191183053):
      static :
        warning("Declaration of " & "union_YInputContent" &
            " exists but with different size")
    union_YInputContent
  else:
    union_YInputContent_1191183053)
  StructYDeleteSet_1191183028 = (when declared(StructYDeleteSet):
    when ownSizeof(StructYDeleteSet) != ownSizeof(StructYDeleteSet_1191183027):
      static :
        warning("Declaration of " & "StructYDeleteSet" &
            " exists but with different size")
    StructYDeleteSet
  else:
    StructYDeleteSet_1191183027)
  YUndoManager_1191182977 = (when declared(YUndoManager):
    when ownSizeof(YUndoManager) != ownSizeof(YUndoManager_1191182976):
      static :
        warning("Declaration of " & "YUndoManager" &
            " exists but with different size")
    YUndoManager
  else:
    YUndoManager_1191182976)
  StructYOutput_1191182995 = (when declared(StructYOutput):
    when ownSizeof(StructYOutput) != ownSizeof(StructYOutput_1191182994):
      static :
        warning("Declaration of " & "StructYOutput" &
            " exists but with different size")
    StructYOutput
  else:
    StructYOutput_1191182994)
when not declared(StructYEvent):
  type
    StructYEvent* = StructYEvent_1191183095
else:
  static :
    hint("Declaration of " & "StructYEvent" & " already exists, not redeclaring")
when not declared(StructYXmlTextEvent):
  type
    StructYXmlTextEvent* = StructYXmlTextEvent_1191183083
else:
  static :
    hint("Declaration of " & "StructYXmlTextEvent" &
        " already exists, not redeclaring")
when not declared(StructYPendingUpdate):
  type
    StructYPendingUpdate* = StructYPendingUpdate_1191183041
else:
  static :
    hint("Declaration of " & "StructYPendingUpdate" &
        " already exists, not redeclaring")
when not declared(YDeltaOut):
  type
    YDeltaOut* = YDeltaOut_1191183113
else:
  static :
    hint("Declaration of " & "YDeltaOut" & " already exists, not redeclaring")
when not declared(YArrayIter):
  type
    YArrayIter* = YArrayIter_1191182966
else:
  static :
    hint("Declaration of " & "YArrayIter" & " already exists, not redeclaring")
when not declared(StructYAfterTransactionEvent):
  type
    StructYAfterTransactionEvent* = StructYAfterTransactionEvent_1191183031
else:
  static :
    hint("Declaration of " & "StructYAfterTransactionEvent" &
        " already exists, not redeclaring")
when not declared(YJsonPathIter):
  type
    YJsonPathIter* = YJsonPathIter_1191182970
else:
  static :
    hint("Declaration of " & "YJsonPathIter" &
        " already exists, not redeclaring")
when not declared(StructYDeltaAttr):
  type
    StructYDeltaAttr* = StructYDeltaAttr_1191183107
else:
  static :
    hint("Declaration of " & "StructYDeltaAttr" &
        " already exists, not redeclaring")
when not declared(YStickyIndex):
  type
    YStickyIndex* = YStickyIndex_1191183131
else:
  static :
    hint("Declaration of " & "YStickyIndex" & " already exists, not redeclaring")
when not declared(YChunk):
  type
    YChunk* = YChunk_1191183065
else:
  static :
    hint("Declaration of " & "YChunk" & " already exists, not redeclaring")
when not declared(YXmlAttr):
  type
    YXmlAttr* = YXmlAttr_1191183006
else:
  static :
    hint("Declaration of " & "YXmlAttr" & " already exists, not redeclaring")
when not declared(StructYXmlAttr):
  type
    StructYXmlAttr* = StructYXmlAttr_1191183004
else:
  static :
    hint("Declaration of " & "StructYXmlAttr" &
        " already exists, not redeclaring")
when not declared(YOutputContent):
  type
    YOutputContent* = YOutputContent_1191182998
else:
  static :
    hint("Declaration of " & "YOutputContent" &
        " already exists, not redeclaring")
when not declared(YOutput):
  type
    YOutput* = YOutput_1191183000
else:
  static :
    hint("Declaration of " & "YOutput" & " already exists, not redeclaring")
when not declared(YXmlTextEvent):
  type
    YXmlTextEvent* = YXmlTextEvent_1191183085
else:
  static :
    hint("Declaration of " & "YXmlTextEvent" &
        " already exists, not redeclaring")
when not declared(YMapEvent):
  type
    YMapEvent* = YMapEvent_1191183073
else:
  static :
    hint("Declaration of " & "YMapEvent" & " already exists, not redeclaring")
when not declared(YArrayEvent):
  type
    YArrayEvent* = YArrayEvent_1191183077
else:
  static :
    hint("Declaration of " & "YArrayEvent" & " already exists, not redeclaring")
when not declared(StructYPathSegment):
  type
    StructYPathSegment* = StructYPathSegment_1191183103
else:
  static :
    hint("Declaration of " & "StructYPathSegment" &
        " already exists, not redeclaring")
when not declared(TransactionMut):
  type
    TransactionMut* = TransactionMut_1191182962
else:
  static :
    hint("Declaration of " & "TransactionMut" &
        " already exists, not redeclaring")
when not declared(YSubscription):
  type
    YSubscription* = YSubscription_1191182984
else:
  static :
    hint("Declaration of " & "YSubscription" &
        " already exists, not redeclaring")
when not declared(StickyIndex):
  type
    StickyIndex* = StickyIndex_1191182982
else:
  static :
    hint("Declaration of " & "StickyIndex" & " already exists, not redeclaring")
when not declared(YPathSegmentCase):
  type
    YPathSegmentCase* = YPathSegmentCase_1191183101
else:
  static :
    hint("Declaration of " & "YPathSegmentCase" &
        " already exists, not redeclaring")
when not declared(Branch):
  type
    Branch* = Branch_1191182958
else:
  static :
    hint("Declaration of " & "Branch" & " already exists, not redeclaring")
when not declared(StructYArrayEvent):
  type
    StructYArrayEvent* = StructYArrayEvent_1191183075
else:
  static :
    hint("Declaration of " & "StructYArrayEvent" &
        " already exists, not redeclaring")
when not declared(TransactionInner):
  type
    TransactionInner* = TransactionInner_1191182986
else:
  static :
    hint("Declaration of " & "TransactionInner" &
        " already exists, not redeclaring")
when not declared(YIdRange):
  type
    YIdRange* = YIdRange_1191183021
else:
  static :
    hint("Declaration of " & "YIdRange" & " already exists, not redeclaring")
when not declared(YEventKeyChange):
  type
    YEventKeyChange* = YEventKeyChange_1191183121
else:
  static :
    hint("Declaration of " & "YEventKeyChange" &
        " already exists, not redeclaring")
when not declared(YPathSegment):
  type
    YPathSegment* = YPathSegment_1191183105
else:
  static :
    hint("Declaration of " & "YPathSegment" & " already exists, not redeclaring")
when not declared(StructYUndoManagerOptions):
  type
    StructYUndoManagerOptions* = StructYUndoManagerOptions_1191183123
else:
  static :
    hint("Declaration of " & "StructYUndoManagerOptions" &
        " already exists, not redeclaring")
when not declared(YMapInputData):
  type
    YMapInputData* = YMapInputData_1191183049
else:
  static :
    hint("Declaration of " & "YMapInputData" &
        " already exists, not redeclaring")
when not declared(union_YPathSegmentCase):
  type
    union_YPathSegmentCase* = union_YPathSegmentCase_1191183099
else:
  static :
    hint("Declaration of " & "union_YPathSegmentCase" &
        " already exists, not redeclaring")
when not declared(YEvent):
  type
    YEvent* = YEvent_1191183097
else:
  static :
    hint("Declaration of " & "YEvent" & " already exists, not redeclaring")
when not declared(YIdRangeSeq):
  type
    YIdRangeSeq* = YIdRangeSeq_1191183025
else:
  static :
    hint("Declaration of " & "YIdRangeSeq" & " already exists, not redeclaring")
when not declared(YEventChange):
  type
    YEventChange* = YEventChange_1191183117
else:
  static :
    hint("Declaration of " & "YEventChange" & " already exists, not redeclaring")
when not declared(YMapIter):
  type
    YMapIter* = YMapIter_1191182968
else:
  static :
    hint("Declaration of " & "YMapIter" & " already exists, not redeclaring")
when not declared(union_YBranchIdVariant):
  type
    union_YBranchIdVariant* = union_YBranchIdVariant_1191183133
else:
  static :
    hint("Declaration of " & "union_YBranchIdVariant" &
        " already exists, not redeclaring")
when not declared(YUndoManagerOptions):
  type
    YUndoManagerOptions* = YUndoManagerOptions_1191183125
else:
  static :
    hint("Declaration of " & "YUndoManagerOptions" &
        " already exists, not redeclaring")
when not declared(StructYInput):
  type
    StructYInput* = StructYInput_1191183047
else:
  static :
    hint("Declaration of " & "StructYInput" & " already exists, not redeclaring")
when not declared(YInput):
  type
    YInput* = YInput_1191183057
else:
  static :
    hint("Declaration of " & "YInput" & " already exists, not redeclaring")
when not declared(YWeakLinkEvent):
  type
    YWeakLinkEvent* = YWeakLinkEvent_1191183089
else:
  static :
    hint("Declaration of " & "YWeakLinkEvent" &
        " already exists, not redeclaring")
when not declared(LinkSource):
  type
    LinkSource* = LinkSource_1191182978
else:
  static :
    hint("Declaration of " & "LinkSource" & " already exists, not redeclaring")
when not declared(Unquote):
  type
    Unquote* = Unquote_1191182980
else:
  static :
    hint("Declaration of " & "Unquote" & " already exists, not redeclaring")
when not declared(StructYBranchId):
  type
    StructYBranchId* = StructYBranchId_1191183137
else:
  static :
    hint("Declaration of " & "StructYBranchId" &
        " already exists, not redeclaring")
when not declared(YXmlAttrIter):
  type
    YXmlAttrIter* = YXmlAttrIter_1191182972
else:
  static :
    hint("Declaration of " & "YXmlAttrIter" & " already exists, not redeclaring")
when not declared(YXmlEvent):
  type
    YXmlEvent* = YXmlEvent_1191183081
else:
  static :
    hint("Declaration of " & "YXmlEvent" & " already exists, not redeclaring")
when not declared(StructYUndoEvent):
  type
    StructYUndoEvent* = StructYUndoEvent_1191183127
else:
  static :
    hint("Declaration of " & "StructYUndoEvent" &
        " already exists, not redeclaring")
when not declared(YBranchIdVariant):
  type
    YBranchIdVariant* = YBranchIdVariant_1191183135
else:
  static :
    hint("Declaration of " & "YBranchIdVariant" &
        " already exists, not redeclaring")
when not declared(StructYStateVector):
  type
    StructYStateVector* = StructYStateVector_1191183008
else:
  static :
    hint("Declaration of " & "StructYStateVector" &
        " already exists, not redeclaring")
when not declared(YSubdocsEvent):
  type
    YSubdocsEvent* = YSubdocsEvent_1191183037
else:
  static :
    hint("Declaration of " & "YSubdocsEvent" &
        " already exists, not redeclaring")
when not declared(StructYTextEvent):
  type
    StructYTextEvent* = StructYTextEvent_1191183067
else:
  static :
    hint("Declaration of " & "StructYTextEvent" &
        " already exists, not redeclaring")
when not declared(YXmlTreeWalker):
  type
    YXmlTreeWalker* = YXmlTreeWalker_1191182974
else:
  static :
    hint("Declaration of " & "YXmlTreeWalker" &
        " already exists, not redeclaring")
when not declared(YUndoEvent):
  type
    YUndoEvent* = YUndoEvent_1191183129
else:
  static :
    hint("Declaration of " & "YUndoEvent" & " already exists, not redeclaring")
when not declared(StructYXmlEvent):
  type
    StructYXmlEvent* = StructYXmlEvent_1191183079
else:
  static :
    hint("Declaration of " & "StructYXmlEvent" &
        " already exists, not redeclaring")
when not declared(YDeltaIn):
  type
    YDeltaIn* = YDeltaIn_1191183061
else:
  static :
    hint("Declaration of " & "YDeltaIn" & " already exists, not redeclaring")
when not declared(Weak):
  type
    Weak* = Weak_1191183051
else:
  static :
    hint("Declaration of " & "Weak" & " already exists, not redeclaring")
when not declared(YDoc_typedef):
  type
    YDoc_typedef* = YDoc_typedef_1191182955
else:
  static :
    hint("Declaration of " & "YDoc_typedef" & " already exists, not redeclaring")
when not declared(YTextEvent):
  type
    YTextEvent* = YTextEvent_1191183069
else:
  static :
    hint("Declaration of " & "YTextEvent" & " already exists, not redeclaring")
when not declared(YInputContent):
  type
    YInputContent* = YInputContent_1191183055
else:
  static :
    hint("Declaration of " & "YInputContent" &
        " already exists, not redeclaring")
when not declared(YTransaction):
  type
    YTransaction* = YTransaction_1191183039
else:
  static :
    hint("Declaration of " & "YTransaction" & " already exists, not redeclaring")
when not declared(StructYOptions):
  type
    StructYOptions* = StructYOptions_1191182988
else:
  static :
    hint("Declaration of " & "StructYOptions" &
        " already exists, not redeclaring")
when not declared(YEventContent):
  type
    YEventContent* = YEventContent_1191183093
else:
  static :
    hint("Declaration of " & "YEventContent" &
        " already exists, not redeclaring")
when not declared(StructYDeltaIn):
  type
    StructYDeltaIn* = StructYDeltaIn_1191183059
else:
  static :
    hint("Declaration of " & "StructYDeltaIn" &
        " already exists, not redeclaring")
when not declared(YDeltaAttr):
  type
    YDeltaAttr* = YDeltaAttr_1191183109
else:
  static :
    hint("Declaration of " & "YDeltaAttr" & " already exists, not redeclaring")
when not declared(YMapEntry):
  type
    YMapEntry* = YMapEntry_1191183002
else:
  static :
    hint("Declaration of " & "YMapEntry" & " already exists, not redeclaring")
when not declared(YDeleteSet):
  type
    YDeleteSet* = YDeleteSet_1191183029
else:
  static :
    hint("Declaration of " & "YDeleteSet" & " already exists, not redeclaring")
when not declared(StructYWeakLinkEvent):
  type
    StructYWeakLinkEvent* = StructYWeakLinkEvent_1191183087
else:
  static :
    hint("Declaration of " & "StructYWeakLinkEvent" &
        " already exists, not redeclaring")
when not declared(YWeakIter):
  type
    YWeakIter* = YWeakIter_1191182964
else:
  static :
    hint("Declaration of " & "YWeakIter" & " already exists, not redeclaring")
when not declared(YPendingUpdate):
  type
    YPendingUpdate* = YPendingUpdate_1191183043
else:
  static :
    hint("Declaration of " & "YPendingUpdate" &
        " already exists, not redeclaring")
when not declared(StructYMapEvent):
  type
    StructYMapEvent* = StructYMapEvent_1191183071
else:
  static :
    hint("Declaration of " & "StructYMapEvent" &
        " already exists, not redeclaring")
when not declared(union_YEventContent):
  type
    union_YEventContent* = union_YEventContent_1191183091
else:
  static :
    hint("Declaration of " & "union_YEventContent" &
        " already exists, not redeclaring")
when not declared(StructYEventChange):
  type
    StructYEventChange* = StructYEventChange_1191183115
else:
  static :
    hint("Declaration of " & "StructYEventChange" &
        " already exists, not redeclaring")
when not declared(StructYIdRange):
  type
    StructYIdRange* = StructYIdRange_1191183012
else:
  static :
    hint("Declaration of " & "StructYIdRange" &
        " already exists, not redeclaring")
when not declared(StructYIdRangeSeq):
  type
    StructYIdRangeSeq* = StructYIdRangeSeq_1191183023
else:
  static :
    hint("Declaration of " & "StructYIdRangeSeq" &
        " already exists, not redeclaring")
when not declared(StructYMapInputData):
  type
    StructYMapInputData* = StructYMapInputData_1191183045
else:
  static :
    hint("Declaration of " & "StructYMapInputData" &
        " already exists, not redeclaring")
when not declared(YOptions):
  type
    YOptions* = YOptions_1191182990
else:
  static :
    hint("Declaration of " & "YOptions" & " already exists, not redeclaring")
when not declared(YBranchId):
  type
    YBranchId* = YBranchId_1191183139
else:
  static :
    hint("Declaration of " & "YBranchId" & " already exists, not redeclaring")
when not declared(union_YOutputContent):
  type
    union_YOutputContent* = union_YOutputContent_1191182992
else:
  static :
    hint("Declaration of " & "union_YOutputContent" &
        " already exists, not redeclaring")
when not declared(Transaction):
  type
    Transaction* = Transaction_1191182960
else:
  static :
    hint("Declaration of " & "Transaction" & " already exists, not redeclaring")
when not declared(YStateVector):
  type
    YStateVector* = YStateVector_1191183010
else:
  static :
    hint("Declaration of " & "YStateVector" & " already exists, not redeclaring")
when not declared(StructYMapEntry):
  type
    StructYMapEntry* = StructYMapEntry_1191182996
else:
  static :
    hint("Declaration of " & "StructYMapEntry" &
        " already exists, not redeclaring")
when not declared(StructYChunk):
  type
    StructYChunk* = StructYChunk_1191183063
else:
  static :
    hint("Declaration of " & "StructYChunk" & " already exists, not redeclaring")
when not declared(StructYEventKeyChange):
  type
    StructYEventKeyChange* = StructYEventKeyChange_1191183119
else:
  static :
    hint("Declaration of " & "StructYEventKeyChange" &
        " already exists, not redeclaring")
when not declared(StructYDeltaOut):
  type
    StructYDeltaOut* = StructYDeltaOut_1191183111
else:
  static :
    hint("Declaration of " & "StructYDeltaOut" &
        " already exists, not redeclaring")
when not declared(StructYSubdocsEvent):
  type
    StructYSubdocsEvent* = StructYSubdocsEvent_1191183035
else:
  static :
    hint("Declaration of " & "StructYSubdocsEvent" &
        " already exists, not redeclaring")
when not declared(YAfterTransactionEvent):
  type
    YAfterTransactionEvent* = YAfterTransactionEvent_1191183033
else:
  static :
    hint("Declaration of " & "YAfterTransactionEvent" &
        " already exists, not redeclaring")
when not declared(union_YInputContent):
  type
    union_YInputContent* = union_YInputContent_1191183053
else:
  static :
    hint("Declaration of " & "union_YInputContent" &
        " already exists, not redeclaring")
when not declared(StructYDeleteSet):
  type
    StructYDeleteSet* = StructYDeleteSet_1191183027
else:
  static :
    hint("Declaration of " & "StructYDeleteSet" &
        " already exists, not redeclaring")
when not declared(YUndoManager):
  type
    YUndoManager* = YUndoManager_1191182976
else:
  static :
    hint("Declaration of " & "YUndoManager" & " already exists, not redeclaring")
when not declared(StructYOutput):
  type
    StructYOutput* = StructYOutput_1191182994
else:
  static :
    hint("Declaration of " & "StructYOutput" &
        " already exists, not redeclaring")
when not declared(Y_JSON):
  when -9 is static:
    const
      Y_JSON* = -9           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:107:9
  else:
    let Y_JSON* = -9         ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:107:9
else:
  static :
    hint("Declaration of " & "Y_JSON" & " already exists, not redeclaring")
when not declared(Y_JSON_BOOL):
  when -8 is static:
    const
      Y_JSON_BOOL* = -8      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:112:9
  else:
    let Y_JSON_BOOL* = -8    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:112:9
else:
  static :
    hint("Declaration of " & "Y_JSON_BOOL" & " already exists, not redeclaring")
when not declared(Y_JSON_NUM):
  when -7 is static:
    const
      Y_JSON_NUM* = -7       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:117:9
  else:
    let Y_JSON_NUM* = -7     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:117:9
else:
  static :
    hint("Declaration of " & "Y_JSON_NUM" & " already exists, not redeclaring")
when not declared(Y_JSON_INT):
  when -6 is static:
    const
      Y_JSON_INT* = -6       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:122:9
  else:
    let Y_JSON_INT* = -6     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:122:9
else:
  static :
    hint("Declaration of " & "Y_JSON_INT" & " already exists, not redeclaring")
when not declared(Y_JSON_STR):
  when -5 is static:
    const
      Y_JSON_STR* = -5       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:127:9
  else:
    let Y_JSON_STR* = -5     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:127:9
else:
  static :
    hint("Declaration of " & "Y_JSON_STR" & " already exists, not redeclaring")
when not declared(Y_JSON_BUF):
  when -4 is static:
    const
      Y_JSON_BUF* = -4       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:132:9
  else:
    let Y_JSON_BUF* = -4     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:132:9
else:
  static :
    hint("Declaration of " & "Y_JSON_BUF" & " already exists, not redeclaring")
when not declared(Y_JSON_ARR):
  when -3 is static:
    const
      Y_JSON_ARR* = -3       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:138:9
  else:
    let Y_JSON_ARR* = -3     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:138:9
else:
  static :
    hint("Declaration of " & "Y_JSON_ARR" & " already exists, not redeclaring")
when not declared(Y_JSON_MAP):
  when -2 is static:
    const
      Y_JSON_MAP* = -2       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:144:9
  else:
    let Y_JSON_MAP* = -2     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:144:9
else:
  static :
    hint("Declaration of " & "Y_JSON_MAP" & " already exists, not redeclaring")
when not declared(Y_JSON_NULL):
  when -1 is static:
    const
      Y_JSON_NULL* = -1      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:149:9
  else:
    let Y_JSON_NULL* = -1    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:149:9
else:
  static :
    hint("Declaration of " & "Y_JSON_NULL" & " already exists, not redeclaring")
when not declared(Y_JSON_UNDEF):
  when 0 is static:
    const
      Y_JSON_UNDEF* = 0      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:154:9
  else:
    let Y_JSON_UNDEF* = 0    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:154:9
else:
  static :
    hint("Declaration of " & "Y_JSON_UNDEF" & " already exists, not redeclaring")
when not declared(Y_ARRAY):
  when 1 is static:
    const
      Y_ARRAY* = 1           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:159:9
  else:
    let Y_ARRAY* = 1         ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:159:9
else:
  static :
    hint("Declaration of " & "Y_ARRAY" & " already exists, not redeclaring")
when not declared(Y_MAP):
  when 2 is static:
    const
      Y_MAP* = 2             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:164:9
  else:
    let Y_MAP* = 2           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:164:9
else:
  static :
    hint("Declaration of " & "Y_MAP" & " already exists, not redeclaring")
when not declared(Y_TEXT):
  when 3 is static:
    const
      Y_TEXT* = 3            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:169:9
  else:
    let Y_TEXT* = 3          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:169:9
else:
  static :
    hint("Declaration of " & "Y_TEXT" & " already exists, not redeclaring")
when not declared(Y_XML_ELEM):
  when 4 is static:
    const
      Y_XML_ELEM* = 4        ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:174:9
  else:
    let Y_XML_ELEM* = 4      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:174:9
else:
  static :
    hint("Declaration of " & "Y_XML_ELEM" & " already exists, not redeclaring")
when not declared(Y_XML_TEXT):
  when 5 is static:
    const
      Y_XML_TEXT* = 5        ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:179:9
  else:
    let Y_XML_TEXT* = 5      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:179:9
else:
  static :
    hint("Declaration of " & "Y_XML_TEXT" & " already exists, not redeclaring")
when not declared(Y_XML_FRAG):
  when 6 is static:
    const
      Y_XML_FRAG* = 6        ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:184:9
  else:
    let Y_XML_FRAG* = 6      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:184:9
else:
  static :
    hint("Declaration of " & "Y_XML_FRAG" & " already exists, not redeclaring")
when not declared(Y_DOC):
  when 7 is static:
    const
      Y_DOC* = 7             ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:189:9
  else:
    let Y_DOC* = 7           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:189:9
else:
  static :
    hint("Declaration of " & "Y_DOC" & " already exists, not redeclaring")
when not declared(Y_WEAK_LINK):
  when 8 is static:
    const
      Y_WEAK_LINK* = 8       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:194:9
  else:
    let Y_WEAK_LINK* = 8     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:194:9
else:
  static :
    hint("Declaration of " & "Y_WEAK_LINK" & " already exists, not redeclaring")
when not declared(Y_UNDEFINED):
  when 9 is static:
    const
      Y_UNDEFINED* = 9       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:200:9
  else:
    let Y_UNDEFINED* = 9     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:200:9
else:
  static :
    hint("Declaration of " & "Y_UNDEFINED" & " already exists, not redeclaring")
when not declared(Y_TRUE):
  when 1 is static:
    const
      Y_TRUE* = 1            ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:205:9
  else:
    let Y_TRUE* = 1          ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:205:9
else:
  static :
    hint("Declaration of " & "Y_TRUE" & " already exists, not redeclaring")
when not declared(Y_FALSE):
  when 0 is static:
    const
      Y_FALSE* = 0           ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:210:9
  else:
    let Y_FALSE* = 0         ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:210:9
else:
  static :
    hint("Declaration of " & "Y_FALSE" & " already exists, not redeclaring")
when not declared(Y_OFFSET_BYTES):
  when 0 is static:
    const
      Y_OFFSET_BYTES* = 0    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:216:9
  else:
    let Y_OFFSET_BYTES* = 0  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:216:9
else:
  static :
    hint("Declaration of " & "Y_OFFSET_BYTES" &
        " already exists, not redeclaring")
when not declared(Y_OFFSET_UTF16):
  when 1 is static:
    const
      Y_OFFSET_UTF16* = 1    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:222:9
  else:
    let Y_OFFSET_UTF16* = 1  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:222:9
else:
  static :
    hint("Declaration of " & "Y_OFFSET_UTF16" &
        " already exists, not redeclaring")
when not declared(ERR_CODE_IO):
  when 1 is static:
    const
      ERR_CODE_IO* = 1       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:227:9
  else:
    let ERR_CODE_IO* = 1     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:227:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_IO" & " already exists, not redeclaring")
when not declared(ERR_CODE_VAR_INT):
  when 2 is static:
    const
      ERR_CODE_VAR_INT* = 2  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:232:9
  else:
    let ERR_CODE_VAR_INT* = 2 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:232:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_VAR_INT" &
        " already exists, not redeclaring")
when not declared(ERR_CODE_EOS):
  when 3 is static:
    const
      ERR_CODE_EOS* = 3      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:237:9
  else:
    let ERR_CODE_EOS* = 3    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:237:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_EOS" & " already exists, not redeclaring")
when not declared(ERR_CODE_UNEXPECTED_VALUE):
  when 4 is static:
    const
      ERR_CODE_UNEXPECTED_VALUE* = 4 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:242:9
  else:
    let ERR_CODE_UNEXPECTED_VALUE* = 4 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:242:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_UNEXPECTED_VALUE" &
        " already exists, not redeclaring")
when not declared(ERR_CODE_INVALID_JSON):
  when 5 is static:
    const
      ERR_CODE_INVALID_JSON* = 5 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:247:9
  else:
    let ERR_CODE_INVALID_JSON* = 5 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:247:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_INVALID_JSON" &
        " already exists, not redeclaring")
when not declared(ERR_CODE_OTHER):
  when 6 is static:
    const
      ERR_CODE_OTHER* = 6    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:252:9
  else:
    let ERR_CODE_OTHER* = 6  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:252:9
else:
  static :
    hint("Declaration of " & "ERR_CODE_OTHER" &
        " already exists, not redeclaring")
when not declared(ERR_NOT_ENOUGH_MEMORY):
  when 7 is static:
    const
      ERR_NOT_ENOUGH_MEMORY* = 7 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:257:9
  else:
    let ERR_NOT_ENOUGH_MEMORY* = 7 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:257:9
else:
  static :
    hint("Declaration of " & "ERR_NOT_ENOUGH_MEMORY" &
        " already exists, not redeclaring")
when not declared(ERR_TYPE_MISMATCH):
  when 8 is static:
    const
      ERR_TYPE_MISMATCH* = 8 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:262:9
  else:
    let ERR_TYPE_MISMATCH* = 8 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:262:9
else:
  static :
    hint("Declaration of " & "ERR_TYPE_MISMATCH" &
        " already exists, not redeclaring")
when not declared(ERR_CUSTOM):
  when 9 is static:
    const
      ERR_CUSTOM* = 9        ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:267:9
  else:
    let ERR_CUSTOM* = 9      ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:267:9
else:
  static :
    hint("Declaration of " & "ERR_CUSTOM" & " already exists, not redeclaring")
when not declared(ERR_INVALID_PARENT):
  when 9 is static:
    const
      ERR_INVALID_PARENT* = 9 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:272:9
  else:
    let ERR_INVALID_PARENT* = 9 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:272:9
else:
  static :
    hint("Declaration of " & "ERR_INVALID_PARENT" &
        " already exists, not redeclaring")
when not declared(YCHANGE_ADD):
  when 1 is static:
    const
      YCHANGE_ADD* = 1       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:274:9
  else:
    let YCHANGE_ADD* = 1     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:274:9
else:
  static :
    hint("Declaration of " & "YCHANGE_ADD" & " already exists, not redeclaring")
when not declared(YCHANGE_RETAIN):
  when 0 is static:
    const
      YCHANGE_RETAIN* = 0    ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:276:9
  else:
    let YCHANGE_RETAIN* = 0  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:276:9
else:
  static :
    hint("Declaration of " & "YCHANGE_RETAIN" &
        " already exists, not redeclaring")
when not declared(YCHANGE_REMOVE):
  when -1 is static:
    const
      YCHANGE_REMOVE* = -1   ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:278:9
  else:
    let YCHANGE_REMOVE* = -1 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:278:9
else:
  static :
    hint("Declaration of " & "YCHANGE_REMOVE" &
        " already exists, not redeclaring")
when not declared(Y_KIND_UNDO):
  when 0 is static:
    const
      Y_KIND_UNDO* = 0       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:280:9
  else:
    let Y_KIND_UNDO* = 0     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:280:9
else:
  static :
    hint("Declaration of " & "Y_KIND_UNDO" & " already exists, not redeclaring")
when not declared(Y_KIND_REDO):
  when 1 is static:
    const
      Y_KIND_REDO* = 1       ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:282:9
  else:
    let Y_KIND_REDO* = 1     ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:282:9
else:
  static :
    hint("Declaration of " & "Y_KIND_REDO" & " already exists, not redeclaring")
when not declared(Y_EVENT_PATH_KEY):
  when 1 is static:
    const
      Y_EVENT_PATH_KEY* = 1  ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:287:9
  else:
    let Y_EVENT_PATH_KEY* = 1 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:287:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_PATH_KEY" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_PATH_INDEX):
  when 2 is static:
    const
      Y_EVENT_PATH_INDEX* = 2 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:292:9
  else:
    let Y_EVENT_PATH_INDEX* = 2 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:292:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_PATH_INDEX" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_CHANGE_ADD):
  when 1 is static:
    const
      Y_EVENT_CHANGE_ADD* = 1 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:298:9
  else:
    let Y_EVENT_CHANGE_ADD* = 1 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:298:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_CHANGE_ADD" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_CHANGE_DELETE):
  when 2 is static:
    const
      Y_EVENT_CHANGE_DELETE* = 2 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:304:9
  else:
    let Y_EVENT_CHANGE_DELETE* = 2 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:304:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_CHANGE_DELETE" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_CHANGE_RETAIN):
  when 3 is static:
    const
      Y_EVENT_CHANGE_RETAIN* = 3 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:310:9
  else:
    let Y_EVENT_CHANGE_RETAIN* = 3 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:310:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_CHANGE_RETAIN" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_KEY_CHANGE_ADD):
  when 4 is static:
    const
      Y_EVENT_KEY_CHANGE_ADD* = 4 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:316:9
  else:
    let Y_EVENT_KEY_CHANGE_ADD* = 4 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:316:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_KEY_CHANGE_ADD" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_KEY_CHANGE_DELETE):
  when 5 is static:
    const
      Y_EVENT_KEY_CHANGE_DELETE* = 5 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:322:9
  else:
    let Y_EVENT_KEY_CHANGE_DELETE* = 5 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:322:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_KEY_CHANGE_DELETE" &
        " already exists, not redeclaring")
when not declared(Y_EVENT_KEY_CHANGE_UPDATE):
  when 6 is static:
    const
      Y_EVENT_KEY_CHANGE_UPDATE* = 6 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:328:9
  else:
    let Y_EVENT_KEY_CHANGE_UPDATE* = 6 ## Generated based on /Volumes/Data/scott/src/github.com/dsrw/model_citizen/omnara-claude-20250821031723/lib/libyrs.h:328:9
else:
  static :
    hint("Declaration of " & "Y_EVENT_KEY_CHANGE_UPDATE" &
        " already exists, not redeclaring")
when not declared(yoptions):
  proc yoptions*(): StructYOptions_1191182989 {.cdecl, importc: "yoptions".}
else:
  static :
    hint("Declaration of " & "yoptions" & " already exists, not redeclaring")
when not declared(ydoc_destroy):
  proc ydoc_destroy*(value: ptr YDoc_typedef_1191182957): void {.cdecl,
      importc: "ydoc_destroy".}
else:
  static :
    hint("Declaration of " & "ydoc_destroy" & " already exists, not redeclaring")
when not declared(ymap_entry_destroy):
  proc ymap_entry_destroy*(value: ptr StructYMapEntry_1191182997): void {.cdecl,
      importc: "ymap_entry_destroy".}
else:
  static :
    hint("Declaration of " & "ymap_entry_destroy" &
        " already exists, not redeclaring")
when not declared(yxmlattr_destroy):
  proc yxmlattr_destroy*(attr: ptr StructYXmlAttr_1191183005): void {.cdecl,
      importc: "yxmlattr_destroy".}
else:
  static :
    hint("Declaration of " & "yxmlattr_destroy" &
        " already exists, not redeclaring")
when not declared(ystring_destroy):
  proc ystring_destroy*(str: cstring): void {.cdecl, importc: "ystring_destroy".}
else:
  static :
    hint("Declaration of " & "ystring_destroy" &
        " already exists, not redeclaring")
when not declared(ybinary_destroy):
  proc ybinary_destroy*(ptr_arg: cstring; len: uint32): void {.cdecl,
      importc: "ybinary_destroy".}
else:
  static :
    hint("Declaration of " & "ybinary_destroy" &
        " already exists, not redeclaring")
when not declared(ydoc_new):
  proc ydoc_new*(): ptr YDoc_typedef_1191182957 {.cdecl, importc: "ydoc_new".}
else:
  static :
    hint("Declaration of " & "ydoc_new" & " already exists, not redeclaring")
when not declared(ydoc_clone):
  proc ydoc_clone*(doc: ptr YDoc_typedef_1191182957): ptr YDoc_typedef_1191182957 {.
      cdecl, importc: "ydoc_clone".}
else:
  static :
    hint("Declaration of " & "ydoc_clone" & " already exists, not redeclaring")
when not declared(ydoc_new_with_options):
  proc ydoc_new_with_options*(options: StructYOptions_1191182989): ptr YDoc_typedef_1191182957 {.
      cdecl, importc: "ydoc_new_with_options".}
else:
  static :
    hint("Declaration of " & "ydoc_new_with_options" &
        " already exists, not redeclaring")
when not declared(ydoc_id):
  proc ydoc_id*(doc: ptr YDoc_typedef_1191182957): uint64 {.cdecl,
      importc: "ydoc_id".}
else:
  static :
    hint("Declaration of " & "ydoc_id" & " already exists, not redeclaring")
when not declared(ydoc_guid):
  proc ydoc_guid*(doc: ptr YDoc_typedef_1191182957): cstring {.cdecl,
      importc: "ydoc_guid".}
else:
  static :
    hint("Declaration of " & "ydoc_guid" & " already exists, not redeclaring")
when not declared(ydoc_collection_id):
  proc ydoc_collection_id*(doc: ptr YDoc_typedef_1191182957): cstring {.cdecl,
      importc: "ydoc_collection_id".}
else:
  static :
    hint("Declaration of " & "ydoc_collection_id" &
        " already exists, not redeclaring")
when not declared(ydoc_should_load):
  proc ydoc_should_load*(doc: ptr YDoc_typedef_1191182957): uint8 {.cdecl,
      importc: "ydoc_should_load".}
else:
  static :
    hint("Declaration of " & "ydoc_should_load" &
        " already exists, not redeclaring")
when not declared(ydoc_auto_load):
  proc ydoc_auto_load*(doc: ptr YDoc_typedef_1191182957): uint8 {.cdecl,
      importc: "ydoc_auto_load".}
else:
  static :
    hint("Declaration of " & "ydoc_auto_load" &
        " already exists, not redeclaring")
when not declared(ydoc_observe_updates_v1):
  proc ydoc_observe_updates_v1*(doc: ptr YDoc_typedef_1191182957;
                                state: pointer; cb: proc (a0: pointer;
      a1: uint32; a2: cstring): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ydoc_observe_updates_v1".}
else:
  static :
    hint("Declaration of " & "ydoc_observe_updates_v1" &
        " already exists, not redeclaring")
when not declared(ydoc_observe_updates_v2):
  proc ydoc_observe_updates_v2*(doc: ptr YDoc_typedef_1191182957;
                                state: pointer; cb: proc (a0: pointer;
      a1: uint32; a2: cstring): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ydoc_observe_updates_v2".}
else:
  static :
    hint("Declaration of " & "ydoc_observe_updates_v2" &
        " already exists, not redeclaring")
when not declared(ydoc_observe_after_transaction):
  proc ydoc_observe_after_transaction*(doc: ptr YDoc_typedef_1191182957;
                                       state: pointer; cb: proc (a0: pointer;
      a1: ptr StructYAfterTransactionEvent_1191183032): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ydoc_observe_after_transaction".}
else:
  static :
    hint("Declaration of " & "ydoc_observe_after_transaction" &
        " already exists, not redeclaring")
when not declared(ydoc_observe_subdocs):
  proc ydoc_observe_subdocs*(doc: ptr YDoc_typedef_1191182957; state: pointer;
      cb: proc (a0: pointer; a1: ptr StructYSubdocsEvent_1191183036): void {.
      cdecl.}): ptr YSubscription_1191182985 {.cdecl,
      importc: "ydoc_observe_subdocs".}
else:
  static :
    hint("Declaration of " & "ydoc_observe_subdocs" &
        " already exists, not redeclaring")
when not declared(ydoc_observe_clear):
  proc ydoc_observe_clear*(doc: ptr YDoc_typedef_1191182957; state: pointer; cb: proc (
      a0: pointer; a1: ptr YDoc_typedef_1191182957): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ydoc_observe_clear".}
else:
  static :
    hint("Declaration of " & "ydoc_observe_clear" &
        " already exists, not redeclaring")
when not declared(ydoc_load):
  proc ydoc_load*(doc: ptr YDoc_typedef_1191182957; parent_txn: ptr YTransaction_1191183040): void {.
      cdecl, importc: "ydoc_load".}
else:
  static :
    hint("Declaration of " & "ydoc_load" & " already exists, not redeclaring")
when not declared(ydoc_clear):
  proc ydoc_clear*(doc: ptr YDoc_typedef_1191182957;
                   parent_txn: ptr YTransaction_1191183040): void {.cdecl,
      importc: "ydoc_clear".}
else:
  static :
    hint("Declaration of " & "ydoc_clear" & " already exists, not redeclaring")
when not declared(ydoc_read_transaction):
  proc ydoc_read_transaction*(doc: ptr YDoc_typedef_1191182957): ptr YTransaction_1191183040 {.
      cdecl, importc: "ydoc_read_transaction".}
else:
  static :
    hint("Declaration of " & "ydoc_read_transaction" &
        " already exists, not redeclaring")
when not declared(ydoc_write_transaction):
  proc ydoc_write_transaction*(doc: ptr YDoc_typedef_1191182957;
                               origin_len: uint32; origin: cstring): ptr YTransaction_1191183040 {.
      cdecl, importc: "ydoc_write_transaction".}
else:
  static :
    hint("Declaration of " & "ydoc_write_transaction" &
        " already exists, not redeclaring")
when not declared(ytransaction_subdocs):
  proc ytransaction_subdocs*(txn: ptr YTransaction_1191183040; len: ptr uint32): ptr ptr YDoc_typedef_1191182957 {.
      cdecl, importc: "ytransaction_subdocs".}
else:
  static :
    hint("Declaration of " & "ytransaction_subdocs" &
        " already exists, not redeclaring")
when not declared(ytransaction_commit):
  proc ytransaction_commit*(txn: ptr YTransaction_1191183040): void {.cdecl,
      importc: "ytransaction_commit".}
else:
  static :
    hint("Declaration of " & "ytransaction_commit" &
        " already exists, not redeclaring")
when not declared(ytransaction_force_gc):
  proc ytransaction_force_gc*(txn: ptr YTransaction_1191183040): void {.cdecl,
      importc: "ytransaction_force_gc".}
else:
  static :
    hint("Declaration of " & "ytransaction_force_gc" &
        " already exists, not redeclaring")
when not declared(ytransaction_writeable):
  proc ytransaction_writeable*(txn: ptr YTransaction_1191183040): uint8 {.cdecl,
      importc: "ytransaction_writeable".}
else:
  static :
    hint("Declaration of " & "ytransaction_writeable" &
        " already exists, not redeclaring")
when not declared(ytransaction_json_path):
  proc ytransaction_json_path*(txn: ptr YTransaction_1191183040;
                               json_path: cstring): ptr YJsonPathIter_1191182971 {.
      cdecl, importc: "ytransaction_json_path".}
else:
  static :
    hint("Declaration of " & "ytransaction_json_path" &
        " already exists, not redeclaring")
when not declared(yjson_path_iter_next):
  proc yjson_path_iter_next*(iter: ptr YJsonPathIter_1191182971): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yjson_path_iter_next".}
else:
  static :
    hint("Declaration of " & "yjson_path_iter_next" &
        " already exists, not redeclaring")
when not declared(yjson_path_iter_destroy):
  proc yjson_path_iter_destroy*(iter: ptr YJsonPathIter_1191182971): void {.
      cdecl, importc: "yjson_path_iter_destroy".}
else:
  static :
    hint("Declaration of " & "yjson_path_iter_destroy" &
        " already exists, not redeclaring")
when not declared(ytype_get):
  proc ytype_get*(txn: ptr YTransaction_1191183040; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "ytype_get".}
else:
  static :
    hint("Declaration of " & "ytype_get" & " already exists, not redeclaring")
when not declared(ytext):
  proc ytext*(doc: ptr YDoc_typedef_1191182957; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "ytext".}
else:
  static :
    hint("Declaration of " & "ytext" & " already exists, not redeclaring")
when not declared(yarray):
  proc yarray*(doc: ptr YDoc_typedef_1191182957; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "yarray".}
else:
  static :
    hint("Declaration of " & "yarray" & " already exists, not redeclaring")
when not declared(ymap):
  proc ymap*(doc: ptr YDoc_typedef_1191182957; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "ymap".}
else:
  static :
    hint("Declaration of " & "ymap" & " already exists, not redeclaring")
when not declared(yxmlfragment):
  proc yxmlfragment*(doc: ptr YDoc_typedef_1191182957; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "yxmlfragment".}
else:
  static :
    hint("Declaration of " & "yxmlfragment" & " already exists, not redeclaring")
when not declared(ytransaction_state_vector_v1):
  proc ytransaction_state_vector_v1*(txn: ptr YTransaction_1191183040;
                                     len: ptr uint32): cstring {.cdecl,
      importc: "ytransaction_state_vector_v1".}
else:
  static :
    hint("Declaration of " & "ytransaction_state_vector_v1" &
        " already exists, not redeclaring")
when not declared(ytransaction_state_diff_v1):
  proc ytransaction_state_diff_v1*(txn: ptr YTransaction_1191183040;
                                   sv: cstring; sv_len: uint32; len: ptr uint32): cstring {.
      cdecl, importc: "ytransaction_state_diff_v1".}
else:
  static :
    hint("Declaration of " & "ytransaction_state_diff_v1" &
        " already exists, not redeclaring")
when not declared(ytransaction_state_diff_v2):
  proc ytransaction_state_diff_v2*(txn: ptr YTransaction_1191183040;
                                   sv: cstring; sv_len: uint32; len: ptr uint32): cstring {.
      cdecl, importc: "ytransaction_state_diff_v2".}
else:
  static :
    hint("Declaration of " & "ytransaction_state_diff_v2" &
        " already exists, not redeclaring")
when not declared(ytransaction_snapshot):
  proc ytransaction_snapshot*(txn: ptr YTransaction_1191183040; len: ptr uint32): cstring {.
      cdecl, importc: "ytransaction_snapshot".}
else:
  static :
    hint("Declaration of " & "ytransaction_snapshot" &
        " already exists, not redeclaring")
when not declared(ytransaction_encode_state_from_snapshot_v1):
  proc ytransaction_encode_state_from_snapshot_v1*(txn: ptr YTransaction_1191183040;
      snapshot: cstring; snapshot_len: uint32; len: ptr uint32): cstring {.
      cdecl, importc: "ytransaction_encode_state_from_snapshot_v1".}
else:
  static :
    hint("Declaration of " & "ytransaction_encode_state_from_snapshot_v1" &
        " already exists, not redeclaring")
when not declared(ytransaction_encode_state_from_snapshot_v2):
  proc ytransaction_encode_state_from_snapshot_v2*(txn: ptr YTransaction_1191183040;
      snapshot: cstring; snapshot_len: uint32; len: ptr uint32): cstring {.
      cdecl, importc: "ytransaction_encode_state_from_snapshot_v2".}
else:
  static :
    hint("Declaration of " & "ytransaction_encode_state_from_snapshot_v2" &
        " already exists, not redeclaring")
when not declared(ytransaction_pending_ds):
  proc ytransaction_pending_ds*(txn: ptr YTransaction_1191183040): ptr StructYDeleteSet_1191183028 {.
      cdecl, importc: "ytransaction_pending_ds".}
else:
  static :
    hint("Declaration of " & "ytransaction_pending_ds" &
        " already exists, not redeclaring")
when not declared(ydelete_set_destroy):
  proc ydelete_set_destroy*(ds: ptr StructYDeleteSet_1191183028): void {.cdecl,
      importc: "ydelete_set_destroy".}
else:
  static :
    hint("Declaration of " & "ydelete_set_destroy" &
        " already exists, not redeclaring")
when not declared(ytransaction_pending_update):
  proc ytransaction_pending_update*(txn: ptr YTransaction_1191183040): ptr StructYPendingUpdate_1191183042 {.
      cdecl, importc: "ytransaction_pending_update".}
else:
  static :
    hint("Declaration of " & "ytransaction_pending_update" &
        " already exists, not redeclaring")
when not declared(ypending_update_destroy):
  proc ypending_update_destroy*(update: ptr StructYPendingUpdate_1191183042): void {.
      cdecl, importc: "ypending_update_destroy".}
else:
  static :
    hint("Declaration of " & "ypending_update_destroy" &
        " already exists, not redeclaring")
when not declared(yupdate_debug_v1):
  proc yupdate_debug_v1*(update: cstring; update_len: uint32): cstring {.cdecl,
      importc: "yupdate_debug_v1".}
else:
  static :
    hint("Declaration of " & "yupdate_debug_v1" &
        " already exists, not redeclaring")
when not declared(yupdate_debug_v2):
  proc yupdate_debug_v2*(update: cstring; update_len: uint32): cstring {.cdecl,
      importc: "yupdate_debug_v2".}
else:
  static :
    hint("Declaration of " & "yupdate_debug_v2" &
        " already exists, not redeclaring")
when not declared(ytransaction_apply):
  proc ytransaction_apply*(txn: ptr YTransaction_1191183040; diff: cstring;
                           diff_len: uint32): uint8 {.cdecl,
      importc: "ytransaction_apply".}
else:
  static :
    hint("Declaration of " & "ytransaction_apply" &
        " already exists, not redeclaring")
when not declared(ytransaction_apply_v2):
  proc ytransaction_apply_v2*(txn: ptr YTransaction_1191183040; diff: cstring;
                              diff_len: uint32): uint8 {.cdecl,
      importc: "ytransaction_apply_v2".}
else:
  static :
    hint("Declaration of " & "ytransaction_apply_v2" &
        " already exists, not redeclaring")
when not declared(ytext_len):
  proc ytext_len*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): uint32 {.
      cdecl, importc: "ytext_len".}
else:
  static :
    hint("Declaration of " & "ytext_len" & " already exists, not redeclaring")
when not declared(ytext_string):
  proc ytext_string*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): cstring {.
      cdecl, importc: "ytext_string".}
else:
  static :
    hint("Declaration of " & "ytext_string" & " already exists, not redeclaring")
when not declared(ytext_insert):
  proc ytext_insert*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                     index: uint32; value: cstring; attrs: ptr StructYInput_1191183048): void {.
      cdecl, importc: "ytext_insert".}
else:
  static :
    hint("Declaration of " & "ytext_insert" & " already exists, not redeclaring")
when not declared(ytext_format):
  proc ytext_format*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                     index: uint32; len: uint32; attrs: ptr StructYInput_1191183048): void {.
      cdecl, importc: "ytext_format".}
else:
  static :
    hint("Declaration of " & "ytext_format" & " already exists, not redeclaring")
when not declared(ytext_insert_embed):
  proc ytext_insert_embed*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                           index: uint32; content: ptr StructYInput_1191183048;
                           attrs: ptr StructYInput_1191183048): void {.cdecl,
      importc: "ytext_insert_embed".}
else:
  static :
    hint("Declaration of " & "ytext_insert_embed" &
        " already exists, not redeclaring")
when not declared(ytext_insert_delta):
  proc ytext_insert_delta*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                           delta: ptr StructYDeltaIn_1191183060;
                           delta_len: uint32): void {.cdecl,
      importc: "ytext_insert_delta".}
else:
  static :
    hint("Declaration of " & "ytext_insert_delta" &
        " already exists, not redeclaring")
when not declared(ydelta_input_retain):
  proc ydelta_input_retain*(len: uint32; attrs: ptr StructYInput_1191183048): StructYDeltaIn_1191183060 {.
      cdecl, importc: "ydelta_input_retain".}
else:
  static :
    hint("Declaration of " & "ydelta_input_retain" &
        " already exists, not redeclaring")
when not declared(ydelta_input_delete):
  proc ydelta_input_delete*(len: uint32): StructYDeltaIn_1191183060 {.cdecl,
      importc: "ydelta_input_delete".}
else:
  static :
    hint("Declaration of " & "ydelta_input_delete" &
        " already exists, not redeclaring")
when not declared(ydelta_input_insert):
  proc ydelta_input_insert*(data: ptr StructYInput_1191183048;
                            attrs: ptr StructYInput_1191183048): StructYDeltaIn_1191183060 {.
      cdecl, importc: "ydelta_input_insert".}
else:
  static :
    hint("Declaration of " & "ydelta_input_insert" &
        " already exists, not redeclaring")
when not declared(ytext_remove_range):
  proc ytext_remove_range*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                           index: uint32; length: uint32): void {.cdecl,
      importc: "ytext_remove_range".}
else:
  static :
    hint("Declaration of " & "ytext_remove_range" &
        " already exists, not redeclaring")
when not declared(yarray_len):
  proc yarray_len*(array: ptr Branch_1191182959): uint32 {.cdecl,
      importc: "yarray_len".}
else:
  static :
    hint("Declaration of " & "yarray_len" & " already exists, not redeclaring")
when not declared(yarray_get):
  proc yarray_get*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                   index: uint32): ptr StructYOutput_1191182995 {.cdecl,
      importc: "yarray_get".}
else:
  static :
    hint("Declaration of " & "yarray_get" & " already exists, not redeclaring")
when not declared(yarray_get_json):
  proc yarray_get_json*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                        index: uint32): cstring {.cdecl,
      importc: "yarray_get_json".}
else:
  static :
    hint("Declaration of " & "yarray_get_json" &
        " already exists, not redeclaring")
when not declared(yarray_insert_range):
  proc yarray_insert_range*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                            index: uint32; items: ptr StructYInput_1191183048;
                            items_len: uint32): void {.cdecl,
      importc: "yarray_insert_range".}
else:
  static :
    hint("Declaration of " & "yarray_insert_range" &
        " already exists, not redeclaring")
when not declared(yarray_remove_range):
  proc yarray_remove_range*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                            index: uint32; len: uint32): void {.cdecl,
      importc: "yarray_remove_range".}
else:
  static :
    hint("Declaration of " & "yarray_remove_range" &
        " already exists, not redeclaring")
when not declared(yarray_move):
  proc yarray_move*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                    source: uint32; target: uint32): void {.cdecl,
      importc: "yarray_move".}
else:
  static :
    hint("Declaration of " & "yarray_move" & " already exists, not redeclaring")
when not declared(yarray_iter):
  proc yarray_iter*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YArrayIter_1191182967 {.
      cdecl, importc: "yarray_iter".}
else:
  static :
    hint("Declaration of " & "yarray_iter" & " already exists, not redeclaring")
when not declared(yarray_iter_destroy):
  proc yarray_iter_destroy*(iter: ptr YArrayIter_1191182967): void {.cdecl,
      importc: "yarray_iter_destroy".}
else:
  static :
    hint("Declaration of " & "yarray_iter_destroy" &
        " already exists, not redeclaring")
when not declared(yarray_iter_next):
  proc yarray_iter_next*(iterator_arg: ptr YArrayIter_1191182967): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yarray_iter_next".}
else:
  static :
    hint("Declaration of " & "yarray_iter_next" &
        " already exists, not redeclaring")
when not declared(ymap_iter):
  proc ymap_iter*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YMapIter_1191182969 {.
      cdecl, importc: "ymap_iter".}
else:
  static :
    hint("Declaration of " & "ymap_iter" & " already exists, not redeclaring")
when not declared(ymap_iter_destroy):
  proc ymap_iter_destroy*(iter: ptr YMapIter_1191182969): void {.cdecl,
      importc: "ymap_iter_destroy".}
else:
  static :
    hint("Declaration of " & "ymap_iter_destroy" &
        " already exists, not redeclaring")
when not declared(ymap_iter_next):
  proc ymap_iter_next*(iter: ptr YMapIter_1191182969): ptr StructYMapEntry_1191182997 {.
      cdecl, importc: "ymap_iter_next".}
else:
  static :
    hint("Declaration of " & "ymap_iter_next" &
        " already exists, not redeclaring")
when not declared(ymap_len):
  proc ymap_len*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): uint32 {.
      cdecl, importc: "ymap_len".}
else:
  static :
    hint("Declaration of " & "ymap_len" & " already exists, not redeclaring")
when not declared(ymap_insert):
  proc ymap_insert*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                    key: cstring; value: ptr StructYInput_1191183048): void {.
      cdecl, importc: "ymap_insert".}
else:
  static :
    hint("Declaration of " & "ymap_insert" & " already exists, not redeclaring")
when not declared(ymap_remove):
  proc ymap_remove*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                    key: cstring): uint8 {.cdecl, importc: "ymap_remove".}
else:
  static :
    hint("Declaration of " & "ymap_remove" & " already exists, not redeclaring")
when not declared(ymap_get):
  proc ymap_get*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                 key: cstring): ptr StructYOutput_1191182995 {.cdecl,
      importc: "ymap_get".}
else:
  static :
    hint("Declaration of " & "ymap_get" & " already exists, not redeclaring")
when not declared(ymap_get_json):
  proc ymap_get_json*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                      key: cstring): cstring {.cdecl, importc: "ymap_get_json".}
else:
  static :
    hint("Declaration of " & "ymap_get_json" &
        " already exists, not redeclaring")
when not declared(ymap_remove_all):
  proc ymap_remove_all*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): void {.
      cdecl, importc: "ymap_remove_all".}
else:
  static :
    hint("Declaration of " & "ymap_remove_all" &
        " already exists, not redeclaring")
when not declared(yxmlelem_tag):
  proc yxmlelem_tag*(xml: ptr Branch_1191182959): cstring {.cdecl,
      importc: "yxmlelem_tag".}
else:
  static :
    hint("Declaration of " & "yxmlelem_tag" & " already exists, not redeclaring")
when not declared(yxmlelem_string):
  proc yxmlelem_string*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): cstring {.
      cdecl, importc: "yxmlelem_string".}
else:
  static :
    hint("Declaration of " & "yxmlelem_string" &
        " already exists, not redeclaring")
when not declared(yxmlelem_insert_attr):
  proc yxmlelem_insert_attr*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             attr_name: cstring; attr_value: ptr StructYInput_1191183048): void {.
      cdecl, importc: "yxmlelem_insert_attr".}
else:
  static :
    hint("Declaration of " & "yxmlelem_insert_attr" &
        " already exists, not redeclaring")
when not declared(yxmlelem_remove_attr):
  proc yxmlelem_remove_attr*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             attr_name: cstring): void {.cdecl,
      importc: "yxmlelem_remove_attr".}
else:
  static :
    hint("Declaration of " & "yxmlelem_remove_attr" &
        " already exists, not redeclaring")
when not declared(yxmlelem_get_attr):
  proc yxmlelem_get_attr*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                          attr_name: cstring): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxmlelem_get_attr".}
else:
  static :
    hint("Declaration of " & "yxmlelem_get_attr" &
        " already exists, not redeclaring")
when not declared(yxmlelem_attr_iter):
  proc yxmlelem_attr_iter*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YXmlAttrIter_1191182973 {.
      cdecl, importc: "yxmlelem_attr_iter".}
else:
  static :
    hint("Declaration of " & "yxmlelem_attr_iter" &
        " already exists, not redeclaring")
when not declared(yxmltext_attr_iter):
  proc yxmltext_attr_iter*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YXmlAttrIter_1191182973 {.
      cdecl, importc: "yxmltext_attr_iter".}
else:
  static :
    hint("Declaration of " & "yxmltext_attr_iter" &
        " already exists, not redeclaring")
when not declared(yxmlattr_iter_destroy):
  proc yxmlattr_iter_destroy*(iterator_arg: ptr YXmlAttrIter_1191182973): void {.
      cdecl, importc: "yxmlattr_iter_destroy".}
else:
  static :
    hint("Declaration of " & "yxmlattr_iter_destroy" &
        " already exists, not redeclaring")
when not declared(yxmlattr_iter_next):
  proc yxmlattr_iter_next*(iterator_arg: ptr YXmlAttrIter_1191182973): ptr StructYXmlAttr_1191183005 {.
      cdecl, importc: "yxmlattr_iter_next".}
else:
  static :
    hint("Declaration of " & "yxmlattr_iter_next" &
        " already exists, not redeclaring")
when not declared(yxml_next_sibling):
  proc yxml_next_sibling*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxml_next_sibling".}
else:
  static :
    hint("Declaration of " & "yxml_next_sibling" &
        " already exists, not redeclaring")
when not declared(yxml_prev_sibling):
  proc yxml_prev_sibling*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxml_prev_sibling".}
else:
  static :
    hint("Declaration of " & "yxml_prev_sibling" &
        " already exists, not redeclaring")
when not declared(yxmlelem_parent):
  proc yxmlelem_parent*(xml: ptr Branch_1191182959): ptr Branch_1191182959 {.
      cdecl, importc: "yxmlelem_parent".}
else:
  static :
    hint("Declaration of " & "yxmlelem_parent" &
        " already exists, not redeclaring")
when not declared(yxmlelem_child_len):
  proc yxmlelem_child_len*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): uint32 {.
      cdecl, importc: "yxmlelem_child_len".}
else:
  static :
    hint("Declaration of " & "yxmlelem_child_len" &
        " already exists, not redeclaring")
when not declared(yxmlelem_first_child):
  proc yxmlelem_first_child*(xml: ptr Branch_1191182959): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxmlelem_first_child".}
else:
  static :
    hint("Declaration of " & "yxmlelem_first_child" &
        " already exists, not redeclaring")
when not declared(yxmlelem_tree_walker):
  proc yxmlelem_tree_walker*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YXmlTreeWalker_1191182975 {.
      cdecl, importc: "yxmlelem_tree_walker".}
else:
  static :
    hint("Declaration of " & "yxmlelem_tree_walker" &
        " already exists, not redeclaring")
when not declared(yxmlelem_tree_walker_destroy):
  proc yxmlelem_tree_walker_destroy*(iter: ptr YXmlTreeWalker_1191182975): void {.
      cdecl, importc: "yxmlelem_tree_walker_destroy".}
else:
  static :
    hint("Declaration of " & "yxmlelem_tree_walker_destroy" &
        " already exists, not redeclaring")
when not declared(yxmlelem_tree_walker_next):
  proc yxmlelem_tree_walker_next*(iterator_arg: ptr YXmlTreeWalker_1191182975): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxmlelem_tree_walker_next".}
else:
  static :
    hint("Declaration of " & "yxmlelem_tree_walker_next" &
        " already exists, not redeclaring")
when not declared(yxmlelem_insert_elem):
  proc yxmlelem_insert_elem*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             index: uint32; name: cstring): ptr Branch_1191182959 {.
      cdecl, importc: "yxmlelem_insert_elem".}
else:
  static :
    hint("Declaration of " & "yxmlelem_insert_elem" &
        " already exists, not redeclaring")
when not declared(yxmlelem_insert_text):
  proc yxmlelem_insert_text*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             index: uint32): ptr Branch_1191182959 {.cdecl,
      importc: "yxmlelem_insert_text".}
else:
  static :
    hint("Declaration of " & "yxmlelem_insert_text" &
        " already exists, not redeclaring")
when not declared(yxmlelem_remove_range):
  proc yxmlelem_remove_range*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                              index: uint32; len: uint32): void {.cdecl,
      importc: "yxmlelem_remove_range".}
else:
  static :
    hint("Declaration of " & "yxmlelem_remove_range" &
        " already exists, not redeclaring")
when not declared(yxmlelem_get):
  proc yxmlelem_get*(xml: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                     index: uint32): ptr StructYOutput_1191182995 {.cdecl,
      importc: "yxmlelem_get".}
else:
  static :
    hint("Declaration of " & "yxmlelem_get" & " already exists, not redeclaring")
when not declared(yxmltext_len):
  proc yxmltext_len*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): uint32 {.
      cdecl, importc: "yxmltext_len".}
else:
  static :
    hint("Declaration of " & "yxmltext_len" & " already exists, not redeclaring")
when not declared(yxmltext_string):
  proc yxmltext_string*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): cstring {.
      cdecl, importc: "yxmltext_string".}
else:
  static :
    hint("Declaration of " & "yxmltext_string" &
        " already exists, not redeclaring")
when not declared(yxmltext_insert):
  proc yxmltext_insert*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                        index: uint32; str: cstring; attrs: ptr StructYInput_1191183048): void {.
      cdecl, importc: "yxmltext_insert".}
else:
  static :
    hint("Declaration of " & "yxmltext_insert" &
        " already exists, not redeclaring")
when not declared(yxmltext_insert_embed):
  proc yxmltext_insert_embed*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                              index: uint32; content: ptr StructYInput_1191183048;
                              attrs: ptr StructYInput_1191183048): void {.cdecl,
      importc: "yxmltext_insert_embed".}
else:
  static :
    hint("Declaration of " & "yxmltext_insert_embed" &
        " already exists, not redeclaring")
when not declared(yxmltext_format):
  proc yxmltext_format*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                        index: uint32; len: uint32; attrs: ptr StructYInput_1191183048): void {.
      cdecl, importc: "yxmltext_format".}
else:
  static :
    hint("Declaration of " & "yxmltext_format" &
        " already exists, not redeclaring")
when not declared(yxmltext_remove_range):
  proc yxmltext_remove_range*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                              idx: uint32; len: uint32): void {.cdecl,
      importc: "yxmltext_remove_range".}
else:
  static :
    hint("Declaration of " & "yxmltext_remove_range" &
        " already exists, not redeclaring")
when not declared(yxmltext_insert_attr):
  proc yxmltext_insert_attr*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             attr_name: cstring; attr_value: ptr StructYInput_1191183048): void {.
      cdecl, importc: "yxmltext_insert_attr".}
else:
  static :
    hint("Declaration of " & "yxmltext_insert_attr" &
        " already exists, not redeclaring")
when not declared(yxmltext_remove_attr):
  proc yxmltext_remove_attr*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                             attr_name: cstring): void {.cdecl,
      importc: "yxmltext_remove_attr".}
else:
  static :
    hint("Declaration of " & "yxmltext_remove_attr" &
        " already exists, not redeclaring")
when not declared(yxmltext_get_attr):
  proc yxmltext_get_attr*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                          attr_name: cstring): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yxmltext_get_attr".}
else:
  static :
    hint("Declaration of " & "yxmltext_get_attr" &
        " already exists, not redeclaring")
when not declared(ytext_chunks):
  proc ytext_chunks*(txt: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                     chunks_len: ptr uint32): ptr StructYChunk_1191183064 {.
      cdecl, importc: "ytext_chunks".}
else:
  static :
    hint("Declaration of " & "ytext_chunks" & " already exists, not redeclaring")
when not declared(ychunks_destroy):
  proc ychunks_destroy*(chunks: ptr StructYChunk_1191183064; len: uint32): void {.
      cdecl, importc: "ychunks_destroy".}
else:
  static :
    hint("Declaration of " & "ychunks_destroy" &
        " already exists, not redeclaring")
when not declared(youtput_destroy):
  proc youtput_destroy*(val: ptr StructYOutput_1191182995): void {.cdecl,
      importc: "youtput_destroy".}
else:
  static :
    hint("Declaration of " & "youtput_destroy" &
        " already exists, not redeclaring")
when not declared(yinput_null):
  proc yinput_null*(): StructYInput_1191183048 {.cdecl, importc: "yinput_null".}
else:
  static :
    hint("Declaration of " & "yinput_null" & " already exists, not redeclaring")
when not declared(yinput_undefined):
  proc yinput_undefined*(): StructYInput_1191183048 {.cdecl,
      importc: "yinput_undefined".}
else:
  static :
    hint("Declaration of " & "yinput_undefined" &
        " already exists, not redeclaring")
when not declared(yinput_bool):
  proc yinput_bool*(flag: uint8): StructYInput_1191183048 {.cdecl,
      importc: "yinput_bool".}
else:
  static :
    hint("Declaration of " & "yinput_bool" & " already exists, not redeclaring")
when not declared(yinput_float):
  proc yinput_float*(num: cdouble): StructYInput_1191183048 {.cdecl,
      importc: "yinput_float".}
else:
  static :
    hint("Declaration of " & "yinput_float" & " already exists, not redeclaring")
when not declared(yinput_long):
  proc yinput_long*(integer: int64): StructYInput_1191183048 {.cdecl,
      importc: "yinput_long".}
else:
  static :
    hint("Declaration of " & "yinput_long" & " already exists, not redeclaring")
when not declared(yinput_string):
  proc yinput_string*(str: cstring): StructYInput_1191183048 {.cdecl,
      importc: "yinput_string".}
else:
  static :
    hint("Declaration of " & "yinput_string" &
        " already exists, not redeclaring")
when not declared(yinput_json):
  proc yinput_json*(str: cstring): StructYInput_1191183048 {.cdecl,
      importc: "yinput_json".}
else:
  static :
    hint("Declaration of " & "yinput_json" & " already exists, not redeclaring")
when not declared(yinput_binary):
  proc yinput_binary*(buf: cstring; len: uint32): StructYInput_1191183048 {.
      cdecl, importc: "yinput_binary".}
else:
  static :
    hint("Declaration of " & "yinput_binary" &
        " already exists, not redeclaring")
when not declared(yinput_json_array):
  proc yinput_json_array*(values: ptr StructYInput_1191183048; len: uint32): StructYInput_1191183048 {.
      cdecl, importc: "yinput_json_array".}
else:
  static :
    hint("Declaration of " & "yinput_json_array" &
        " already exists, not redeclaring")
when not declared(yinput_json_map):
  proc yinput_json_map*(keys: ptr cstring; values: ptr StructYInput_1191183048;
                        len: uint32): StructYInput_1191183048 {.cdecl,
      importc: "yinput_json_map".}
else:
  static :
    hint("Declaration of " & "yinput_json_map" &
        " already exists, not redeclaring")
when not declared(yinput_yarray):
  proc yinput_yarray*(values: ptr StructYInput_1191183048; len: uint32): StructYInput_1191183048 {.
      cdecl, importc: "yinput_yarray".}
else:
  static :
    hint("Declaration of " & "yinput_yarray" &
        " already exists, not redeclaring")
when not declared(yinput_ymap):
  proc yinput_ymap*(keys: ptr cstring; values: ptr StructYInput_1191183048;
                    len: uint32): StructYInput_1191183048 {.cdecl,
      importc: "yinput_ymap".}
else:
  static :
    hint("Declaration of " & "yinput_ymap" & " already exists, not redeclaring")
when not declared(yinput_ytext):
  proc yinput_ytext*(str: cstring): StructYInput_1191183048 {.cdecl,
      importc: "yinput_ytext".}
else:
  static :
    hint("Declaration of " & "yinput_ytext" & " already exists, not redeclaring")
when not declared(yinput_yxmlelem):
  proc yinput_yxmlelem*(name: cstring): StructYInput_1191183048 {.cdecl,
      importc: "yinput_yxmlelem".}
else:
  static :
    hint("Declaration of " & "yinput_yxmlelem" &
        " already exists, not redeclaring")
when not declared(yinput_yxmltext):
  proc yinput_yxmltext*(str: cstring): StructYInput_1191183048 {.cdecl,
      importc: "yinput_yxmltext".}
else:
  static :
    hint("Declaration of " & "yinput_yxmltext" &
        " already exists, not redeclaring")
when not declared(yinput_ydoc):
  proc yinput_ydoc*(doc: ptr YDoc_typedef_1191182957): StructYInput_1191183048 {.
      cdecl, importc: "yinput_ydoc".}
else:
  static :
    hint("Declaration of " & "yinput_ydoc" & " already exists, not redeclaring")
when not declared(yinput_weak):
  proc yinput_weak*(weak: ptr Weak_1191183052): StructYInput_1191183048 {.cdecl,
      importc: "yinput_weak".}
else:
  static :
    hint("Declaration of " & "yinput_weak" & " already exists, not redeclaring")
when not declared(youtput_read_ydoc):
  proc youtput_read_ydoc*(val: ptr StructYOutput_1191182995): ptr YDoc_typedef_1191182957 {.
      cdecl, importc: "youtput_read_ydoc".}
else:
  static :
    hint("Declaration of " & "youtput_read_ydoc" &
        " already exists, not redeclaring")
when not declared(youtput_read_bool):
  proc youtput_read_bool*(val: ptr StructYOutput_1191182995): ptr uint8 {.cdecl,
      importc: "youtput_read_bool".}
else:
  static :
    hint("Declaration of " & "youtput_read_bool" &
        " already exists, not redeclaring")
when not declared(youtput_read_float):
  proc youtput_read_float*(val: ptr StructYOutput_1191182995): ptr cdouble {.
      cdecl, importc: "youtput_read_float".}
else:
  static :
    hint("Declaration of " & "youtput_read_float" &
        " already exists, not redeclaring")
when not declared(youtput_read_long):
  proc youtput_read_long*(val: ptr StructYOutput_1191182995): ptr int64 {.cdecl,
      importc: "youtput_read_long".}
else:
  static :
    hint("Declaration of " & "youtput_read_long" &
        " already exists, not redeclaring")
when not declared(youtput_read_string):
  proc youtput_read_string*(val: ptr StructYOutput_1191182995): cstring {.cdecl,
      importc: "youtput_read_string".}
else:
  static :
    hint("Declaration of " & "youtput_read_string" &
        " already exists, not redeclaring")
when not declared(youtput_read_binary):
  proc youtput_read_binary*(val: ptr StructYOutput_1191182995): cstring {.cdecl,
      importc: "youtput_read_binary".}
else:
  static :
    hint("Declaration of " & "youtput_read_binary" &
        " already exists, not redeclaring")
when not declared(youtput_read_json_array):
  proc youtput_read_json_array*(val: ptr StructYOutput_1191182995): ptr StructYOutput_1191182995 {.
      cdecl, importc: "youtput_read_json_array".}
else:
  static :
    hint("Declaration of " & "youtput_read_json_array" &
        " already exists, not redeclaring")
when not declared(youtput_read_json_map):
  proc youtput_read_json_map*(val: ptr StructYOutput_1191182995): ptr StructYMapEntry_1191182997 {.
      cdecl, importc: "youtput_read_json_map".}
else:
  static :
    hint("Declaration of " & "youtput_read_json_map" &
        " already exists, not redeclaring")
when not declared(youtput_read_yarray):
  proc youtput_read_yarray*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_yarray".}
else:
  static :
    hint("Declaration of " & "youtput_read_yarray" &
        " already exists, not redeclaring")
when not declared(youtput_read_yxmlelem):
  proc youtput_read_yxmlelem*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_yxmlelem".}
else:
  static :
    hint("Declaration of " & "youtput_read_yxmlelem" &
        " already exists, not redeclaring")
when not declared(youtput_read_ymap):
  proc youtput_read_ymap*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_ymap".}
else:
  static :
    hint("Declaration of " & "youtput_read_ymap" &
        " already exists, not redeclaring")
when not declared(youtput_read_ytext):
  proc youtput_read_ytext*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_ytext".}
else:
  static :
    hint("Declaration of " & "youtput_read_ytext" &
        " already exists, not redeclaring")
when not declared(youtput_read_yxmltext):
  proc youtput_read_yxmltext*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_yxmltext".}
else:
  static :
    hint("Declaration of " & "youtput_read_yxmltext" &
        " already exists, not redeclaring")
when not declared(youtput_read_yweak):
  proc youtput_read_yweak*(val: ptr StructYOutput_1191182995): ptr Branch_1191182959 {.
      cdecl, importc: "youtput_read_yweak".}
else:
  static :
    hint("Declaration of " & "youtput_read_yweak" &
        " already exists, not redeclaring")
when not declared(yunobserve):
  proc yunobserve*(subscription: ptr YSubscription_1191182985): void {.cdecl,
      importc: "yunobserve".}
else:
  static :
    hint("Declaration of " & "yunobserve" & " already exists, not redeclaring")
when not declared(ytext_observe):
  proc ytext_observe*(txt: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYTextEvent_1191183068): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ytext_observe".}
else:
  static :
    hint("Declaration of " & "ytext_observe" &
        " already exists, not redeclaring")
when not declared(ymap_observe):
  proc ymap_observe*(map: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYMapEvent_1191183072): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "ymap_observe".}
else:
  static :
    hint("Declaration of " & "ymap_observe" & " already exists, not redeclaring")
when not declared(yarray_observe):
  proc yarray_observe*(array: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYArrayEvent_1191183076): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yarray_observe".}
else:
  static :
    hint("Declaration of " & "yarray_observe" &
        " already exists, not redeclaring")
when not declared(yxmlelem_observe):
  proc yxmlelem_observe*(xml: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYXmlEvent_1191183080): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yxmlelem_observe".}
else:
  static :
    hint("Declaration of " & "yxmlelem_observe" &
        " already exists, not redeclaring")
when not declared(yxmltext_observe):
  proc yxmltext_observe*(xml: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYXmlTextEvent_1191183084): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yxmltext_observe".}
else:
  static :
    hint("Declaration of " & "yxmltext_observe" &
        " already exists, not redeclaring")
when not declared(yobserve_deep):
  proc yobserve_deep*(ytype: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: uint32; a2: ptr StructYEvent_1191183096): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yobserve_deep".}
else:
  static :
    hint("Declaration of " & "yobserve_deep" &
        " already exists, not redeclaring")
when not declared(ytext_event_target):
  proc ytext_event_target*(e: ptr StructYTextEvent_1191183068): ptr Branch_1191182959 {.
      cdecl, importc: "ytext_event_target".}
else:
  static :
    hint("Declaration of " & "ytext_event_target" &
        " already exists, not redeclaring")
when not declared(yarray_event_target):
  proc yarray_event_target*(e: ptr StructYArrayEvent_1191183076): ptr Branch_1191182959 {.
      cdecl, importc: "yarray_event_target".}
else:
  static :
    hint("Declaration of " & "yarray_event_target" &
        " already exists, not redeclaring")
when not declared(ymap_event_target):
  proc ymap_event_target*(e: ptr StructYMapEvent_1191183072): ptr Branch_1191182959 {.
      cdecl, importc: "ymap_event_target".}
else:
  static :
    hint("Declaration of " & "ymap_event_target" &
        " already exists, not redeclaring")
when not declared(yxmlelem_event_target):
  proc yxmlelem_event_target*(e: ptr StructYXmlEvent_1191183080): ptr Branch_1191182959 {.
      cdecl, importc: "yxmlelem_event_target".}
else:
  static :
    hint("Declaration of " & "yxmlelem_event_target" &
        " already exists, not redeclaring")
when not declared(yxmltext_event_target):
  proc yxmltext_event_target*(e: ptr StructYXmlTextEvent_1191183084): ptr Branch_1191182959 {.
      cdecl, importc: "yxmltext_event_target".}
else:
  static :
    hint("Declaration of " & "yxmltext_event_target" &
        " already exists, not redeclaring")
when not declared(ytext_event_path):
  proc ytext_event_path*(e: ptr StructYTextEvent_1191183068; len: ptr uint32): ptr StructYPathSegment_1191183104 {.
      cdecl, importc: "ytext_event_path".}
else:
  static :
    hint("Declaration of " & "ytext_event_path" &
        " already exists, not redeclaring")
when not declared(ymap_event_path):
  proc ymap_event_path*(e: ptr StructYMapEvent_1191183072; len: ptr uint32): ptr StructYPathSegment_1191183104 {.
      cdecl, importc: "ymap_event_path".}
else:
  static :
    hint("Declaration of " & "ymap_event_path" &
        " already exists, not redeclaring")
when not declared(yxmlelem_event_path):
  proc yxmlelem_event_path*(e: ptr StructYXmlEvent_1191183080; len: ptr uint32): ptr StructYPathSegment_1191183104 {.
      cdecl, importc: "yxmlelem_event_path".}
else:
  static :
    hint("Declaration of " & "yxmlelem_event_path" &
        " already exists, not redeclaring")
when not declared(yxmltext_event_path):
  proc yxmltext_event_path*(e: ptr StructYXmlTextEvent_1191183084;
                            len: ptr uint32): ptr StructYPathSegment_1191183104 {.
      cdecl, importc: "yxmltext_event_path".}
else:
  static :
    hint("Declaration of " & "yxmltext_event_path" &
        " already exists, not redeclaring")
when not declared(yarray_event_path):
  proc yarray_event_path*(e: ptr StructYArrayEvent_1191183076; len: ptr uint32): ptr StructYPathSegment_1191183104 {.
      cdecl, importc: "yarray_event_path".}
else:
  static :
    hint("Declaration of " & "yarray_event_path" &
        " already exists, not redeclaring")
when not declared(ypath_destroy):
  proc ypath_destroy*(path: ptr StructYPathSegment_1191183104; len: uint32): void {.
      cdecl, importc: "ypath_destroy".}
else:
  static :
    hint("Declaration of " & "ypath_destroy" &
        " already exists, not redeclaring")
when not declared(ytext_event_delta):
  proc ytext_event_delta*(e: ptr StructYTextEvent_1191183068; len: ptr uint32): ptr StructYDeltaOut_1191183112 {.
      cdecl, importc: "ytext_event_delta".}
else:
  static :
    hint("Declaration of " & "ytext_event_delta" &
        " already exists, not redeclaring")
when not declared(yxmltext_event_delta):
  proc yxmltext_event_delta*(e: ptr StructYXmlTextEvent_1191183084;
                             len: ptr uint32): ptr StructYDeltaOut_1191183112 {.
      cdecl, importc: "yxmltext_event_delta".}
else:
  static :
    hint("Declaration of " & "yxmltext_event_delta" &
        " already exists, not redeclaring")
when not declared(yarray_event_delta):
  proc yarray_event_delta*(e: ptr StructYArrayEvent_1191183076; len: ptr uint32): ptr StructYEventChange_1191183116 {.
      cdecl, importc: "yarray_event_delta".}
else:
  static :
    hint("Declaration of " & "yarray_event_delta" &
        " already exists, not redeclaring")
when not declared(yxmlelem_event_delta):
  proc yxmlelem_event_delta*(e: ptr StructYXmlEvent_1191183080; len: ptr uint32): ptr StructYEventChange_1191183116 {.
      cdecl, importc: "yxmlelem_event_delta".}
else:
  static :
    hint("Declaration of " & "yxmlelem_event_delta" &
        " already exists, not redeclaring")
when not declared(ytext_delta_destroy):
  proc ytext_delta_destroy*(delta: ptr StructYDeltaOut_1191183112; len: uint32): void {.
      cdecl, importc: "ytext_delta_destroy".}
else:
  static :
    hint("Declaration of " & "ytext_delta_destroy" &
        " already exists, not redeclaring")
when not declared(yevent_delta_destroy):
  proc yevent_delta_destroy*(delta: ptr StructYEventChange_1191183116;
                             len: uint32): void {.cdecl,
      importc: "yevent_delta_destroy".}
else:
  static :
    hint("Declaration of " & "yevent_delta_destroy" &
        " already exists, not redeclaring")
when not declared(ymap_event_keys):
  proc ymap_event_keys*(e: ptr StructYMapEvent_1191183072; len: ptr uint32): ptr StructYEventKeyChange_1191183120 {.
      cdecl, importc: "ymap_event_keys".}
else:
  static :
    hint("Declaration of " & "ymap_event_keys" &
        " already exists, not redeclaring")
when not declared(yxmlelem_event_keys):
  proc yxmlelem_event_keys*(e: ptr StructYXmlEvent_1191183080; len: ptr uint32): ptr StructYEventKeyChange_1191183120 {.
      cdecl, importc: "yxmlelem_event_keys".}
else:
  static :
    hint("Declaration of " & "yxmlelem_event_keys" &
        " already exists, not redeclaring")
when not declared(yxmltext_event_keys):
  proc yxmltext_event_keys*(e: ptr StructYXmlTextEvent_1191183084;
                            len: ptr uint32): ptr StructYEventKeyChange_1191183120 {.
      cdecl, importc: "yxmltext_event_keys".}
else:
  static :
    hint("Declaration of " & "yxmltext_event_keys" &
        " already exists, not redeclaring")
when not declared(yevent_keys_destroy):
  proc yevent_keys_destroy*(keys: ptr StructYEventKeyChange_1191183120;
                            len: uint32): void {.cdecl,
      importc: "yevent_keys_destroy".}
else:
  static :
    hint("Declaration of " & "yevent_keys_destroy" &
        " already exists, not redeclaring")
when not declared(yundo_manager):
  proc yundo_manager*(doc: ptr YDoc_typedef_1191182957;
                      options: ptr StructYUndoManagerOptions_1191183124): ptr YUndoManager_1191182977 {.
      cdecl, importc: "yundo_manager".}
else:
  static :
    hint("Declaration of " & "yundo_manager" &
        " already exists, not redeclaring")
when not declared(yundo_manager_destroy):
  proc yundo_manager_destroy*(mgr: ptr YUndoManager_1191182977): void {.cdecl,
      importc: "yundo_manager_destroy".}
else:
  static :
    hint("Declaration of " & "yundo_manager_destroy" &
        " already exists, not redeclaring")
when not declared(yundo_manager_add_origin):
  proc yundo_manager_add_origin*(mgr: ptr YUndoManager_1191182977;
                                 origin_len: uint32; origin: cstring): void {.
      cdecl, importc: "yundo_manager_add_origin".}
else:
  static :
    hint("Declaration of " & "yundo_manager_add_origin" &
        " already exists, not redeclaring")
when not declared(yundo_manager_remove_origin):
  proc yundo_manager_remove_origin*(mgr: ptr YUndoManager_1191182977;
                                    origin_len: uint32; origin: cstring): void {.
      cdecl, importc: "yundo_manager_remove_origin".}
else:
  static :
    hint("Declaration of " & "yundo_manager_remove_origin" &
        " already exists, not redeclaring")
when not declared(yundo_manager_add_scope):
  proc yundo_manager_add_scope*(mgr: ptr YUndoManager_1191182977;
                                ytype: ptr Branch_1191182959): void {.cdecl,
      importc: "yundo_manager_add_scope".}
else:
  static :
    hint("Declaration of " & "yundo_manager_add_scope" &
        " already exists, not redeclaring")
when not declared(yundo_manager_clear):
  proc yundo_manager_clear*(mgr: ptr YUndoManager_1191182977): void {.cdecl,
      importc: "yundo_manager_clear".}
else:
  static :
    hint("Declaration of " & "yundo_manager_clear" &
        " already exists, not redeclaring")
when not declared(yundo_manager_stop):
  proc yundo_manager_stop*(mgr: ptr YUndoManager_1191182977): void {.cdecl,
      importc: "yundo_manager_stop".}
else:
  static :
    hint("Declaration of " & "yundo_manager_stop" &
        " already exists, not redeclaring")
when not declared(yundo_manager_undo):
  proc yundo_manager_undo*(mgr: ptr YUndoManager_1191182977): uint8 {.cdecl,
      importc: "yundo_manager_undo".}
else:
  static :
    hint("Declaration of " & "yundo_manager_undo" &
        " already exists, not redeclaring")
when not declared(yundo_manager_redo):
  proc yundo_manager_redo*(mgr: ptr YUndoManager_1191182977): uint8 {.cdecl,
      importc: "yundo_manager_redo".}
else:
  static :
    hint("Declaration of " & "yundo_manager_redo" &
        " already exists, not redeclaring")
when not declared(yundo_manager_undo_stack_len):
  proc yundo_manager_undo_stack_len*(mgr: ptr YUndoManager_1191182977): uint32 {.
      cdecl, importc: "yundo_manager_undo_stack_len".}
else:
  static :
    hint("Declaration of " & "yundo_manager_undo_stack_len" &
        " already exists, not redeclaring")
when not declared(yundo_manager_redo_stack_len):
  proc yundo_manager_redo_stack_len*(mgr: ptr YUndoManager_1191182977): uint32 {.
      cdecl, importc: "yundo_manager_redo_stack_len".}
else:
  static :
    hint("Declaration of " & "yundo_manager_redo_stack_len" &
        " already exists, not redeclaring")
when not declared(yundo_manager_observe_added):
  proc yundo_manager_observe_added*(mgr: ptr YUndoManager_1191182977;
                                    state: pointer; callback: proc (a0: pointer;
      a1: ptr StructYUndoEvent_1191183128): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yundo_manager_observe_added".}
else:
  static :
    hint("Declaration of " & "yundo_manager_observe_added" &
        " already exists, not redeclaring")
when not declared(yundo_manager_observe_popped):
  proc yundo_manager_observe_popped*(mgr: ptr YUndoManager_1191182977;
                                     state: pointer; callback: proc (
      a0: pointer; a1: ptr StructYUndoEvent_1191183128): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yundo_manager_observe_popped".}
else:
  static :
    hint("Declaration of " & "yundo_manager_observe_popped" &
        " already exists, not redeclaring")
when not declared(ytype_kind):
  proc ytype_kind*(branch: ptr Branch_1191182959): int8 {.cdecl,
      importc: "ytype_kind".}
else:
  static :
    hint("Declaration of " & "ytype_kind" & " already exists, not redeclaring")
when not declared(ysticky_index_destroy):
  proc ysticky_index_destroy*(pos: ptr YStickyIndex_1191183132): void {.cdecl,
      importc: "ysticky_index_destroy".}
else:
  static :
    hint("Declaration of " & "ysticky_index_destroy" &
        " already exists, not redeclaring")
when not declared(ysticky_index_assoc):
  proc ysticky_index_assoc*(pos: ptr YStickyIndex_1191183132): int8 {.cdecl,
      importc: "ysticky_index_assoc".}
else:
  static :
    hint("Declaration of " & "ysticky_index_assoc" &
        " already exists, not redeclaring")
when not declared(ysticky_index_from_index):
  proc ysticky_index_from_index*(branch: ptr Branch_1191182959;
                                 txn: ptr YTransaction_1191183040;
                                 index: uint32; assoc: int8): ptr YStickyIndex_1191183132 {.
      cdecl, importc: "ysticky_index_from_index".}
else:
  static :
    hint("Declaration of " & "ysticky_index_from_index" &
        " already exists, not redeclaring")
when not declared(ysticky_index_encode):
  proc ysticky_index_encode*(pos: ptr YStickyIndex_1191183132; len: ptr uint32): cstring {.
      cdecl, importc: "ysticky_index_encode".}
else:
  static :
    hint("Declaration of " & "ysticky_index_encode" &
        " already exists, not redeclaring")
when not declared(ysticky_index_decode):
  proc ysticky_index_decode*(binary: cstring; len: uint32): ptr YStickyIndex_1191183132 {.
      cdecl, importc: "ysticky_index_decode".}
else:
  static :
    hint("Declaration of " & "ysticky_index_decode" &
        " already exists, not redeclaring")
when not declared(ysticky_index_to_json):
  proc ysticky_index_to_json*(pos: ptr YStickyIndex_1191183132): cstring {.
      cdecl, importc: "ysticky_index_to_json".}
else:
  static :
    hint("Declaration of " & "ysticky_index_to_json" &
        " already exists, not redeclaring")
when not declared(ysticky_index_from_json):
  proc ysticky_index_from_json*(json: cstring): ptr YStickyIndex_1191183132 {.
      cdecl, importc: "ysticky_index_from_json".}
else:
  static :
    hint("Declaration of " & "ysticky_index_from_json" &
        " already exists, not redeclaring")
when not declared(ysticky_index_read):
  proc ysticky_index_read*(pos: ptr YStickyIndex_1191183132;
                           txn: ptr YTransaction_1191183040;
                           out_branch: ptr ptr Branch_1191182959;
                           out_index: ptr uint32): void {.cdecl,
      importc: "ysticky_index_read".}
else:
  static :
    hint("Declaration of " & "ysticky_index_read" &
        " already exists, not redeclaring")
when not declared(yweak_destroy):
  proc yweak_destroy*(weak: ptr Weak_1191183052): void {.cdecl,
      importc: "yweak_destroy".}
else:
  static :
    hint("Declaration of " & "yweak_destroy" &
        " already exists, not redeclaring")
when not declared(yweak_deref):
  proc yweak_deref*(map_link: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yweak_deref".}
else:
  static :
    hint("Declaration of " & "yweak_deref" & " already exists, not redeclaring")
when not declared(yweak_read):
  proc yweak_read*(text_link: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                   out_branch: ptr ptr Branch_1191182959;
                   out_start_index: ptr uint32; out_end_index: ptr uint32): void {.
      cdecl, importc: "yweak_read".}
else:
  static :
    hint("Declaration of " & "yweak_read" & " already exists, not redeclaring")
when not declared(yweak_iter):
  proc yweak_iter*(array_link: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): ptr YWeakIter_1191182965 {.
      cdecl, importc: "yweak_iter".}
else:
  static :
    hint("Declaration of " & "yweak_iter" & " already exists, not redeclaring")
when not declared(yweak_iter_destroy):
  proc yweak_iter_destroy*(iter: ptr YWeakIter_1191182965): void {.cdecl,
      importc: "yweak_iter_destroy".}
else:
  static :
    hint("Declaration of " & "yweak_iter_destroy" &
        " already exists, not redeclaring")
when not declared(yweak_iter_next):
  proc yweak_iter_next*(iter: ptr YWeakIter_1191182965): ptr StructYOutput_1191182995 {.
      cdecl, importc: "yweak_iter_next".}
else:
  static :
    hint("Declaration of " & "yweak_iter_next" &
        " already exists, not redeclaring")
when not declared(yweak_string):
  proc yweak_string*(text_link: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): cstring {.
      cdecl, importc: "yweak_string".}
else:
  static :
    hint("Declaration of " & "yweak_string" & " already exists, not redeclaring")
when not declared(yweak_xml_string):
  proc yweak_xml_string*(xml_text_link: ptr Branch_1191182959;
                         txn: ptr YTransaction_1191183040): cstring {.cdecl,
      importc: "yweak_xml_string".}
else:
  static :
    hint("Declaration of " & "yweak_xml_string" &
        " already exists, not redeclaring")
when not declared(yweak_observe):
  proc yweak_observe*(weak: ptr Branch_1191182959; state: pointer; cb: proc (
      a0: pointer; a1: ptr StructYWeakLinkEvent_1191183088): void {.cdecl.}): ptr YSubscription_1191182985 {.
      cdecl, importc: "yweak_observe".}
else:
  static :
    hint("Declaration of " & "yweak_observe" &
        " already exists, not redeclaring")
when not declared(ymap_link):
  proc ymap_link*(map: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                  key: cstring): ptr Weak_1191183052 {.cdecl,
      importc: "ymap_link".}
else:
  static :
    hint("Declaration of " & "ymap_link" & " already exists, not redeclaring")
when not declared(ytext_quote):
  proc ytext_quote*(text: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                    start_index: ptr uint32; end_index: ptr uint32;
                    start_exclusive: int8; end_exclusive: int8): ptr Weak_1191183052 {.
      cdecl, importc: "ytext_quote".}
else:
  static :
    hint("Declaration of " & "ytext_quote" & " already exists, not redeclaring")
when not declared(yarray_quote):
  proc yarray_quote*(array: ptr Branch_1191182959; txn: ptr YTransaction_1191183040;
                     start_index: ptr uint32; end_index: ptr uint32;
                     start_exclusive: int8; end_exclusive: int8): ptr Weak_1191183052 {.
      cdecl, importc: "yarray_quote".}
else:
  static :
    hint("Declaration of " & "yarray_quote" & " already exists, not redeclaring")
when not declared(ybranch_id):
  proc ybranch_id*(branch: ptr Branch_1191182959): StructYBranchId_1191183138 {.
      cdecl, importc: "ybranch_id".}
else:
  static :
    hint("Declaration of " & "ybranch_id" & " already exists, not redeclaring")
when not declared(ybranch_get):
  proc ybranch_get*(branch_id: ptr StructYBranchId_1191183138;
                    txn: ptr YTransaction_1191183040): ptr Branch_1191182959 {.
      cdecl, importc: "ybranch_get".}
else:
  static :
    hint("Declaration of " & "ybranch_get" & " already exists, not redeclaring")
when not declared(ybranch_alive):
  proc ybranch_alive*(branch: ptr Branch_1191182959): uint8 {.cdecl,
      importc: "ybranch_alive".}
else:
  static :
    hint("Declaration of " & "ybranch_alive" &
        " already exists, not redeclaring")
when not declared(ybranch_json):
  proc ybranch_json*(branch: ptr Branch_1191182959; txn: ptr YTransaction_1191183040): cstring {.
      cdecl, importc: "ybranch_json".}
else:
  static :
    hint("Declaration of " & "ybranch_json" & " already exists, not redeclaring")