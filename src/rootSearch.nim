import
  types, position, positionUtils, move, search, hashTable, searchUtils, evaluation,
  utils, movegen

import malebolgia

import std/[strformat]

func launchSearch(position: Position, state: ptr SearchState, depth: Ply) =
  position.search(state[], depth = depth)
  state[].stop[].store(true)

iterator iterativeDeepeningSearch*(
    positionHistory: seq[Position],
    hashTable: var HashTable,
    targetDepth: Ply,
    maxNodes: int,
    stopTime: Seconds,
    numThreads: int,
    eval: EvaluationFunction,
): tuple[pv: seq[Move], value: Value, nodes: int] {.noSideEffect.} =
  doAssert positionHistory.len >= 1, "Need at least one position"
  let position = positionHistory[^1]
  var
    totalNodes = 0
    searchStates: seq[SearchState]
    stop: Atomic[bool]

  {.cast(noSideEffect).}:
    var threadpool = createMaster()

  doAssert numThreads >= 1
  doAssert numThreads == 1 or maxNodes == int.high,
    "Node search is not supported with more than one thread"

  for _ in 0 ..< numThreads:
    searchStates.add SearchState(
      stop: addr stop,
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
    stop.store(false)
    if numThreads == 1:
      launchSearch(position, addr searchStates[0], depth)
    else:
      {.cast(noSideEffect).}:
        threadpool.awaitAll:
          for i in 0 ..< numThreads:
            threadpool.spawn launchSearch(position, addr searchStates[i], depth)

    var nodes = 0
    for state in searchStates:
      nodes += state.countedNodes
    totalNodes += nodes

    var
      pv = hashTable.getPv(position)
      value = hashTable.get(position.zobristKey).value

    if pv.len == 0:
      debugEcho &"WARNING: Couldn't find PV at root node.\n{position.fen = }"
      doAssert position.moves.len > 0
      pv = @[position.moves[0]]

    yield (pv: pv, value: value, nodes: nodes)

    if secondsSince1970() >= stopTime or totalNodes >= maxNodes:
      break
