import
    types,
    position,
    positionUtils,
    move,
    # search,
    hashTable,
    # searchUtils,
    # evaluation,
    utils

import std/[
    os,
    atomics,
    strformat,
    options,
    sets
]

func launchSearch(position: Position, state: ptr SearchState, depth: Ply): int64 =
    try:
        discard position.search(state[], depth = depth)
        state[].threadStop[].store(true)
        return state[].countedNodes
    except CatchableError:
        {.cast(noSideEffect).}:
            debugEcho "Caught exception: ", getCurrentExceptionMsg()
            debugEcho getCurrentException().getStackTrace()
    except Exception:
        {.cast(noSideEffect).}:
            debugEcho "Caught exception: ", getCurrentExceptionMsg()
            debugEcho getCurrentException().getStackTrace()
            quit(QuitFailure)

iterator iterativeDeepeningSearch*(
    position: Position,
    hashTable: var HashTable,
    stop: ptr Atomic[bool],
    positionHistory: seq[Position] = @[],
    targetDepth: Ply = Ply.high,
    maxNodes = int64.high,
    stopTime = Seconds.high
): tuple[pv: seq[Move], value: Value, nodes: int64] {.noSideEffect.} =
    {.cast(noSideEffect).}:

        block:
            let
                numThreads = max(1, numThreads)
                gameHistory = newGameHistory(positionHistory)
            var
                totalNodes = 0'i64
                searchStates: seq[SearchState]
                threadpool = none(Taskpool)
                threadStop: Atomic[bool]

            for _ in 0..<numThreads:
                searchStates.add SearchState(
                    stop: stop,
                    threadStop: addr threadStop,
                    hashTable: addr hashTable,
                    historyTable: newHistoryTable(),
                    gameHistory: gameHistory,
                    maxNodes: maxNodes,
                    stopTime: stopTime,
                    skipMovesAtRoot: @[],
                    evaluation: evaluation
                )                
                

            hashTable.age()        

            for depth in 1.Ply..targetDepth:

                var
                    foundCheckmate = false
                    pvList: seq[Pv]
                    skipMoves: seq[Move]
                    multiPvNodes = 0'i64

                for move in position.legalMoves:
                    if move notin searchMoves and searchMoves.len > 0:
                        skipMoves.add move

                for multiPvNumber in 1..multiPv:

                    for move in skipMoves:
                        doAssert move in position.legalMoves
                    
                    if skipMoves.len == position.legalMoves.len:
                        break

                    var currentPvNodes = 0'i64
                    
                    threadStop.store(false)

                    for searchState in searchStates.mitems:
                        searchState.skipMovesAtRoot = skipMoves
                        searchState.countedNodes = 0
                        searchState.maxNodes = (maxNodes - totalNodes) div numThreads.int64

                    if numThreads == 1:
                        currentPvNodes = launchSearch(position, addr searchStates[0], depth)
                    else:
                        if not threadpool.isSome:
                            threadpool = some Taskpool.new(numThreads)
                        var threadSeq: seq[FlowVar[int64]]
                        for i in 0..<numThreads:
                            if i > 0:
                                sleep(1)
                            threadSeq.add threadpool.get.spawn launchSearch(position, addr searchStates[i], depth)
               
                        for flowVar in threadSeq.mitems:
                            currentPvNodes += sync flowVar

                    totalNodes += currentPvNodes
                    multiPvNodes += currentPvNodes

                    var
                        pv = hashTable.getPv(position)
                        value = hashTable.get(position.zobristKey).value
                    
                    if pv.len == 0:
                        let msg = &"WARNING: Couldn't find PV at root node.\n{position.fen = }"
                        if requireRootPv:
                            doAssert false, msg
                        else:
                            debugEcho msg
                            doAssert position.legalMoves.len > 0
                            pv = @[position.legalMoves[0]]

                    skipMoves.add pv[0]

                    pvList.add Pv(value: value, pv: pv)

                    foundCheckmate = abs(value) >= valueCheckmate
                
                    if stop[].load or totalNodes >= maxNodes:
                        break
                

                if pvList.len >= min(multiPv, legalMoves.len):
                    yield (
                        pvList: pvList,
                        nodes: multiPvNodes,
                        canStop: legalMoves.len == 1 or foundCheckmate
                    )

                if stop[].load or totalNodes >= maxNodes:
                    break

            if threadpool.isSome:
                threadpool.get.shutdown()