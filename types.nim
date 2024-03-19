import std/[
    strutils
]

type
    Square* = enum
        a1, b1, c1, d1, e1, f1, g1,
        a2, b2, c2, d2, e2, f2, g2,
        a3, b3, c3, d3, e3, f3, g3,
        a4, b4, c4, d4, e4, f4, g4,
        a5, b5, c5, d5, e5, f5, g5,
        a6, b6, c6, d6, e6, f6, g6,
        a7, b7, c7, d7, e7, f7, g7
        noSquare
    Color* = enum
        red, blue, blocked, noColor
    Value* = int32
    Ply* = 0.int8 .. int8.high
    NodeType* = enum
        pvNode,
        allNode,
        cutNode
    ZobristKey* = uint64
    

template isLeftEdge*(square: Square): bool =
    square.int8 mod 7 == 0
template isRightEdge*(square: Square): bool =
    square.int8 mod 7 == 6
template isUpperEdge*(square: Square): bool =
    square >= a7
template isLowerEdge*(square: Square): bool =
    square <= g1
template isEdge*(square: Square): bool =
    square.isLeftEdge or square.isRightEdge or square.isUpperEdge or square.isLowerEdge


template up*(square: Square): Square = (square.int8 + 7).Square
template down*(square: Square): Square = (square.int8 - 7).Square
template left*(square: Square): Square = (square.int8 - 1).Square
template right*(square: Square): Square = (square.int8 + 1).Square
template up*(square: Square, color: Color): Square =
    if color == white:
        square.up
    else:
        square.down

func goUp*(square: var Square): bool =
    if square.isUpperEdge or square == noSquare: return false
    square = square.up
    true
func goDown*(square: var Square): bool =
    if square.isLowerEdge or square == noSquare: return false
    square = square.down
    true
func goLeft*(square: var Square): bool =
    if square.isLeftEdge or square == noSquare: return false
    square = square.left
    true
func goRight*(square: var Square): bool =
    if square.isRightEdge or square == noSquare: return false
    square = square.right
    true
func goNothing*(square: var Square): bool =
    true

func opposite*(color: Color): Color =
    (color.uint8 xor 1).Color


func toSquare*(s: string): Square =
    parseEnum[Square](s)

func toColor*(s: string or char): Color =
    case ($s).toLowerAscii.strip:
    of "x", "b", "blue", "black":
        blue
    of "o", "r", "red", "white":
        red
    of "-":
        blocked
    of "", ".", "_":
        noColor
    else:
        raise newException(ValueError, "Unrecognized color string: \"" & s & "\"")

func clampToType*[In, Out](x: In, OutType: typedesc[Out]): Out =
    x.clamp(OutType.low.In, OutType.high.In).Out

func `-`*(a: Ply, b: SomeNumber or Ply): Ply =
    clampToType(a.BiggestInt - b.BiggestInt, Ply)
func `-`*(a: SomeNumber, b: Ply): Ply =
    clampToType(a.BiggestInt - b.BiggestInt, Ply)

func `+`*(a: Ply, b: SomeNumber or Ply): Ply =
    clampToType(a.BiggestInt + b.BiggestInt, Ply)
func `+`*(a: SomeNumber, b: Ply): Ply =
    clampToType(a.BiggestInt + b.BiggestInt, Ply)

func `-=`*(a: var Ply, b: Ply or SomeNumber) =
    a = a - b
func `+=`*(a: var Ply, b: Ply or SomeNumber) =
    a = a + b

const valueInfinity* = min(-(int16.low.Value), int16.high.Value)
static: doAssert -valueInfinity <= valueInfinity
const baseValueWin = valueInfinity - Ply.high.Value - 1.Value

func valueWin*(height: Ply): Value =
    baseValueWin + (Ply.high - height).Value
static: doAssert Ply.low.valueWin < valueInfinity
static: doAssert Ply.high.valueWin >= baseValueWin
