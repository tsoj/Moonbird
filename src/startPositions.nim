import bitboard, position, positionUtils, movegen

export bitboard, position

import std/[sets, tables]

const upperLeftQuadrant =
  (file(a1) or file(b1) or file(c1) or file(d1)) and
  (rank(a7) or rank(a6) or rank(a5) or rank(a4))

const startPiecePositions =
  a1.toBitboard or g1.toBitboard or a7.toBitboard or g7.toBitboard

static:
  doAssert startPiecePositions == startPos.occupancy

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
    minNumPositions: int, maxNumBlockers: int = 16
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

  let targetNumPositionsPerBlockerNum =
    max(maxSetSize, minNumPositions div startPositions.len + 1)

  for (num, s) in startPositions.mpairs:
    while s.len < targetNumPositionsPerBlockerNum:
      var newPositions: seq[Position]
      for pos in s:
        for move in pos.moves:
          newPositions.add pos.doMove(move)
          newPositions[^1].halfmoveClock = startPos.halfmoveClock
          newPositions[^1].halfmovesPlayed = startPos.halfmovesPlayed

      for pos in newPositions:
        let
          numRed = pos[red].countSetBits
          numBlue = pos[blue].countSetBits
        if abs(numRed - numBlue) <= max(3, min(numRed, numBlue) div 4) and
            pos.gameStatus == running:
          s.incl pos
          if s.len >= targetNumPositionsPerBlockerNum:
            break

  for (num, s) in startPositions.pairs:
    for pos in s:
      result.add pos

when isMainModule:
  let startPositions = getStartPositions(100_000)

  for p in startPositions:
    stdout.printPosition p
  echo startPositions.len
