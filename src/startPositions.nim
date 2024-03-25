import bitboard

export bitboard

import std/[sets]

const upperLeftQuadrant =
  (file(a1) or file(b1) or file(c1) or file(d1)) and
  (rank(a7) or rank(a6) or rank(a5) or rank(a4))

const startPiecePositions =
  a1.toBitboard or g1.toBitboard or a7.toBitboard or g7.toBitboard

func addBlockers(bitboard: Bitboard, howMany: int): seq[Bitboard] =
  if howMany <= 0:
    return @[bitboard]

  for sq in (upperLeftQuadrant and not bitboard and not startPiecePositions):
    result.add addBlockers(bitboard or sq.toBitboard, howMany - 1)

func getUpperLeftBlockerConfigurations(maxNumBlockers: int): seq[Bitboard] =
  for numBlockers in 0 .. maxNumBlockers:
    result.add 0.addBlockers(numBlockers)

func getBlockerConfigurations*(maxNumBlockers: int): seq[Bitboard] =
  var blockerSet: HashSet[Bitboard]
  # this weird calculation is to make sure that we indeed get all configurations with at most maxNumBlockers blockers
  let maxUpperLeftNum =
    max((maxNumBlockers div 4) + 1, min(maxNumBlockers div 2 + 1, 7))
  let upperLeftBlockers = getUpperLeftBlockerConfigurations(maxUpperLeftNum)

  for upperLeft in upperLeftBlockers:
    let blockers =
      upperLeft or upperLeft.mirrorHorizontally or upperLeft.mirrorVertically or
      upperLeft.rotate180
    if blockers.countSetBits <= maxNumBlockers:
      if blockers.rotate90 notin blockerSet:
        blockerSet.incl blockers

  for b in blockerSet:
    result.add b

# let blockerConfigurations = getBlockerConfigurations(16)
# for b in blockerConfigurations:
#   echo b.toString

# echo blockerConfigurations.len
