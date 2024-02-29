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
    see,
    searchParams

import std/[
    atomics,
    options
]

static: doAssert pawn.value == 100.cp

func futilityReduction(value: Value): Ply =
    clampToType(value.toCp div futilityReductionDiv(), Ply)

func hashResultFutilityMargin(depthDifference: Ply): Value =
    depthDifference.Value * hashResultFutilityMarginMul().cp

func nullMoveDepth(depth: Ply): Ply =
    depth - nullMoveDepthSub() - depth div nullMoveDepthDiv().Ply

func lmrDepth(depth: Ply, lmrMoveCounter: int): Ply =
    let halfLife = lmrDepthHalfLife()
    result = ((depth.int * halfLife) div (halfLife + lmrMoveCounter)).Ply - lmrDepthSub()

type SearchState* = object
    stop: bool
    hashTable*: ptr HashTable
    # killerTable*: KillerTable
    # historyTable*: HistoryTable
    repetition*: Repetition
    countedNodes*: int64
    maxNodes*: int64
    stopTime*: Seconds

func shouldStop(state: SearchState): bool =
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
    depth, height: Ply,
    previous: Move
): Value =
    assert alpha < beta

    state.countedNodes += 1

    if (
        height == Ply.high or state.repetition.addAndCheck(position, height) or
        position.halfmoveClock >= 100
    ) and height > 0:
        return 0.Value
    
    let
        us = position.us
        hashResult = state.hashTable[].get(position.zobristKey)

    var
        alpha = alpha
        nodeType = allNode
        bestMove = noMove
        bestValue = -valueInfinity

    if depth <= 0:
        return position.evaluate

    # iterate over all moves and recursively search the new positions
    for move in position.treeSearchMoveIterator(hashResult.bestMove):

        if height == 0.Ply and move in state.skipMovesAtRoot:
            continue

        let newPosition = position.doMove(move)
        if newPosition.inCheck(us):
            continue
        moveCounter += 1

        let givingCheck = newPosition.inCheck(newPosition.us)

        var
            newDepth = depth
            newBeta = beta

        if not givingCheck:

            # late move reduction
            if moveCounter >= minMoveCounterLmr() and not move.isTactical:
                newDepth = lmrDepth(newDepth, lmrMoveCounter)
                lmrMoveCounter += 1

            # futility reduction
            if moveCounter >= minMoveCounterFutility() and newDepth > 0:
                newDepth -= futilityReduction(alpha - staticEval - position.see(move))
            
            if newDepth <= 0:
                continue

        # first explore with null window
        if hashResult.isEmpty or hashResult.bestMove != move or hashResult.nodeType == allNode:
            newBeta = alpha + 1

        # stop search if we exceeded maximum nodes or we got a stop signal from outside
        if state.shouldStop:
            break
        
        # search new position
        var value = -newPosition.search(
            state,
            alpha = -newBeta, beta = -alpha,
            depth = newDepth - 1.Ply, height = height + 1.Ply,
            previous = move
        )

        # re-search with full window and full depth
        if value > alpha and (newDepth < depth or newBeta < beta):
            newDepth = depth
            value = -newPosition.search(
                state,
                alpha = -beta, beta = -alpha,
                depth = depth - 1.Ply, height = height + 1.Ply,
                previous = move
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
        else:
            state.historyTable.update(move, previous = previous, us, newDepth, raisedAlpha = false)

    if moveCounter == 0:
        # checkmate
        if inCheck:
            bestValue = -(height.checkmateValue)
        # stalemate
        else:
            bestValue = 0.Value
    
    state.update(position, bestMove, previous = previous, depth = depth, height = height, nodeType, bestValue)

    bestValue

func search*(
    position: Position,
    state: var SearchState,
    depth: Ply
): Value =

    let hashResult = state.hashTable[].get(position.zobristKey)

    var
        estimatedValue = (if hashResult.isEmpty: 0.Value else: hashResult.value).float
        alphaOffset = aspirationWindowStartingOffset().cp.float
        betaOffset = aspirationWindowStartingOffset().cp.float

    # growing alpha beta window
    while not state.shouldStop:
        let
            alpha = max(estimatedValue - alphaOffset, -valueInfinity.float).Value
            beta = min(estimatedValue + betaOffset, valueInfinity.float).Value

        result = position.search(
            state,
            alpha = alpha, beta = beta,
            depth = depth, height = 0,
            previous = noMove
        )
        doAssert result.abs <= valueInfinity

        estimatedValue = result.float
        if result <= alpha:
            alphaOffset *= aspirationWindowMultiplier()
        elif result >= beta:
            betaOffset *= aspirationWindowMultiplier()
        else:
            break
