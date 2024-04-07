import types, move, position, searchParams

import std/[math, sets]

#-------------- Repetition detection --------------#

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

#-------------- History heuristic --------------#

type HistoryTable* = object
  table: array[red .. blue, array[a1 .. g7, array[a1 .. g7, float]]]

func halve(h: var HistoryTable, color: Color) =
  for sq1 in a1 .. g7:
    for sq2 in a1 .. g7:
      h.table[color][sq1][sq2] /= historyTableShrinkDiv()

func add(h: var HistoryTable, color: Color, move: Move, addition: float) =
  template entry(): auto =
    h.table[color][move.source][move.target]

  entry =
    clamp(entry + addition, -maxHistoryTableValue().float, maxHistoryTableValue().float)

  if entry.abs >= maxHistoryTableValue().float:
    h.halve(color)

func update*(
    h: var HistoryTable, move: Move, color: Color, depth: Ply, raisedAlpha: bool
) =
  if move == nullMove:
    return

  doAssert move.source != noSquare and move.target != noSquare

  let addition =
    (if raisedAlpha: 1.0 else: -1.0 / historyTableBadMoveDivider()) * depth.float ^ 2

  h.add(color, move, addition)

func get*(h: HistoryTable, move: Move, color: Color): -1.0 .. 1.0 =
  if move != nullMove:
    doAssert move.source != noSquare and move.target != noSquare

    return h.table[color][move.source][move.target] / maxHistoryTableValue().float
