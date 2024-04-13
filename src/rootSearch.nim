import
  types, position, positionUtils, move, search, hashTable, searchUtils, evaluation,
  utils, movegen

import std/[strformat]

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
      historyTable: HistoryTable(),
      repetition: newRepetition(positionHistory[0 ..^ 2]),
      maxNodes: maxNodes,
      stopTime: stopTime,
      eval: eval,
    )

  hashTable.age()
  for depth in 1.Ply .. targetDepth:
    position.search(searchState, depth)
    let nodes = searchState.countedNodes
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
