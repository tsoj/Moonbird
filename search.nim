import
    types,
    bitboard,
    position,
    positionUtils,
    move,
    searchUtils,
    moveIterator,
    hashTable,
    evaluation,
    utils,
    searchParams,
    movegen

import std/[
    atomics,
    options
]

# static: doAssert pawn.value == 100.cp

# func futilityReduction(value: Value): Ply =
#     clampToType(value.toCp div futilityReductionDiv(), Ply)

# func hashResultFutilityMargin(depthDifference: Ply): Value =
#     depthDifference.Value * hashResultFutilityMarginMul().cp

# func nullMoveDepth(depth: Ply): Ply =
#     depth - nullMoveDepthSub() - depth div nullMoveDepthDiv().Ply

# func lmrDepth(depth: Ply, lmrMoveCounter: int): Ply =
#     let halfLife = lmrDepthHalfLife()
#     result = ((depth.int * halfLife) div (halfLife + lmrMoveCounter)).Ply - lmrDepthSub()

type SearchState* {.requiresInit.} = object
    stop*: bool
    hashTable*: ptr HashTable
    # killerTable*: KillerTable
    # historyTable*: HistoryTable
    repetition*: Repetition
    countedNodes*: int64
    maxNodes*: int64
    stopTime*: Seconds
    eval*: EvaluationFunction

func shouldStop(state: var SearchState): bool =
    if state.countedNodes >= state.maxNodes or
    ((state.countedNodes mod 1998) == 1107 and secondsSince1970() >= state.stopTime):
        state.stop = true
    state.stop

func update(
    state: var SearchState,
    position: Position,
    bestMove: Move,# previous: Move,
    depth, height: Ply,
    nodeType: NodeType,
    bestValue: Value
) =
    if bestMove != noMove and bestValue.abs < valueInfinity:
        state.hashTable[].add(position.zobristKey, nodeType, bestValue, depth, bestMove)
        # if nodeType != allNode:
        #     state.historyTable.update(bestMove, previous, position.us, depth, raisedAlpha = true)
        # if nodeType == cutNode:
        #     state.killerTable.update(height, bestMove)

func search(
    position: Position,
    state: var SearchState,
    alpha, beta: Value,
    depth, height: Ply
): Value =
    assert alpha < beta

    state.countedNodes += 1

    if height > 0.Ply and (
        height == Ply.high or
        position.halfmoveClock >= 100 or
        state.repetition.addAndCheckForRepetition(position, height)
    ):
        return 0.Value
    
    let
        us = position.us
        hashResult = state.hashTable[].get(position.zobristKey)

    var
        alpha = alpha
        nodeType = allNode
        bestMove = noMove
        bestValue = -valueInfinity

    if depth <= 0.Ply:
        return state.eval(position)

    # iterate over all moves and recursively search the new positions
    for move in position.moveIterator(hashResult.bestMove):

        let newPosition = position.doMove(move)

        # stop search if we exceeded maximum nodes or we got a stop signal from outside
        if state.shouldStop:
            break
        
        # search new position
        var value = -newPosition.search(
            state,
            alpha = -beta, beta = -alpha,
            depth = depth - 1.Ply, height = height + 1.Ply
        )

        if value > bestValue:
            bestValue = value
            bestMove = move

        if value >= beta:
            nodeType = cutNode
            break

        if value > alpha:
            nodeType = pvNode
            alpha = value
    
    state.update(position, bestMove, depth = depth, height = height, nodeType, bestValue)

    bestValue

func search*(
    position: Position,
    state: var SearchState,
    depth: Ply
) =

    state.stop = false
    state.countedNodes = 0

    discard position.search(
        state,
        alpha = -valueInfinity, beta = valueInfinity,
        depth = depth, height = 0.Ply
    )
