import types, position, bitboard

type EvaluationFunction* = proc(position: Position): Value {.noSideEffect.}

func evaluate*(position: Position): Value =
  Value(position[position.us].countSetBits - position[position.enemy].countSetBits)
