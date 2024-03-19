import
    move,
    position,
    bitboard

export move, position


func moves*(position: Position): seq[Move] =
    var doneTargets = 0.Bitboard

    for source in position[position.us]:
        for target in source.doubles and not position.occupancy:
            result.add Move(source: source, target: target)
        
        for target in source.singles and not (position.occupancy or doneTargets):
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
        
        if move.isDouble:
            result.movePiece(us, source, target)
            result.zobristKey ^= zobristKey(us, source)
        else:
            assert move.isSingle
            result.addPiece(us, target)
            result.halfmoveClock = 0

        let captured = result[enemy] and target.singles
        result[us] |= captured
        result[enemy] &= not captured

        for square in captured:            
            result.zobristKey ^= zobristKey(us, square)
            result.zobristKey ^= zobristKey(enemy, square)
        
        result.zobristKey ^= zobristKey(us, target)

    result.us = enemy
    
    result.zobristKey ^= red.ZobristKey xor blue.ZobristKey

func pieceDelta*(move: Move, position: Position): int =

    if move == nullMove: return 0

    assert move != noMove
    assert (position[position.us] and move.source.toBitboard) != 0, "This function should be used on the position before the move"
    
    if move.isSingle:
        result += 1

    result += 2 * countSetBits(position[position.enemy] and move.target.mask(1))

func isLegal*(move: Move, position: Position): bool =
    if move == noMove: false
    elif move == nullMove: true
    else:
        move.source != noSquare and move.target != noSquare and
        (position[position.us] and move.source.toBitboard) != 0 and
        (position.occupancy and move.target.toBitboard) == 0 and
        (move.target.toBitboard and (move.source.singles or move.source.doubles)) != 0

