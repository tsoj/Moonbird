import bitboard, position, positionUtils, movegen

export bitboard, position

import std/[sets, tables, random]

const startPositionsFileName = "res/ply3_fair.txt"

let openingPositions = block:
  var positions: seq[Position]
  for line in startPositionsFileName.lines:
    if line.len == 0 or line[0] == '#':
      continue
    positions.add line.toPosition

  var rg = initRand()
  rg.shuffle(positions)
  positions

func balance(position: Position, depth: int, maxAllowedInbalance: int): int =
  let
    us = position.us
    enemy = position.enemy

  if depth <= 0:
    return position[us].countSetBits - position[enemy].countSetBits

  result = int.low
  for move in position.moves:
    let newPosition = position.doMove move
    result = max(result, -newPosition.balance(depth - 1, maxAllowedInbalance))
    if result > maxAllowedInbalance:
      break

proc getStartPositions*(minNumPositions: int, fairExplorationDepth = 2): seq[Position] =
  {.cast(noSideEffect).}:
    result = openingPositions
  var rg = initRand()
  while result.len < minNumPositions:
    let position = result[rg.rand(0 ..< result.len)]
    for move in position.moves:
      let newPosition = position.doMove move
      if newPosition.balance(depth = fairExplorationDepth, maxAllowedInbalance = 0).abs ==
          0:
        result.add newPosition
    rg.shuffle(result)

proc createStartPositionFile*(fileName: string, numPositions: int) =
  var positions = getStartPositions(numPositions)
  positions.shuffle
  let fenFile = open(fileName, fmWrite)
  for position in positions:
    fenFile.writeLine position.fen
  fenFile.close()

when isMainModule:
  let startPositions = getStartPositions(10_000)

  for i, p in startPositions:
    print p
    if i >= 100:
      break
  echo startPositions.len
