import types

export types

type
  ParamValue = float32
  EvalParams* = object
    pst*: array[a1 .. g7, ParamValue]

func doForAll[T](
    output: var T,
    input: T,
    operation: proc(a: var ParamValue, b: ParamValue) {.noSideEffect, raises: [].},
) {.raises: [].} =
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

const defaultEvalParams* = block:
  var e: EvalParams
  doForAll(
    e,
    e,
    proc(x: var ParamValue, y: ParamValue) =
      x = 1.0
    ,
  )
  e
