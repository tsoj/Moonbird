import
    move,
    position,
    bitboard

export move, position


func genMoves(position: Position): seq[Move] =
    let occupancy = position[red] or position[blue] or position[blocked]
    var doneTargets = 0.Bitboard

    for source in position[position.us]:
        for target in source.attack(2) and not occupancy:
            result.add Move(source: source, target: target)
        
        for target in source.attack(1) and not (occupancy or doneTargets):
            result.add Move(source: source, target: target)
            doneTargets |= target.toBitboard
    
    if result.len == 0:
        result.add nullMove