import
  types, bitboard, position, positionUtils, move, searchUtils, moveIterator, hashTable,
  evaluation, utils, movegen

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
    bestMove: Move, # previous: Move,
    depth, height: Ply,
    nodeType: NodeType,
    bestValue: Value,
) =
  if bestMove != noMove and bestValue.abs < valueInfinity:
    state.hashTable[].add(position.zobristKey, nodeType, bestValue, depth, bestMove)
    if nodeType != allNode:
      state.historyTable.update(bestMove, position.us, depth, raisedAlpha = true)
    # if nodeType == cutNode:
    #     state.killerTable.update(height, bestMove)

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

  let hashResult = state.hashTable[].get(position.zobristKey)

  var
    alpha = alpha
    nodeType = allNode
    bestMove = noMove
    bestValue = -valueInfinity
    moveCounter = 0

  if depth <= 0.Ply:
    return state.eval(position)

  # iterate over all moves and recursively search the new positions
  for move in position.moveIterator(hashResult.bestMove, state.historyTable):
    let newPosition = position.doMove(move)
    moveCounter += 1

    # stop search if we exceeded maximum nodes or we got a stop signal from outside
    if state.shouldStop:
      return # TODO break
      #break

    # search new position
    var value =
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
      state.historyTable.update(move, position.us, depth, raisedAlpha = false)

  if moveCounter <= 1:
    let
      status = position.gameStatus
      winColor = [red: winRed, blue: winBlue]

    if status in [draw, fiftyMoveRule]:
      return 0.Value
    if status == winColor[position.us]:
      return height.valueWin
    if status == winColor[position.enemy]:
      return -height.valueWin

  state.update(position, bestMove, depth = depth, height = height, nodeType, bestValue)

  bestValue

func search*(position: Position, state: var SearchState, depth: Ply) =
  state.stop = false
  state.countedNodes = 0

  discard position.search(
    state, alpha = -valueInfinity, beta = valueInfinity, depth = depth, height = 0.Ply
  )
