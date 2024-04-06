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

type
  HistoryArray = array[red .. blue, array[a1 .. g7, array[a1 .. g7, float]]]
    # TODO make entries dependent on how many pieces are captured
  HistoryTable* = object
    table: HistoryArray
    # counterTable: ref array[pawn..king, array[a1..h8, HistoryArray]]

func newHistoryTable*(): HistoryTable =
  # allocating this on the heap, as it is too big for the stack
  # result.counterTable = new array[pawn..king, array[a1..h8, HistoryArray]]
  discard # TODO

func halve(table: var HistoryArray, color: Color) =
  for sq1 in a1 .. g7:
    for sq2 in a1 .. g7:
      table[color][sq1][sq2] /= historyTableShrinkDiv()

func update*(
    historyTable: var HistoryTable,
    move: Move,
    color: Color,
    depth: Ply,
    raisedAlpha: bool,
) =
  if move == nullMove:
    return

  doAssert move.source != noSquare and move.target != noSquare

  func add(table: var HistoryArray, color: Color, move: Move, addition: float) =
    template entry(): auto =
      table[color][move.source][move.target]

    entry = clamp(
      entry + addition, -maxHistoryTableValue().float, maxHistoryTableValue().float
    )
    if entry.abs >= maxHistoryTableValue().float:
      table.halve(color)

  let addition =
    (if raisedAlpha: 1.0 else: -1.0 / historyTableBadMoveDivider()) * depth.float ^ 2

  historyTable.table.add(color, move, addition)

  # if previous.moved in pawn .. king and previous.target in a1 .. h8:
  #   historyTable.counterTable[][previous.moved][previous.target].add(
  #     color, move, addition * historyTableCounterMul()
  #   )

func get*(historyTable: HistoryTable, move: Move, color: Color): -1.0 .. 1.0 =
  if move != nullMove:
    doAssert move.source != noSquare and move.target != noSquare
    var sum = historyTable.table[color][move.source][move.target]
    return sum / maxHistoryTableValue().float

  # if previous.moved in pawn .. king and previous.target in a1 .. h8:
  #   sum +=
  #     historyTable.counterTable[][previous.moved][previous.target][color][move.moved][
  #       move.target
  #     ]

  # sum / (2 * maxHistoryTableValue().float)
