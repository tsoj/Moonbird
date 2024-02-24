
import
    position,
    positionUtils,
    move,
    movegen

func perft*(position: Position, depth: int, printRootMoveNodes = false): int64 =

    if depth <= 0:
        return 1

    if position[red] == 0 or position[blue] == 0 or (not position.occupancy) == 0 or
    position.halfmoveClock >= 100 or (position.moves() == @[nullMove] and position.doMove(nullMove).moves() == @[nullMove]):
        return 0

    let moves = position.moves()
    for move in moves:
        let
            newPosition = position.doMove(move)
            nodes = newPosition.perft(depth - 1)
        
        if printRootMoveNodes:
            debugEcho "    ", move, " ", nodes, " ", newPosition.fen
        result += nodes

var p = "x5o/7/7/7/7/7/o5x x 0 1".toPosition
echo p.perft(0)


const perftPositions = [
    ("7/7/7/7/7/7/7 x 0 1", @[1, 0, 0, 0, 0]),
    ("7/7/7/7/7/7/7 o 0 1", @[1, 0, 0, 0, 0]),
    ("x5o/7/7/7/7/7/o5x x 0 1", @[1, 16, 256, 6460, 155888, 4752668]),
    ("x5o/7/7/7/7/7/o5x o 0 1", @[1, 16, 256, 6460, 155888, 4752668]),
    ("x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1", @[1, 14, 196, 4184, 86528, 2266352]),
    ("x5o/7/2-1-2/7/2-1-2/7/o5x o 0 1", @[1, 14, 196, 4184, 86528, 2266352]),
    ("x5o/7/2-1-2/3-3/2-1-2/7/o5x x 0 1", @[1, 14, 196, 4100, 83104, 2114588]),
    ("x5o/7/2-1-2/3-3/2-1-2/7/o5x o 0 1", @[1, 14, 196, 4100, 83104, 2114588]),
    ("x5o/7/3-3/2-1-2/3-3/7/o5x x 0 1", @[1, 16, 256, 5948, 133264, 3639856]),
    ("x5o/7/3-3/2-1-2/3-3/7/o5x o 0 1", @[1, 16, 256, 5948, 133264, 3639856]),
    ("7/7/7/7/ooooooo/ooooooo/xxxxxxx x 0 1", @[1, 1, 75, 249, 14270, 452980]),
    ("7/7/7/7/ooooooo/ooooooo/xxxxxxx o 0 1", @[1, 75, 249, 14270, 452980]),
    ("7/7/7/7/xxxxxxx/xxxxxxx/ooooooo x 0 1", @[1, 75, 249, 14270, 452980]),
    ("7/7/7/7/xxxxxxx/xxxxxxx/ooooooo o 0 1", @[1, 1, 75, 249, 14270, 452980]),
    ("7/7/7/2x1o2/7/7/7 x 0 1", @[1, 23, 419, 7887, 168317, 4266992]),
    ("7/7/7/2x1o2/7/7/7 o 0 1", @[1, 23, 419, 7887, 168317, 4266992]),
    ("x5o/7/7/7/7/7/o5x x 100 1", @[1, 0, 0, 0, 0]),
    ("x5o/7/7/7/7/7/o5x o 100 1", @[1, 0, 0, 0, 0]),
    ("7/7/7/7/-------/-------/x5o x 0 1", @[1, 2, 4, 13, 30, 73, 174]),
    ("7/7/7/7/-------/-------/x5o o 0 1", @[1, 2, 4, 13, 30, 73, 174]),
]

for (fen, targetNodes) in perftPositions:
    let position = fen.toPosition
    echo position.fen
    for i, nodesTarget in targetNodes:
        let nodes = position.perft(i)
        echo nodes
        if nodesTarget != nodes:
            echo "ERROR: Should be ", nodesTarget, " but is ", nodes
            echo position

