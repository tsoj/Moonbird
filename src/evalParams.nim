import types

import std/[os, random, math]

export types

type
  ParamValue = float32
  CoreEvalParams* = object
    pst*: array[a1 .. g7, array[4 ^ 4, ParamValue]]
    mobility*: array[49, ParamValue]
    turnBonus*: ParamValue

  EvalParams* {.requiresInit.} = object
    data: seq[CoreEvalParams]

func get*(ep: EvalParams): CoreEvalParams =
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
  doForAll(
    a.get,
    b.get,
    proc(x: var ParamValue, y: ParamValue) =
      x += y
    ,
  )

func `*=`*(a: var EvalParams, b: EvalParams) =
  doForAll(
    a.get,
    b.get,
    proc(x: var ParamValue, y: ParamValue) =
      x *= y
    ,
  )

func `*=`*(a: var EvalParams, b: ParamValue) =
  doForAll(
    a.get,
    a.get,
    proc(x: var ParamValue, y: ParamValue) =
      x *= b
    ,
  )

func setAll*(a: var EvalParams, b: ParamValue) =
  doForAll(
    a.get,
    a.get,
    proc(x: var ParamValue, y: ParamValue) =
      x = b
    ,
  )

proc setRandom*(a: var EvalParams, b: Slice[float64]) =
  doForAll(
    a.get,
    a.get,
    proc(x: var ParamValue, y: ParamValue) =
      {.cast(noSideEffect).}:
        x = rand(b).ParamValue
    ,
  )

const charWidth = 8

proc toString*(evalParams: EvalParams): string =
  var
    s: string
    params = evalParams

  proc op(x: var ParamValue, y: ParamValue) =
    for i in 0 ..< sizeof(float64):
      let
        shift = charWidth * i
        bits = cast[char]((cast[uint64](x.float64) shr shift) and 0b1111_1111)
      s.add bits

  doForAll(params.get, params.get, op)
  s

proc toEvalParams*(s: string): EvalParams =
  var
    params = newEvalParams()
    i = 0

  proc op(x: var ParamValue, y: ParamValue) =
    var bits: uint64 = 0
    for n in 0 ..< sizeof(float64):
      let shift = charWidth * i
      bits = bits or (cast[uint64](cast[uint8](s[i])) shl shift)
      i += 1
    x = cast[float64](bits)

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
