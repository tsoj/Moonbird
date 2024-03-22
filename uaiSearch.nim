import
    types,
    move,
    position,
    positionUtils,
    timeManagedSearch,
    hashTable,
    #evaluation,
    utils

import std/[
    strformat
    # strutils,
    # algorithm,
    # sugar,
    # random,
    # sets
]

export SearchInfo

proc infoString(
    iteration: int,
    value: Value,
    nodes: int,
    pv: seq[Move],
    time: Seconds,
    hashFull: int
): string =
    let nps = int(nodes.float / time.float)
    result = fmt"info depth {iteration+1:>2} time {int(time * 1000.0):>6} nodes {nodes:>9} nps {nps:>7} hashfull {hashFull:>4} score cp {value:>4} pv"
    for move in pv:
        result &= " " & $move
        

proc uaiSearch*(searchInfo: SearchInfo) =

    var
        bestMove = noMove
        iteration = 0

    for (pv, value, nodes, passedTime) in searchInfo.iterativeTimeManagedSearch():
        
        echo infoString(
            iteration = iteration,
            value = value,
            nodes = nodes,
            pv = pv,
            time = passedTime,
            hashFull = searchInfo.hashTable[].hashFull
        )

        if pv.len > 0:
            bestMove = pv[0]
        iteration += 1

    echo "bestmove ", bestMove

