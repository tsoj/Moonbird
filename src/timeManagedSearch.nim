import types, move, position, hashTable, rootSearch, evaluation, utils

import std/[sequtils]

type SearchInfo* {.requiresInit.} = object
  positionHistory*: seq[Position]
  hashTable*: ptr HashTable
  targetDepth*: Ply = Ply.high
  movesToGo*: int = int.high
  increment*, timeLeft*: array[red .. blue, Seconds] =
    [red: Seconds.high, blue: Seconds.high]
  moveTime*: Seconds = Seconds.high
  nodes*: int = int.high
  numThreads*: int = 1
  eval*: EvaluationFunction = perspectiveEvaluate

type MoveTime = object
  maxTime, approxTime: Seconds

func calculateMoveTime(
    moveTime, timeLeft, incPerMove: Seconds, movesToGo, halfmovesPlayed: int
): MoveTime =
  doAssert movesToGo >= 0
  let
    estimatedGameLength = 70
    estimatedMovesToGo = max(20, estimatedGameLength - halfmovesPlayed div 2)
    newMovesToGo = max(2, min(movesToGo, estimatedMovesToGo))

  result.maxTime = min(timeLeft / 2, moveTime)
  result.approxTime = incPerMove + timeLeft / newMovesToGo

  if incPerMove >= 2.Seconds or timeLeft > 180.Seconds:
    result.approxTime = result.approxTime * 1.2
  elif incPerMove < 0.2.Seconds and timeLeft < 30.Seconds:
    result.approxTime = result.approxTime * 0.8
    if movesToGo > 2:
      result.maxTime = min(timeLeft / 4, moveTime)

iterator iterativeTimeManagedSearch*(
    searchInfo: SearchInfo
): tuple[pv: seq[Move], value: Value, nodes: int, passedTime: Seconds] =
  const numConsideredBranchingFactors = 4

  doAssert searchInfo.positionHistory.len >= 1, "Need at least one position"

  let
    position = searchInfo.positionHistory[^1]
    us = position.us
    calculatedMoveTime = calculateMoveTime(
      searchInfo.moveTime,
      searchInfo.timeLeft[us],
      searchInfo.increment[us],
      searchInfo.movesToGo,
      position.halfmovesPlayed,
    )

  let start = secondsSince1970()
  var
    startLastIteration = secondsSince1970()
    branchingFactors = repeat(2.0, numConsideredBranchingFactors)
    lastNumNodes = int.high

  for (pv, value, nodes) in iterativeDeepeningSearch(
    positionHistory = searchInfo.positionHistory,
    hashTable = searchInfo.hashTable[],
    targetDepth = searchInfo.targetDepth,
    maxNodes = searchInfo.nodes,
    stopTime = start + calculatedMoveTime.maxTime,
    numThreads = searchInfo.numThreads,
    eval = searchInfo.eval,
  ):
    let
      totalPassedTime = secondsSince1970() - start
      iterationPassedTime = (secondsSince1970() - startLastIteration)
    startLastIteration = secondsSince1970()

    yield (pv: pv, value: value, nodes: nodes, passedTime: iterationPassedTime)

    doAssert calculatedMoveTime.approxTime >= 0.Seconds

    branchingFactors.add(nodes.float / lastNumNodes.float)
    lastNumNodes = if nodes <= 100_000: int.high else: nodes

    let averageBranchingFactor = block:
      var average = 0.0
      for f in branchingFactors[^numConsideredBranchingFactors ..^ 1]:
        average += f
      average / numConsideredBranchingFactors.float

    let estimatedTimeNextIteration = iterationPassedTime * averageBranchingFactor
    if estimatedTimeNextIteration + totalPassedTime > calculatedMoveTime.approxTime:
      break

proc timeManagedSearch*(searchInfo: SearchInfo): tuple[pv: seq[Move], value: Value] =
  for (pv, value, nodes, passedTime) in searchInfo.iterativeTimeManagedSearch():
    result = (pv: pv, value: value)
