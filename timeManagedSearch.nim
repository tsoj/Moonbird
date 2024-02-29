import
    types,
    move,
    position,
    hashTable,
    # rootSearch,
    # evaluation,
    utils

import std/[
    sequtils
]


type SearchInfo* = object
    position*: Position
    hashTable*: ptr HashTable
    positionHistory*: seq[Position]
    targetDepth*: Ply
    movesToGo*: int
    increment*, timeLeft*: array[red..blue, Seconds]
    moveTime*: Seconds
    nodes*: int64

type MoveTime = object
    maxTime, approxTime: Seconds
func calculateMoveTime(moveTime, timeLeft, incPerMove: Seconds, movesToGo, halfmovesPlayed: int): MoveTime = 

    doAssert movesToGo >= 0
    let
        estimatedGameLength = 70
        estimatedMovesToGo = max(20, estimatedGameLength - halfmovesPlayed div 2)
        newMovesToGo = max(2, min(movesToGo, estimatedMovesToGo))

    result.maxTime = min(timeLeft / 2, moveTime)
    result.approxTime = incPerMove + timeLeft/newMovesToGo

    if incPerMove >= 2.Seconds or timeLeft > 180.Seconds:
        result.approxTime = result.approxTime * 1.2
    elif incPerMove < 0.2.Seconds and timeLeft < 30.Seconds:
        result.approxTime = result.approxTime * 0.8
        if movesToGo > 2:
            result.maxTime = min(timeLeft / 4, moveTime)

iterator iterativeTimeManagedSearch*(searchInfo: SearchInfo): tuple[pv: seq[Move], value: Value, nodes: int64, passedTime: Seconds] =

    const numConsideredBranchingFactors = 4

    let
        us = searchInfo.position.us
        calculatedMoveTime = calculateMoveTime(
            searchInfo.moveTime,
            searchInfo.timeLeft[us],
            searchInfo.increment[us],
            searchInfo.movesToGo,
            searchInfo.position.halfmovesPlayed
        )

    let start = secondsSince1970()
    var
        startLastIteration = secondsSince1970()
        branchingFactors = repeat(2.0, numConsideredBranchingFactors)
        lastNumNodes = int64.high

    for (pv, value, nodes) in iterativeDeepeningSearch(
        position,
        hashTable,
        stop,
        positionHistory,
        targetDepth,
        numThreads = if calculatedMoveTime.approxTime <= 0.1.Seconds: 1 else: numThreads,
        maxNodes = maxNodes,
        stopTime = start + calculatedMoveTime.maxTime,
        multiPv = multiPv,
        searchMoves = searchMoves,
        evaluation = evaluation,
        requireRootPv = requireRootPv
    ):
        let
            totalPassedTime = secondsSince1970() - start
            iterationPassedTime = (secondsSince1970() - startLastIteration)
        startLastIteration = secondsSince1970()

        yield (pv: pv, value: value, nodes: nodes, passedTime: iterationPassedTime)

        doAssert calculatedMoveTime.approxTime >= 0.Seconds
        
        branchingFactors.add(nodes.float / lastNumNodes.float)
        lastNumNodes = if nodes <= 100_000: int64.high else: nodes

        let averageBranchingFactor = block:
            var average = 0.0
            for f in branchingFactors[^numConsideredBranchingFactors..^1]:
                average += f
            average / numConsideredBranchingFactors.float

        let estimatedTimeNextIteration = iterationPassedTime * averageBranchingFactor
        if estimatedTimeNextIteration + totalPassedTime > calculatedMoveTime.approxTime:
            break;

        if timeLeft[us] < Seconds.high:
            break

    stop[].store(true)

proc timeManagedSearch*(searchInfo: SearchInfo): tuple[pv: seq[PMove], value: Value] =
    for (pv, value, nodes, passedTime) in searchInfo.iterativeTimeManagedSearch():
        result = (pv: pv, value: value)
