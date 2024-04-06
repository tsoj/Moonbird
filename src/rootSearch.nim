import
  types, position, positionUtils, move, search, hashTable, searchUtils, evaluation,
  utils, movegen

import std/[strformat]

# TODO remove catching errors here, as we don't use threads for search here
func launchSearch(position: Position, state: var SearchState, depth: Ply): int =
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
    positionHistory: seq[Position],
    hashTable: var HashTable,
    targetDepth: Ply,
    maxNodes: int,
    stopTime: Seconds,
    eval: EvaluationFunction,
): tuple[pv: seq[Move], value: Value, nodes: int] {.noSideEffect.} =
  doAssert positionHistory.len >= 1, "Need at least one position"
  let position = positionHistory[^1]
  var
    totalNodes = 0'i64
    searchState = SearchState(
      stop: false,
      countedNodes: 0,
      hashTable: addr hashTable,
      historyTable: newHistoryTable(),
      repetition: newRepetition(positionHistory[0 ..^ 2]),
      maxNodes: maxNodes,
      stopTime: stopTime,
      eval: eval,
    )

  hashTable.age()
  for depth in 1.Ply .. targetDepth:
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
