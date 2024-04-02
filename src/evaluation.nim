import types, position, bitboard, evalParams, positionUtils, movegen

import std/[macros]

type EvaluationFunction* = proc(position: Position): Value {.noSideEffect.}

type
  Gradient* = object
    gradient*: ptr EvalParams
    g*: float32

  EvalValue = object
    params: ptr EvalParams
    absoluteValue: ptr Value

  EvalState = Gradient or EvalValue

macro getParameter(structName, parameter: untyped): untyped =
  let s = $structName.toStrLit & "." & $parameter.toStrLit
  parseExpr(s)

template addValue(evalState: EvalState, goodFor: Color, parameter: untyped) =
  when evalState is Gradient:
    let f = (if goodFor == red: 1.0 else: -1.0) * evalState.g
    getParameter(evalState.gradient[], parameter) += f
  else:
    static:
      doAssert evalState is EvalValue
    var value = getParameter(evalState.params[], parameter).Value
    if goodFor == blue:
      value *= -1
    evalState.absoluteValue[] += value

func pst*(evalState: EvalState, position: Position) =
  for color in red .. blue:
    for square in position[color]:
      evalState.addValue(goodFor = color, pst[square])

func absoluteEvaluate*(evalState: EvalState, position: Position) =
  evalState.pst(position)

func absoluteEvaluate*(evalParams: EvalParams, position: Position): Value =
  let evalValue = EvalValue(params: addr evalParams, absoluteValue: addr result)
  evalValue.absoluteEvaluate(position)

func absoluteEvaluate*(position: Position): Value =
  defaultEvalParams.absoluteEvaluate(position)

func perspectiveEvaluate*(position: Position): Value =
  result = position.absoluteEvaluate
  if position.us == blue:
    result = -result
  # Value(position[position.us].countSetBits - position[position.enemy].countSetBits) * 100
  # Times 100 because we want centipawn values

# let pos = startPos.doMove(Move(source: f1, target: f1))#.doMove(Move(source: a1, target: c1))

# echo pos.absoluteEvaluate
# echo pos.perspectiveEvaluate
