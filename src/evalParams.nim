import types

import std/[streams, os]

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

proc writeEvalParams*(stream: Stream, evalParams: EvalParams) =
  var params = evalParams
  doForAll(
    params,
    params,
    proc(x: var ParamValue, y: ParamValue) =
      {.cast(noSideEffect).}:
        stream.write x.float64
    ,
  )

proc readEvalParams*(stream: Stream): EvalParams =
  doAssert not isNil stream
  var params: EvalParams

  proc op(x: var ParamValue, y: ParamValue) =
    {.cast(noSideEffect).}:
      discard
      x = stream.readFloat64().ParamValue

  doForAll(params, params, op)

proc writeEvalParams*(evalParams: EvalParams, fileName: string) =
  var strm = newFileStream(fileName, fmWrite)
  if isNil(strm):
    raise newException(IOError, "Couldn't open file: " & fileName)
  strm.writeEvalParams evalParams
  strm.close

# proc readEvalParams*(fileName: string): EvalParams =
#   let strm = newFileStream(fileName, fmRead)
#   if isNil(strm):
#     raise newException(IOError, "Couldn't open file: " & fileName)
#   result = strm.readEvalParams
#   strm.close

# proc staticReadEvalParams*(fileName: string): EvalParams =
#   # staticRead(fileName)
#   let strm = newStringStream("hellleioj")
#   strm.setPosition 0
#   let a = strm.readFloat64
#   debugEcho a
#   # if isNil(strm):
#   #   raise newException(IOError, "Couldn't open static stream for: " & fileName)
#   # result = strm.readEvalParams
#   strm.close

const defaultEvalParams* = block:
  var e: EvalParams
  doForAll(
    e,
    e,
    proc(x: var ParamValue, y: ParamValue) =
      x = 1.0
    ,
  )

  # const fileName = "default.bin" #"res/params/default.bin"
  # if fileExists fileName:
  #   e = staticReadEvalParams fileName
  # else:
  #   echo "WARNING! Couldn't find default eval params at ", fileName
  e


#import std/streams

const hello = block:
  let strm = newStringStream("12345678")
  strm.readFloat64

echo hello