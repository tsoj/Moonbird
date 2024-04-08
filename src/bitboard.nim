import types, utils

export types

import std/[options, bitops]

export bitops

type Bitboard* = uint64

func `&=`*(a: var Bitboard, b: Bitboard) =
  a = a and b
func `|=`*(a: var Bitboard, b: Bitboard) =
  a = a or b
func `^=`*(a: var Bitboard, b: Bitboard) =
  a = a xor b

func toBitboard*(square: Square): Bitboard =
  1u64 shl square.int8

const fullBoard*: Bitboard = block:
  var fullBoard: Bitboard = 0
  for sq in a1 .. g7:
    fullBoard |= sq.toBitboard
  fullBoard

func toSquare*(x: Bitboard): Square =
  let x = (x and fullBoard)
  if x == 0: noSquare else: x.countTrailingZeroBits.Square

iterator items*(bitboard: Bitboard): Square {.inline.} =
  var occ = bitboard
  while occ != 0:
    yield occ.countTrailingZeroBits.Square
    occ &= occ - 1

func toString*(bitboard: Bitboard): string =
  boardString(
    proc(square: Square): auto =
      if (square.toBitboard and bitboard) != 0:
        some ("●", fgDefault)
      else:
        none (string, ForegroundColor)
  )

func file*(square: Square): Bitboard =
  const aFile =
    a1.toBitboard or a2.toBitboard or a3.toBitboard or a4.toBitboard or a5.toBitboard or
    a6.toBitboard or a7.toBitboard
  (aFile shl (square.int mod 7))

func rank*(square: Square): Bitboard =
  const rank1 = 0b1111111.Bitboard
  (rank1 shl (7 * (square.int div 7)))

func mirrorHorizontally*(bitboard: Bitboard): Bitboard =
  for i in 0 .. 3:
    let
      f1 = file(i.Square)
      f2 = file((6 - i).Square)
      shiftAmount = 6 - 2 * i
    result |= (bitboard and f1) shl shiftAmount
    result |= (bitboard and f2) shr shiftAmount

func mirrorVertically*(bitboard: Bitboard): Bitboard =
  for i in 0 .. 3:
    let
      r1 = rank((i * 7).Square)
      r2 = rank(((6 - i) * 7).Square)
      shiftAmount = (6 - 2 * i) * 7
    result |= (bitboard and r1) shl shiftAmount
    result |= (bitboard and r2) shr shiftAmount


func rotate90*(bitboard: Bitboard): Bitboard =
  for sq in bitboard:
    result |=
      newSquare(rankNumber = 6 - sq.fileNumber, fileNumber = sq.rankNumber).toBitboard

func rotate180*(bitboard: Bitboard): Bitboard =
  bitboard.mirrorHorizontally.mirrorVertically

func rotate270*(bitboard: Bitboard): Bitboard =
  bitboard.rotate180.rotate90

func up(bitboard: Bitboard): Bitboard =
  bitboard shl 7

func down(bitboard: Bitboard): Bitboard =
  bitboard shr 7

func right(bitboard: Bitboard): Bitboard =
  bitboard shl 1

func left(bitboard: Bitboard): Bitboard =
  bitboard shr 1

func singles*(bitboard: Bitboard): Bitboard =
  result =
    ((bitboard.right) or (bitboard.up.right) or (bitboard.down.right)) and not file(a1)

  result |=
    ((bitboard.left) or (bitboard.up.left) or (bitboard.down.left)) and not file(g1)

  result |= bitboard.down or bitboard.up
  result &= fullBoard

func computeMask(square: Square, size: int): Bitboard =
  if size <= 0:
    return square.toBitboard

  result = square.toBitboard

  for i in 1 .. size:
    result |= result.singles

const masks = block:
  var masks: array[0 .. 6, array[a1 .. g7, Bitboard]]
  for size in 0 .. 6:
    for square in a1 .. g7:
      masks[size][square] = square.computeMask(size)
  masks

const attacks = block:
  var attacks: array[1 .. 6, array[a1 .. g7, Bitboard]]
  for size in 1 .. 6:
    for square in a1 .. g7:
      attacks[size][square] = masks[size][square] and not masks[size - 1][square]
  attacks

func mask*(square: Square, size: 0 .. 6): Bitboard =
  masks[size][square]

func attack*(square: Square, size: 1 .. 6): Bitboard =
  attacks[size][square]

func singles*(square: Square): Bitboard =
  square.attack(1)

func doubles*(square: Square): Bitboard =
  square.attack(2)
