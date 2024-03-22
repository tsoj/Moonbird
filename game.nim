import
    position,
    positionUtils,
    movegen,
    timeManagedSearch,
    evalution,
    hashTable

import std/[
    tables
]

type
    Game* {.requiresInit.} = object
        hashTable: ref HashTable
        positionHistory: seq[Position]
        evals: Table[Position, Value] = initTable[Position, Value]()
        maxNodes: int
        adjudicateEasyFill: bool
        adjudicateThreefoldRepetition: bool
        evaluation: EvaluationFunction
    GameStatus* = enum
        running, fiftyMoveRule, threefoldRepetition, winRed, winBlue, draw


func gameStatus(position: Position): GameStatus =
    if position[red] == 0:
        winBlue

    elif position[blue] == 0:
        winRed

    elif position.halfmoveClock >= 100:
        fiftyMoveRule

    elif position.moves.len == 0 and position.doMove(nullMove).moves.len == 0:
        let
            numBlue = position[blue].countSetBits
            numRed = position[red].countSetBits

        if numRed > numBlue:
            winRed
        elif numRed < numBlue:
            winBlue
        else:
            draw
    else:
        running



func canAdjudicateEasyfill(position: Position): bool =
    











    const auto our_reach = (pos.get_us().singles() | pos.get_us().doubles());
    const auto them_stuck = our_reach & pos.get_them();
    const auto them_free = pos.get_them() ^ them_stuck;
    const auto both_reach = pos.get_both().singles() | pos.get_both().doubles();

    // Is the game already over?
    if (pos.is_gameover()) {
        return false;
    }

    // Can we still move?
    if (our_reach & pos.get_empty()) {
        return false;
    }

    // Can they move without releasing us?
    if (!((pos.get_them().singles() | them_free.doubles()) & pos.get_empty())) {
        return false;
    }

    // Pretend they get everything, is it enough?
    if (pos.get_us().count() > pos.get_them().count() + pos.get_empty().count()) {
        return false;
    }

    const auto reachable = [&] {
        auto bb = (pos.get_them().singles() | them_free.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        bb |= (bb.singles() | bb.doubles()) & pos.get_empty();
        return bb;
    }();

    const auto reservoirs = (pos.get_empty() | pos.get_them()).singles() & (pos.get_empty() | pos.get_them());
    if (!(reachable & reservoirs)) {
        return false;
    }

    if ((reachable & reservoirs) && pos.get_them().count() + reachable.count() < pos.get_us().count()) {
        return false;
    }

    return true;
}

