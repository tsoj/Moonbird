import
    position,
    types


import std/[
    random
]

type ZobristKey* = uint64

const keys = block:
    var
        keys: array[red..blocked, array[a1..g7, ZobristKey]]
        rand = initRand(seed = 0)
    for color in red..blocked:
        for sq in a1..g7:
            keys[color][sq] = rand.next()
    keys

func zobristKey*(position: Position): ZobristKey =
    for color in red..blocked:
        for square in position[color]:
            result ^= keys[color][square]
    result ^= position.us.ZobristKey