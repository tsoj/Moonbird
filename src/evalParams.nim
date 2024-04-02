import types

import std/[os, random]

export types

type
  ParamValue = float32
  EvalParams* = object
    pst*: array[a1 .. g7, ParamValue]

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
    a,
    b,
    proc(x: var ParamValue, y: ParamValue) =
      x += y
    ,
  )

func `*=`*(a: var EvalParams, b: EvalParams) =
  doForAll(
    a,
    b,
    proc(x: var ParamValue, y: ParamValue) =
      x *= y
    ,
  )

func `*=`*(a: var EvalParams, b: ParamValue) =
  doForAll(
    a,
    a,
    proc(x: var ParamValue, y: ParamValue) =
      x *= b
    ,
  )

func setAll*(a: var EvalParams, b: ParamValue) =
  doForAll(
    a,
    a,
    proc(x: var ParamValue, y: ParamValue) =
      x = b
    ,
  )
  
proc setRandom*(a: var EvalParams, b: Slice[float64]) =
  doForAll(
    a,
    a,
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

  doForAll(params, params, op)
  s

proc toEvalParams*(s: string): EvalParams =
  var
    params: EvalParams
    i = 0

  proc op(x: var ParamValue, y: ParamValue) =
    var bits: uint64 = 0
    for n in 0 ..< sizeof(float64):
      let shift = charWidth * i
      bits = bits or (cast[uint64](cast[uint8](s[i])) shl shift)
      i += 1
    x = cast[float64](bits)

  doForAll(params, params, op)

  params

const defaultEvalParams* = block:
  var e: EvalParams

  const fileName = "res/params/default.bin"
  if fileExists fileName:
    # For some reason staticRead starts relative paths at the source file location
    e = staticRead("../" & fileName).toEvalParams
  else:
    echo "WARNING! Couldn't find default eval params at ", fileName
  e

echo defaultEvalParams