import bitboard, position, positionUtils, movegen

export bitboard, position

import std/[sets, tables, random]

const
  upperLeftQuadrant =
    (file(a1) or file(b1) or file(c1) or file(d1)) and
    (rank(a7) or rank(a6) or rank(a5) or rank(a4))
  startPiecePositions = a1.toBitboard or g1.toBitboard or a7.toBitboard or g7.toBitboard
  defaultMaxNumBlockers = 16

static:
  doAssert startPiecePositions == startPos.occupancy

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

func addBlockers(bitboard: Bitboard, howMany: int): seq[Bitboard] =
  if howMany <= 0:
    return @[bitboard]

  for sq in (upperLeftQuadrant and not bitboard and not startPiecePositions):
    result.add addBlockers(bitboard or sq.toBitboard, howMany - 1)

func getUpperLeftBlockerConfigurations(maxNumBlockers: int): seq[Bitboard] =
  for numBlockers in 0 .. maxNumBlockers:
    result.add 0.addBlockers(numBlockers)

func getBlockerConfigurations*(
    maxNumBlockers: int, minNumBlockers: int = 0
): seq[Bitboard] =
  var blockerSet: HashSet[Bitboard]
  # this weird calculation is to make sure that we indeed get all configurations with at most maxNumBlockers blockers
  let maxUpperLeftNum =
    max((maxNumBlockers div 4) + 1, min(maxNumBlockers div 2 + 1, 7))
  let upperLeftBlockers = getUpperLeftBlockerConfigurations(maxUpperLeftNum)

  for upperLeft in upperLeftBlockers:
    let blockers =
      upperLeft or upperLeft.mirrorHorizontally or upperLeft.mirrorVertically or
      upperLeft.rotate180
    if blockers.countSetBits in minNumBlockers .. maxNumBlockers:
      if blockers.rotate90 notin blockerSet:
        blockerSet.incl blockers

  for b in blockerSet:
    result.add b

func getStartPositions*(
    minNumPositions: int, maxNumBlockers: int = defaultMaxNumBlockers
): seq[Position] =
  var startPositions: Table[int, HashSet[Position]]

  let blockerConfigurations = getBlockerConfigurations(maxNumBlockers = maxNumBlockers)

  for blockerConfig in blockerConfigurations:
    let num = blockerConfig.countSetBits
    var pos = startPos
    doAssert (pos.occupancy and blockerConfig) == 0
    pos[blocked] = blockerConfig
    if num notin startPositions:
      startPositions[num] = initHashSet[Position]()
    startPositions[num].incl pos

  doAssert startPositions.len > 0

  let maxSetSize = block:
    var maxSetSize = 0
    for (num, s) in startPositions.pairs:
      maxSetSize = max(maxSetSize, s.len)
    maxSetSize

  doAssert 0 in startPositions, "There should be at least one positions with no blocks."

  let targetNumPositionsPerBlockerNum =
    max(maxSetSize, minNumPositions div startPositions.len + 1)
  for (numBlocks, s) in startPositions.mpairs:
    block findNewPositions:
      while true:
        var newPositions: seq[Position]
        for pos in s:
          for move in pos.moves:
            var newPosition = pos.doMove(move)
            newPosition.halfmoveClock = startPos.halfmoveClock
            newPosition.halfmovesPlayed = startPos.halfmovesPlayed

            if pos.gameStatus == running and
                newPosition.balance(depth = 2, maxAllowedInbalance = 0).abs == 0:
              newPositions.add newPosition

        for pos in newPositions:
          s.incl pos
          if s.len >= targetNumPositionsPerBlockerNum:
            break findNewPositions

  var numEmpty = 0
  for (num, s) in startPositions.pairs:
    for pos in s:
      if pos[blocked] == 0:
        numEmpty += 1
      result.add pos

  {.cast(noSideEffect).}:
    var rg = initRand()
  rg.shuffle(result)

proc createStartPositionFile*(
    fileName: string, numPositions: int, maxNumBlockers: int = defaultMaxNumBlockers
) =
  var positions = getStartPositions(numPositions, defaultMaxNumBlockers)
  let fenFile = open(fileName, fmWrite)
  for position in positions:
    fenFile.writeLine position.fen
  fenFile.close()

when isMainModule:
  let startPositions = getStartPositions(100_000)

  for p in startPositions[0..100]:
    print p
  echo startPositions.len
