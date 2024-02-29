
import
    position,
    positionUtils,
    move,
    movegen,
    moveIterator

func perft*(position: Position, depth: int, printRootMoveNodes = false): int64 =

    if depth <= 0:
        return 1

    if position[red] == 0 or position[blue] == 0 or (not position.occupancy) == 0 or
    position.halfmoveClock >= 100 or (position.moves() == @[nullMove] and position.doMove(nullMove).moves() == @[nullMove]):
        return 0

    for move in position.moveIterator():
        let
            newPosition = position.doMove(move)
            nodes = newPosition.perft(depth - 1)
        
        if printRootMoveNodes:
            debugEcho "    ", move, " ", nodes, " ", newPosition.fen
        result += nodes

