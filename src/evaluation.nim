import types, position, bitboard, evalParams, positionUtils, movegen

import std/[macros, math]

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

func maskIndex*(
    position: Position, square: static Square, us, enemy, blocked: Bitboard
): int =
  static:
    doAssert square.fileNumber <= 5
    doAssert square.rankNumber <= 5

  let
    ourPieces = us shr square.int8
    enemyPieces = enemy shr square.int8
    blockedPieces = blocked shr square.int8

  var counter = 1

  for sq in [a2, b2, a1, b1]:
    let bit = sq.toBitboard
    if (ourPieces and bit) != 0:
      result += counter * 1
    elif (enemyPieces and bit) != 0:
      result += counter * 2
    elif (blockedPieces and bit) != 0:
      result += counter * 3
    counter *= 4

func get2x2Mask(square: static Square): Bitboard =
  for sq in [a2, b2, a1, b1]:
    result |= sq.toBitboard shl square.int

func evaluate2x2Structure(evalState: EvalState, position: Position) =
  let
    us = position.us
    enemy = position.enemy

  var levelOneIndices: array[a1 .. g7, int]

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
      levelOneIndices[square] = position.maskIndex(square, position[us], position[enemy], position[blocked])
  #!fmt: on

  #!fmt: off
  var dirIndex = 0
  for dirAndSquares in (
    (2, (
      a1, b1, c1, d1,
      a2, b2, c2, d2,
      a3, b3, c3, d3,
      a4, b4, c4, d4,
      a5, b5, c5, d5,
      a6, b6, c6, d6,
    )),
    (14, (      
      a1, b1, c1, d1, e1, f1,
      a2, b2, c2, d2, e2, f2,
      a3, b3, c3, d3, e3, f3,
      a4, b4, c4, d4, e4, f4,
    )),
    (16, (      
      a1, b1, c1, d1,
      a2, b2, c2, d2,
      a3, b3, c3, d3,
      a4, b4, c4, d4,
    )),
    (12, (
      c1, d1, e1, f1,
      c2, d2, e2, f2,
      c3, d3, e3, f3,
      c4, d4, e4, f4,
    ))
  ).fields:
    const (dir, squareList) = dirAndSquares
    for square in squareList.fields:
      const otherSquare = (square.int + dir).Square
      let bigIndex = levelOneIndices[square] + (4 ^ 4) * levelOneIndices[otherSquare]

      assert levelOneIndices[square] < 4^4

      evalState.addValue(goodFor = us, pst[dirIndex][square][bigIndex])
    
    dirIndex += 1
  #!fmt: on

func mobility(evalState: EvalState, position: Position) =
  let phase = position.occupancy.countSetBits.clamp(0, 49)
  for color in red .. blue:
    let targets = position[color].singles.singles and not position.occupancy
    evalState.addValue(goodFor = color, mobility[phase][targets.countSetBits])

func environmentCounts(evalState: EvalState, position: Position) =
  for color in red .. blue:
    for square in position[color]:
      let
        numOurPieces = (position[color] and square.attack(1)).countSetBits
        numEnemyPieces = (position[color.opposite] and square.attack(1)).countSetBits
        numBlockers = (position[blocked] and square.attack(1)).countSetBits
      assert numOurPieces <= 8 and numEnemyPieces <= 8 and numBlockers <= 8
      evalState.addValue(
        goodFor = color,
        environmentCounts[square][numOurPieces][numEnemyPieces][numBlockers],
      )

func absoluteEvaluate*(evalState: EvalState, position: Position) =
  evalState.evaluate2x2Structure(position)
  evalState.mobility(position)
  evalState.environmentCounts(position)
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
