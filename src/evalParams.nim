import types

import std/[os, random, math]

export types

type
  ParamValue = float32
  CoreEvalParams* = object
    pst*: array[4, array[a1 .. g7, array[3 ^ 8, ParamValue]]]
    environmentCounts*:
      array[a1 .. g7, array[0 .. 8, array[0 .. 8, ParamValue]]]
    mobility*: array[0 .. 49, array[0 .. 49, ParamValue]]
    turnBonus*: ParamValue

  EvalParams* {.requiresInit.} = object
    data: seq[CoreEvalParams]

func get*(ep: EvalParams): lent CoreEvalParams =
  ep.data[0]
func get*(ep: var EvalParams): var CoreEvalParams =
  ep.data[0]

func newEvalParams*(): EvalParams =
  EvalParams(data: newSeq[CoreEvalParams](1))

func doForAll[T](
    output: var T,
    input: T,
    operation: proc(a: var ParamValue, b: ParamValue) {.noSideEffect.},
) =
  when T is ParamValue:
    operation(output, input)
  elif T is object:
    for name, inValue, outValue in fieldPairs(input, output):
      doForAll(outValue, inValue, operation)
  elif T is array:
    for index in T.low .. T.high:
      doForAll(output[index], input[index], operation)
  else:
    static:
      doAssert false, "Type is not not implemented for doForAll: " & $typeof(T)

func `+=`*(a: var EvalParams, b: EvalParams) =
  proc op(x: var ParamValue, y: ParamValue) =
    x += y

  doForAll(a.get, b.get, op)

func `*=`*(a: var EvalParams, b: EvalParams) =
  proc op(x: var ParamValue, y: ParamValue) =
    x *= y

  doForAll(a.get, b.get, op)

func `*=`*(a: var EvalParams, b: ParamValue) =
  proc op(x: var ParamValue, y: ParamValue) =
    x *= b

  doForAll(a.get, a.get, op)

func setAll*(a: var EvalParams, b: ParamValue) =
  proc op(x: var ParamValue, y: ParamValue) =
    x = b

  doForAll(a.get, a.get, op)

proc setRandom*(a: var EvalParams, b: Slice[float64]) =
  proc op(x: var ParamValue, y: ParamValue) =
    {.cast(noSideEffect).}:
      x = rand(b).ParamValue

  doForAll(a.get, a.get, op)

const charWidth = 8

proc toString*(evalParams: EvalParams): string =
  var
    s: string
    params = evalParams

  proc op(x: var ParamValue, y: ParamValue) =
    doAssert x in int16.low.ParamValue .. int16.high.ParamValue
    for i in 0 ..< sizeof(int16):
      let
        shift = charWidth * i
        bits = cast[char]((x.int16 shr shift) and 0b1111_1111)
      s.add bits

  doForAll(params.get, params.get, op)
  s

proc toEvalParams*(s: string): EvalParams =
  var
    params = newEvalParams()
    n = 0

  proc op(x: var ParamValue, y: ParamValue) =
    var bits: int16 = 0
    for i in 0 ..< sizeof(int16):
      let shift = charWidth * i
      bits = bits or (cast[int16](s[n]) shl shift)
      n += 1
    x = bits.ParamValue

  doForAll(params.get, params.get, op)

  params

const defaultEvalParamsString = block:
  var s = ""

  const fileName = "res/params/default.bin"
  if fileExists fileName:
    # For some reason staticRead starts relative paths at the source file location
    s = staticRead("../" & fileName)
  else:
    echo "WARNING! Couldn't find default eval params at ", fileName
  s

let defaultEvalParamsData* = block:
  var ep = newEvalParams()

  if defaultEvalParamsString.len > 0:
    if defaultEvalParamsString.len == ep.toString.len:
      ep = defaultEvalParamsString.toEvalParams
    else:
      echo "WARNING! Incompatible params format"
  else:
    echo "WARNING! Empty eval params string"
  ep

template defaultEvalParams*(): EvalParams =
  {.cast(noSideEffect).}:
    defaultEvalParamsData
