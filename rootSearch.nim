import
    types,
    position,
    positionUtils,
    move,
    search,
    hashTable,
    searchUtils,
    # evaluation,
    utils,
    movegen

import std/[
    os,
    atomics,
    strformat,
    options,
    sets
]

func launchSearch(position: Position, state: var SearchState, depth: Ply): int64 =
    try:
        position.search(state, depth = depth)
        return state.countedNodes
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
    positionHistory: seq[Position] = @[],
    targetDepth: Ply = Ply.high,
    maxNodes = int64.high,
    stopTime = Seconds.high
): tuple[pv: seq[Move], value: Value, nodes: int64] {.noSideEffect.} =

    var
        totalNodes = 0'i64
        searchState = SearchState(
            hashTable: addr hashTable,
            repetition: newRepetition(positionHistory),
            maxNodes: maxNodes,
            stopTime: stopTime
        )

    hashTable.age()        

    for depth in 1.Ply..targetDepth:
        let nodes = launchSearch(position, searchState, depth)
        totalNodes += nodes
        

        var
            pv = hashTable.getPv(position)
            value = hashTable.get(position.zobristKey).value
                    
        if pv.len == 0:
            debugEcho &"WARNING: Couldn't find PV at root node.\n{position.fen = }"
            doAssert position.moves.len > 0
            pv = @[position.moves[0]]

        yield (pv: pv, value: value, nodes: nodes)
        
        if searchState.stop or totalNodes >= maxNodes:
            break