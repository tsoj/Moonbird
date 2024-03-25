import position, movegen, utils

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

# TODO
# func asciiColorString(color: Color): string =
#   case color
#   of red: "o"
#   of blue: "x"
#   of blocked: "-"
#   else: " "

# func beatifulColorString(color: Color): string =
#   case color
#   of red: "🏶"
#   of blue: "♠"
#   of blocked: "🞓"
#   else: " "


func fen*(position: Position): string =
  for rank in countdown(6, 0):
    for file in 0 .. 6:
      let square = (rank * 7 + file).Square

      result &= (
        case position[square]
        of red: "o"
        of blue: "x"
        of blocked: "-"
        else: "1"
      )

    if rank != 0:
      result &= "/"

  for i in countdown(7, 2):
    result = result.replace(repeat("1", i), $i)

  result &= (if position.us == red: " o " else: " x ")
  result &= $position.halfmoveClock & " " & $(position.halfmovesPlayed div 2)

func printPosition*(stream: File or Stream, position: Position) =
  stream.printBoardString(
    proc(square: Square): auto =
      let color = position[square]
      if color != noColor:
        return some(
          case color
          of red:
            ("🏶", fgRed)
          of blue:
            ("♠", fgBlue)
          of blocked:
            ("🞓", fgDefault)
          else:
            ("?", fgDefault)
        )
      none (string, ForegroundColor)
  )

  var fenWords = position.fen.splitWhitespace

  {.cast(noSideEffect).}:
    for i in 1 ..< fenWords.len:
      stream.write fenWords[i], " "
    stream.write "\n"
    when stream is File:
      stream.flushFile
    elif stream is Stream:
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
    fenWords[0] = fenWords[0].replace($i, repeat("1", i))

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
  of "b", "x", "blue", "black":
    result.us = blue
  of "r", "w", "o", "red", "white":
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

const startpos* = "x5o/7/7/7/7/7/o5x x 0 1".toPosition

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
