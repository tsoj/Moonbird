import move, position, movegen, searchUtils, searchParams

iterator moveIterator*(
    position: Position,
    tryFirstMove = noMove,
    historyTable: HistoryTable or tuple[] = (),
): Move =
  if tryFirstMove.isLegal(position):
    yield tryFirstMove

  let moves = position.moves

  assert moves.len >= 1

  var movePriorities = newSeqOfCap[float](moves.len)

  for move in moves:
    var score = move.pieceDelta(position).float

    when historyTable is HistoryTable:
      score += historyTable.get(move, position.us) * historyMoveOrderingFactor()

    if move.isDouble:
      score += doubleMoveOrderingBonus()

    movePriorities.add score

    if move == tryFirstMove:
      movePriorities[^1] = float.low

  while true:
    var
      bestValue = float.low
      bestIndex = -1

    for i, priority in movePriorities:
      if priority > bestValue:
        bestValue = priority
        bestIndex = i

    if bestIndex == -1:
      break

    movePriorities[bestIndex] = float.low
    yield moves[bestIndex]
