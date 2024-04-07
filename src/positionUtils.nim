import position, movegen, utils

import std/[strformat]

export position

type GameStatus* = enum
  running
  fiftyMoveRule
  winRed
  winBlue
  draw

func gameStatus*(position: Position): GameStatus =
  if position[red] == 0:
    winBlue
  elif position[blue] == 0:
    winRed
  elif position.halfmoveClock >= 100:
    fiftyMoveRule
  elif ((position[red] or position[blue]).singles.singles and not position.occupancy) ==
      0:
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

const
  fenStrings = [red: "x", blue: "o", blocked: "-", noColor: "1"]
  prettyStrings = [red: "🏶", blue: "♠", blocked: "🞓", noColor: "?"]
  colorColor = [red: fgRed, blue: fgBlue, blocked: fgDefault, noColor: fgDefault]

func toColor(s: string or char): Color =
  case ($s).toLowerAscii.strip
  of fenStrings[red], "red", "b", "black":
    red
  of fenStrings[blue], "blue", "w", "white":
    blue
  of fenStrings[blocked]:
    blocked
  of fenStrings[noColor], "", ".", "_":
    noColor
  else:
    raise newException(ValueError, "Unrecognized color string: \"" & s & "\"")

func fen*(position: Position): string =
  for rank in countdown(6, 0):
    for file in 0 .. 6:
      let square = (rank * 7 + file).Square

      result &= fenStrings[position[square]]

    if rank != 0:
      result &= "/"

  for i in countdown(7, 2):
    result = result.replace(repeat(fenStrings[noColor], i), $i)

  result &=
    fmt" {fenStrings[position.us]} {position.halfmoveClock} {(position.halfmovesPlayed div 2)}"

func printPosition*(stream: File or Stream, position: Position) =
  stream.printBoardString(
    proc(square: Square): auto =
      let color = position[square]
      if color != noColor:
        return some (prettyStrings[color], colorColor[color])
      none (string, ForegroundColor)
  )

  {.cast(noSideEffect).}:
    when stream is File:
      stream.styledWrite resetStyle, colorColor[position.us], prettyStrings[position.us]
      stream.write &" {position.halfmoveClock} {position.halfmovesPlayed}\n"
      stream.flushFile
    elif stream is Stream:
      stream.write &"{prettyStrings[position.us]} {position.halfmoveClock} {position.halfmovesPlayed}\n"
      stream.flush
    else:
      doAssert false

func `$`*(position: Position): string =
  {.cast(noSideEffect).}:
    var strm = newStringStream()
    strm.printPosition(position = position)
    strm.setPosition(0)
    result = strm.readAll()
    strm.close()

proc toPosition*(fen: string, suppressWarnings = false): Position =
  var fenWords = fen.splitWhitespace()
  if fenWords.len < 2:
    raise newException(
      ValueError, "FEN must have at least 2 words (piece location and side to move)"
    )
  if fenWords.len > 4 and not suppressWarnings:
    echo "WARNING: FEN shouldn't have more than 4 words"

  while fenWords.len < 4:
    fenWords.add("0")

  for i in 2 .. 7:
    fenWords[0] = fenWords[0].replace($i, repeat(fenStrings[noColor], i))

  doAssert fenWords.len >= 4
  let
    piecePlacement = fenWords[0]
    activeColor = fenWords[1]
    halfmoveClock = fenWords[2]
    fullmoveNumber = fenWords[3]

  var squareList = block:
    var squareList: seq[Square]
    for y in 0 .. 6:
      for x in countdown(6, 0):
        squareList.add Square(y * 7 + x)
    squareList

  for pieceChar in piecePlacement:
    if squareList.len == 0:
      raise
        newException(ValueError, "FEN is not correctly formatted (too many squares)")

    case pieceChar
    of '/':
      # we don't need to do anything, except check if the / is at the right place
      if not squareList[^1].isLeftEdge:
        raise newException(ValueError, "FEN is not correctly formatted (misplaced '/')")
    of '1':
      discard squareList.pop
    of '0':
      if not suppressWarnings:
        echo "WARNING: '0' in FEN piece placement data is not official notation"
    else:
      doAssert pieceChar notin ['2', '3', '4', '5', '6', '7']
      try:
        let sq = squareList.pop
        result.addPiece(pieceChar.toColor, sq)
      except ValueError:
        raise newException(
          ValueError,
          "FEN piece placement is not correctly formatted: " & getCurrentExceptionMsg(),
        )

  if squareList.len != 0:
    raise newException(ValueError, "FEN is not correctly formatted (too few squares)")

  # active color
  case activeColor.toLowerAscii
  of fenStrings[blue], "blue", "b", "black":
    result.us = blue
  of fenStrings[red], "red", "w", "white":
    result.us = red
  else:
    raise newException(
      ValueError, "FEN active color notation does not exist: " & activeColor
    )

  # halfmove clock and fullmove number
  try:
    result.halfmoveClock = parseInt(halfmoveClock)
  except ValueError:
    raise newException(
      ValueError,
      "FEN halfmove clock is not correctly formatted: " & getCurrentExceptionMsg(),
    )

  try:
    result.halfmovesPlayed = parseInt(fullmoveNumber) * 2
  except ValueError:
    raise newException(
      ValueError,
      "FEN fullmove number is not correctly formatted: " & getCurrentExceptionMsg(),
    )

  result.zobristKey = result.calculateZobristKey

const startPos* = "x5o/7/7/7/7/7/o5x x 0 1".toPosition

proc writePosition*(stream: Stream, position: Position) =
  for b in position.pieces:
    stream.write b.uint64

  stream.write position.zobristKey.uint64
  stream.write position.us.uint8
  stream.write position.halfmovesPlayed.uint16
  stream.write position.halfmoveClock.uint16

proc readPosition*(stream: Stream): Position =
  for b in result.pieces.mitems:
    b = stream.readUint64.Bitboard

  result.zobristKey = stream.readUint64.ZobristKey
  result.us = stream.readUint8.Color
  result.halfmovesPlayed = stream.readUInt16.int
  result.halfmoveClock = stream.readUInt16.int

func swapColors*(position: Position, skipZobristKey: bool = false): Position =
  result = Position(
    pieces: [red: position[blue], blue: position[red], blocked: position[blocked]],
    us: position.enemy,
    halfmoveClock: position.halfmoveClock,
    halfmovesPlayed: position.halfmovesPlayed,
  )
  result.zobristKey = result.calculateZobristKey

template applyTransform(
    position: Position, skipZobristKey: bool, transform: untyped
): Position =
  var transformed = position
  for b in transformed.pieces.mitems:
    b = b.transform
  if not skipZobristKey:
    transformed.zobristKey = transformed.calculateZobristKey
  transformed

func mirrorVertically*(position: Position, skipZobristKey: bool = false): Position =
  position.applyTransform skipZobristKey, mirrorVertically

func mirrorHorizontally*(position: Position, skipZobristKey: bool = false): Position =
  position.applyTransform skipZobristKey, mirrorHorizontally

func rotate90*(position: Position, skipZobristKey: bool = false): Position =
  position.applyTransform skipZobristKey, rotate90

func rotate180*(position: Position, skipZobristKey: bool = false): Position =
  position.applyTransform skipZobristKey, rotate180

func rotate270*(position: Position, skipZobristKey: bool = false): Position =
  position.applyTransform skipZobristKey, rotate270

func nullTransform*(position: Position, skipZobristKey: bool = false): Position =
  position
