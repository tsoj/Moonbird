import
    move,
    position,
    bitboard

export move, position


func moves*(position: Position): seq[Move] =
    var doneTargets = 0.Bitboard

    for source in position[position.us]:
        for target in source.attack(2) and not position.occupancy:
            result.add Move(source: source, target: target)
        
        for target in source.attack(1) and not (position.occupancy or doneTargets):
            result.add Move(source: source, target: target)
            doneTargets |= target.toBitboard
    
    if result.len == 0:
        result.add nullMove

func doMove*(position: Position, move: Move): Position =
    
    let
        us = position.us
        enemy = position.enemy
        source = move.source
        target = move.target
        
    result = position
    result.halfmoveClock += 1
    result.halfmovesPlayed += 1

    if move != nullMove:
        assert source != noSquare and target != noSquare
        
        if (source.attack(2) and target.toBitboard) != 0:
            result.movePiece(us, source, target)
        else:
            result.addPiece(us, target)
            result.halfmoveClock = 0

        result[us] |= result[enemy] and target.mask(1)
        result[enemy] &= not target.mask(1)

    result.us = enemy
