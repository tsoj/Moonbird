import types

export types


type Move* = object
    source*, target*: Square

const
    noMove* = Move(source: noSquare, target: noSquare)
    nullMove* = Move(source: a1, target: noSquare)

static: doAssert noMove != nullMove

func `$`*(move: Move): string =
    $move.source & $move.target

func parseMove*(s: string): Move =
    if s.len != 4:
        raise newException(ValueError, "Unrecognized move string: \"" & s & "\"")
    Move(source: s[0..1].parseSquare, target: s[2..3].parseSquare)