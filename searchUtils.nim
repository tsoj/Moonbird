import
    types,
    move,
    position,
    searchParams,
    zobrist

import std/[
    math
]

#-------------- repetition detection --------------#

type Repetition* = object
    staticHistory: HashSet[ZobristKey]
    dynamicHistory: array[Ply, ZobristKey]


func add(r: var Repetition, key: ZobristKey) =
    r.staticHistory.incl key

func addAndCheckForRepetition(r: var Repetition, position: Position, height: Ply): bool =
    let key = position.zobristKey
    r.dynamicHistory[height] = key
    key in r.staticHistory or key in r.dynamicHistory[max(0, height - position.halfmoveClock)..<height]

func newRepetition*(staticHistory: seq[Position]): Repetition =
    for position in staticHistory:
        result.staticHistory.incl position.zobristKey

func update*(gameHistory: var GameHistory, position: Position, height: Ply) =
    gameHistory.dynamicHistory[height] = position.zobristKey

