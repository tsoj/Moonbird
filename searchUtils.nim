import types, move, position, searchParams

import std/[math, sets]

#-------------- repetition detection --------------#

type Repetition* = object
  staticHistory: HashSet[ZobristKey]
  dynamicHistory: array[Ply, ZobristKey]

func addAndCheckForRepetition*(
    r: var Repetition, position: Position, height: Ply
): bool =
  let key = position.zobristKey
  r.dynamicHistory[height] = key
  key in r.staticHistory or
    key in r.dynamicHistory[max(0.Ply, height - position.halfmoveClock) ..< height]

func newRepetition*(staticHistory: openArray[Position]): Repetition =
  for position in staticHistory:
    result.staticHistory.incl position.zobristKey

func update*(repetition: var Repetition, position: Position, height: Ply) =
  repetition.dynamicHistory[height] = position.zobristKey
