import position, positionUtils, movegen, timeManagedSearch, evaluation, hashTable

import std/[tables]

type Game* {.requiresInit.} = object
  positionHistory*: seq[Position]
  evals: Table[Position, Value] = initTable[Position, Value]()
  maxNodes: int
  adjudicateThreefold: bool
  evaluation: EvaluationFunction
  hashTable: ref HashTable

func getPositionHistory*(game: Game): seq[(Position, Value)] =
  for position in game.positionHistory:
    let value =
      if position in game.evals:
        game.evals[position]
      else:
        valueInfinity
    result.add (position, value)

proc makeNextMove(game: var Game): (GameStatus, Value, Move) =
  doAssert game.positionHistory.len >= 1

  let position = game.positionHistory[^1]

  if position.gameStatus != running:
    return (position.gameStatus, 0.Value, noMove)

  let
    searchInfo = SearchInfo(
      positionHistory: game.positionHistory,
      hashTable: game.hashTable[].addr,
      nodes: game.maxNodes,
      eval: game.evaluation,
    )
    (pv, value) = searchInfo.timeManagedSearch()
    absoluteValue =
      if position.us == red:
        value
      else:
        -value
  doAssert pv.len >= 1
  doAssert pv[0] != noMove
  doAssert position notin game.evals

  game.evals[position] = absoluteValue
  game.positionHistory.add position.doMove pv[0]

  var gameStatus = game.positionHistory[^1].gameStatus

  if game.adjudicateThreefold:
    var counting: Table[tuple[pieces: array[red .. blocked, Bitboard], us: Color], int]
    for position in game.positionHistory:
      let key = (pieces: position.pieces, us: position.us)
      if key notin counting:
        counting[key] = 1
      else:
        counting[key] += 1
        if counting[key] >= 3: 
          gameStatus = draw
          break

  (gameStatus, absoluteValue, pv[0])

func newGame*(
    startPosition: Position,
    maxNodes = 20_000,
    adjudicateThreefold = false,
    hashTable: ref HashTable = nil,
    evaluation: EvaluationFunction = perspectiveEvaluate,
): Game =
  result = Game(
    positionHistory: @[startPosition],
    hashTable: hashTable,
    maxNodes: maxNodes,
    adjudicateThreefold: adjudicateThreefold,
    evaluation: evaluation,
  )

  if result.hashTable == nil:
    {.warning[ProveInit]: off.}:
      result.hashTable = new HashTable
    result.hashTable[] = newHashTable(len = maxNodes * 2)

proc playGame*(game: var Game, printInfo = false): float =
  doAssert game.positionHistory.len >= 1, "Need a start position"

  if printInfo:
    echo "----------------------------"
    echo "start position:"
    print game.positionHistory[0]

  while true:
    let (gameStatus, value, move) = game.makeNextMove()

    if printInfo:
      echo "--------------"
      echo "Move: " & $move
      print game.positionHistory[^1]
      echo "Value: " & $value
      if gameStatus != running:
        echo gameStatus

    if gameStatus != running:
      case gameStatus
      of draw, fiftyMoveRule:
        result = 0.5
      of winRed:
        result = 1.0
      of winBlue:
        result = 0.0
      else:
        doAssert false, $gameStatus

      if printInfo:
        echo "Game status: ", gameStatus
        echo "Result: ", result

      break

when isMainModule:
  var game = newGame("x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1".toPosition, maxNodes = 100_000)
  discard game.playGame(printInfo = true)
