import
    types,
    bitboard

export types


type Move* = object
    source*, target*: Square

const
    noMove* = Move(source: noSquare, target: noSquare)
    nullMove* = Move(source: a1, target: noSquare)

static: doAssert noMove != nullMove


func isDouble*(move: Move): bool =
    (move.source.attack(2) and move.target.toBitboard) != 0

func isSingle*(move: Move): bool =
    (move.source.attack(1) and move.target.toBitboard) != 0

func `$`*(move: Move): string =
    if move == noMove:
        "illegalMove"
    elif move == nullMove:
        "0000"
    elif move.isDouble:
        $move.source & $move.target
    else:
        $move.target

func toMove*(s: string): Move =
    if s.len != 4:
        raise newException(ValueError, "Unrecognized move string: \"" & s & "\"")
    Move(source: s[0..1].toSquare, target: s[2..3].toSquare)
