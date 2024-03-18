import
    types,
    utils

export types

import std/[
    options,
    bitops
]

export bitops

type Bitboard* = uint64

func `&=`*(a: var Bitboard, b: Bitboard) =
    a = a and b
func `|=`*(a: var Bitboard, b: Bitboard) =
    a = a or b
func `^=`*(a: var Bitboard, b: Bitboard) =
    a = a xor b

func toSquare*(x: Bitboard): Square =
    assert x.countSetBits > 0
    x.countTrailingZeroBits.Square

func toBitboard*(square: Square): Bitboard = 1u64 shl square.int8

iterator items*(bitboard: Bitboard): Square {.inline.} =
    var occ = bitboard
    while occ != 0:
        yield occ.countTrailingZeroBits.Square
        occ &= occ - 1

func bitboardString*(bitboard: Bitboard): string =
    boardString(proc (square: Square): Option[string] =
        if (square.toBitboard and bitboard) != 0:
            return some("●")
        none(string)
    )

func computeMask(square: Square, size: int): Bitboard =
    if size <= 0:
        return square.toBitboard

    result = computeMask(square, size - 1)

    for (dirA, dirB) in [
        (goLeft, goUp),
        (goLeft, goDown),
        (goRight, goUp),
        (goRight, goDown)
    ]:
        for (dir1, dir2) in [(dirA, dirB), (dirB, dirA)]:
            var targetSquare = square
            for i in 1..size:
                discard targetSquare.dir1
            
            for i in 0..size:
                result |= targetSquare.toBitboard
                discard targetSquare.dir2

const masks = block:
    var masks: array[0..6, array[a1..g7, Bitboard]]
    for size in 0..6:
        for square in a1..g7:
            masks[size][square] = square.computeMask(size)
    masks

const attacks = block:
    var attacks: array[1..6, array[a1..g7, Bitboard]]
    for size in 1..6:
        for square in a1..g7:
            attacks[size][square] = masks[size][square] and not masks[size - 1][square]
    attacks

func mask*(square: Square, size: 0..6): Bitboard =
    masks[size][square]

func attack*(square: Square, size: 1..6): Bitboard =
    attacks[size][square]

func singles*(square: Square): Bitboard =
    square.attack(1)

func doubles*(square: Square): Bitboard =
    square.attack(2)
