import
    types,
    bitboard

import std/[
    random
]

export types, bitboard

type Position* = object
    pieces: array[red..blocked, Bitboard]
    us*: Color
    halfmoveClock*, halfmovesPlayed*: int
    zobristKey*: Zobristkey

func `[]`*(position: Position, color: Color): Bitboard {.inline.} =
    position.pieces[color]

func `[]`*(position: var Position, color: Color): var Bitboard {.inline.} =
    position.pieces[color]

func `[]=`*(position: var Position, color: Color, bitboard: Bitboard) {.inline.} =
    position.pieces[color] = bitboard

func `[]`*(position: Position, square: Square): Color =
    for color in red..blocked:
        if (position[color] and square.toBitboard) != 0:
            return color
    noColor

func addPiece*(position: var Position, color: Color, target: Square) {.inline.} =
    position[color] |= target.toBitboard

func removePiece*(position: var Position, color: Color, source: Square) {.inline.} =
    position[color] &= not source.toBitboard

func movePiece*(position: var Position, color: Color, source, target: Square) {.inline.} =
    position.removePiece(color, source)
    position.addPiece(color, target)

func enemy*(position: Position): Color =
    position.us.opposite

func occupancy*(position: Position): Bitboard =
    position[red] or position[blue] or position[blocked]

const zobristKeyTable = block:
    var
        zobristKeyTable: array[red..blocked, array[a1..g7, ZobristKey]]
        rand = initRand(seed = 0)
    for color in red..blocked:
        for sq in a1..g7:
            zobristKeyTable[color][sq] = rand.next()
    zobristKeyTable

func zobristKey*(color: Color, square: Square): ZobristKey =
    zobristKeyTable[color][square]

func calculateZobristKey*(position: Position): ZobristKey =
    for color in red..blocked:
        for square in position[color]:
            result ^= zobristKey(color, square)
    result ^= position.us.ZobristKey


