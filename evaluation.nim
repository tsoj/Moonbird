import
    types,
    position,
    bitboard


func evaluate*(position: Position): Value =
    Value(position[position.us].countSetBits - position[position.enemy].countSetBits)