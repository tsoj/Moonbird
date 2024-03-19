
import
    position,
    positionUtils,
    move,
    movegen,
    moveIterator

import std/[
    options
]

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

func zobristPerft*(position: Position, depth: int): Option[(Position, Move)] =
    if depth <= 0:
        return

    for move in position.moveIterator():
        let newPosition = position.doMove(move)
        
        if newPosition.calculateZobristKey != newPosition.zobristKey:

            debugEcho position
            debugEcho position.zobristKey
            debugEcho move
            debugEcho newPosition
            debugEcho newPosition.zobristKey
            debugEcho newPosition.calculateZobristKey
            assert false

            return some (position, move)

        let r = newPosition.zobristPerft(depth - 1)
        if r.isSome:
            return r

