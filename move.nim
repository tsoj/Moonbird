import types, bitboard

export types

type Move* = object
  source*, target*: Square

const
  noMove* = Move(source: noSquare, target: noSquare)
  nullMove* = Move(source: a1, target: noSquare)

static:
  doAssert noMove != nullMove

func isSingle*(move: Move): bool =
  move != noMove and move != nullMove and move.source == move.target

func isDouble*(move: Move): bool =
  move != noMove and move != nullMove and not move.isSingle

func `$`*(move: Move): string =
  if move == noMove:
    "NONE"
  elif move == nullMove:
    "0000"
  elif move.isDouble:
    $move.source & $move.target
  else:
    $move.target

func toMove*(s: string): Move =
  if s == $nullMove:
    nullMove
  elif s == $noMove:
    noMove
  elif s.len == 4:
    Move(source: s[0 .. 1].toSquare, target: s[2 .. 3].toSquare)
  elif s.len == 2:
    Move(source: s.toSquare, target: s.toSquare)
  else:
    raise newException(ValueError, "Unrecognized move string: \"" & s & "\"")
