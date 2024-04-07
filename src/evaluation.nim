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
    getParameter(evalState.gradient[].get, parameter) += f
  else:
    static:
      doAssert evalState is EvalValue
    var value = getParameter(evalState.params[].get, parameter).Value
    if goodFor == blue:
      value *= -1
    evalState.absoluteValue[] += value

func maskIndex*(position: Position, square: static Square): int =
  static:
    doAssert square.fileNumber <= 5
    doAssert square.rankNumber <= 5

  let
    redPieces = position[red] shr square.int8
    bluePieces = position[blue] shr square.int8
    blockedPieces = position[blocked] shr square.int8

  var counter = 1

  for sq in [a2, b2, a1, b1]:
    let bit = sq.toBitboard
    if (redPieces and bit) != 0:
      result += counter * 1
    elif (bluePieces and bit) != 0:
      result += counter * 2
    elif (blockedPieces and bit) != 0:
      result += counter * 3
    counter *= 4

func get2x2Mask(square: static Square): Bitboard =
  for sq in [a2, b2, a1, b1]:
    result |= sq.toBitboard shl square.int

func evaluate2x2Structure(evalState: EvalState, position: Position) =

  #!fmt: off
  for square in (
    a1, b1, c1, d1, e1, f1,
    a2, b2, c2, d2, e2, f2,
    a3, b3, c3, d3, e3, f3,
    a4, b4, c4, d4, e4, f4,
    a5, b5, c5, d5, e5, f5,
    a6, b6, c6, d6, e6, f6,
  ).fields:
    if ((position[red] or position[blue]) and square.get2x2Mask) != 0:
      let index = position.maskIndex(square)
      evalState.addValue(goodFor = red, pst[square][index])
  #!fmt: on

func absoluteEvaluate*(evalState: EvalState, position: Position) =
  evalState.evaluate2x2Structure(position)
  evalState.addValue(goodFor = position.us, turnBonus)

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
