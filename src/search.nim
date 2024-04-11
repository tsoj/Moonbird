import
  types, bitboard, position, positionUtils, move, searchUtils, moveIterator, hashTable,
  searchParams, evaluation, utils, movegen

func futilityReduction(value: Value): Ply =
  clampToType(value.int div futilityReductionDiv(), Ply)

func nullMoveDepth(depth: Ply): Ply =
  depth - nullMoveDepthSub() - depth div nullMoveDepthDiv().Ply

func lmrDepth(depth: Ply, lmrMoveCounter: int): Ply =
  let halfLife = lmrDepthHalfLife()
  result = ((depth.int * halfLife) div (halfLife + lmrMoveCounter)).Ply - lmrDepthSub()

type SearchState* {.requiresInit.} = object
  stop*: bool
  hashTable*: ptr HashTable
  historyTable*: HistoryTable
  repetition*: Repetition
  countedNodes*: int
  maxNodes*: int
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
    bestMove: Move,
    depth, height: Ply,
    nodeType: NodeType,
    bestValue: Value,
) =
  if bestMove != noMove and bestValue.abs < valueInfinity:
    state.hashTable[].add(position.zobristKey, nodeType, bestValue, depth, bestMove)
    if nodeType != allNode:
      state.historyTable.update(bestMove, position.us, depth, raisedAlpha = true)

func search(
    position: Position, state: var SearchState, alpha, beta: Value, depth, height: Ply
): Value =
  assert alpha < beta

  state.countedNodes += 1

  if height > 0.Ply and (
    height == Ply.high or position.halfmoveClock >= 100 or
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
    moveCounter = 0
    lmrMoveCounter = 0

  let depth = block:
    var depth = depth

    # internal iterative reduction
    if hashResult.isEmpty and depth >= iirMinDepth():
      depth -= 1.Ply

    depth

  let beta = block:
    # update alpha, beta or return immediatly based on hash table result
    var beta = beta
    if height > 0 and not hashResult.isEmpty and hashResult.depth >= depth:
      if hashResult.nodeType == pvNode:
        return hashResult.value
      if hashResult.nodeType != allNode:
        alpha = max(alpha, hashResult.value)
      if hashResult.nodeType != cutNode:
        beta = min(beta, hashResult.value)

      if alpha >= beta:
        return alpha
    beta

  if depth <= 0.Ply:
    return state.eval(position)

  # null move reduction
  if height > 0 and (hashResult.isEmpty or hashResult.nodeType == cutNode) and
      (position[us].singles.singles and not position.occupancy).countSetBits >=
      minTargetSquaresNullMovePruning():
    let value =
      -position.doMove(nullMove).search(
        state,
        alpha = -beta,
        beta = -beta + 1.Value,
        depth = nullMoveDepth(depth),
        height = height + 1.Ply,
      )

    if value >= beta:
      return value

  # iterate over all moves and recursively search the new positions
  for move in position.moveIterator(hashResult.bestMove, state.historyTable):
    let newPosition = position.doMove(move)
    moveCounter += 1

    # stop search if necessary
    if state.shouldStop:
      return if bestValue > -valueInfinity: bestValue else: alpha

    if depth == 1 and move.isDouble:
      continue

    var
      newDepth = depth
      newBeta = beta

    # late move reduction
    if moveCounter >= minMoveCounterLmr():
      newDepth = lmrDepth(newDepth, lmrMoveCounter)
      lmrMoveCounter += 1

    # futility reduction
    if moveCounter >= minMoveCounterFutility():
      newDepth -= futilityReduction(alpha + state.eval(newPosition))

    if newDepth <= 0:
      continue

    # first explore with null window
    if hashResult.isEmpty or hashResult.bestMove != move or
        hashResult.nodeType == allNode:
      newBeta = alpha + 1

    # search new position
    var value =
      -newPosition.search(
        state,
        alpha = -newBeta,
        beta = -alpha,
        depth = newDepth - 1.Ply,
        height = height + 1.Ply,
      )

    # re-search with full window and full depth
    if value > alpha and (newDepth < depth or newBeta < beta):
      newDepth = depth
      value =
        -newPosition.search(
          state,
          alpha = -beta,
          beta = -alpha,
          depth = depth - 1.Ply,
          height = height + 1.Ply,
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
      state.historyTable.update(move, us, depth, raisedAlpha = false)

  if moveCounter <= 1:
    let status = position.gameStatus

    if status in [draw, fiftyMoveRule]:
      return 0.Value
    if status.winColor == us:
      return height.valueWin
    if status.winColor == position.enemy:
      return -height.valueWin

  state.update(position, bestMove, depth = depth, height = height, nodeType, bestValue)

  bestValue

func search*(position: Position, state: var SearchState, depth: Ply) =
  state.stop = false
  state.countedNodes = 0

  let hashResult = state.hashTable[].get(position.zobristKey)

  var
    estimatedValue = (if hashResult.isEmpty: 0.Value else: hashResult.value).float
    alphaOffset = aspirationWindowStartingOffset().float
    betaOffset = aspirationWindowStartingOffset().float

  # growing alpha beta window
  while not state.shouldStop:
    let
      alpha = max(estimatedValue - alphaOffset, -valueInfinity.float).Value
      beta = min(estimatedValue + betaOffset, valueInfinity.float).Value

    let value =
      position.search(state, alpha = alpha, beta = beta, depth = depth, height = 0.Ply)

    doAssert value.abs <= valueInfinity

    estimatedValue = value.float
    if value <= alpha:
      alphaOffset *= aspirationWindowMultiplier()
    elif value >= beta:
      betaOffset *= aspirationWindowMultiplier()
    else:
      break
