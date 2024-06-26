import
  ../src/positionUtils,
  ../src/perft,
  ../src/move,
  ../src/movegen,
  ../src/version,
  ../src/game,
  ../src/startPositions

import std/[strformat, terminal, options, random, streams]

const someFens = [
  "x6/7/-------/-------/-------/7/6o x 0 1", "x5o/7/7/7/7/7/o5x x 0 1",
  "x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1", "x5o/7/3-3/2-1-2/3-3/7/o5x x 0 1",
  "7/7/7/7/7/7/7 x 0 1", "7/7/7/7/7/7/7 o 0 1", "7/7/7/7/7/7/7 x 100 1",
  "7/7/7/7/7/7/7 o 100 1", "7/7/7/7/7/7/7 x 0 100", "7/7/7/7/7/7/7 o 0 100",
  "7/7/7/7/7/7/7 x 100 200", "7/7/7/7/7/7/7 o 100 200", "x5o/7/7/7/7/7/o5x x",
  "x5o/7/7/7/7/7/o5x x 0", "x5o/7/2-1-2/7/2-1-2/7/o5x x",
  "x5o/7/2-1-2/7/2-1-2/7/o5x x 0", "7/7/7/7/7/7/7 x 0 1", "7/7/7/7/7/7/7 o 0 1",
  "x5o/7/7/7/7/7/o5x x 0 1", "x5o/7/7/7/7/7/o5x o 0 1",
  "x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1", "x5o/7/2-1-2/7/2-1-2/7/o5x o 0 1",
  "x5o/7/2-1-2/3-3/2-1-2/7/o5x x 0 1", "x5o/7/2-1-2/3-3/2-1-2/7/o5x o 0 1",
  "x5o/7/3-3/2-1-2/3-3/7/o5x x 0 1", "x5o/7/3-3/2-1-2/3-3/7/o5x o 0 1",
  "7/7/7/7/ooooooo/ooooooo/xxxxxxx x 0 1", "7/7/7/7/ooooooo/ooooooo/xxxxxxx o 0 1",
  "7/7/7/7/xxxxxxx/xxxxxxx/ooooooo x 0 1", "7/7/7/7/xxxxxxx/xxxxxxx/ooooooo o 0 1",
  "7/7/7/2x1o2/7/7/7 x 0 1", "7/7/7/2x1o2/7/7/7 o 0 1", "x5o/7/7/7/7/7/o5x x 100 1",
  "x5o/7/7/7/7/7/o5x o 100 1", "7/7/7/7/-------/-------/x5o x 0 1",
  "7/7/7/7/-------/-------/x5o o 0 1", "xxxxxxx/-------/-------/o6/7/7/7 x 0 1",
  "xxxxxxx/ooooooo/ooooooo/7/7/7/7 x 0 1",
]

const perftPositions = [
  ("7/7/7/7/7/7/7 x 0 1", @[1, 0, 0, 0, 0]),
  ("7/7/7/7/7/7/7 o 0 1", @[1, 0, 0, 0, 0]),
  ("x5o/7/7/7/7/7/o5x x 0 1", @[1, 16, 256, 6460, 155888, 4752668]),
  ("x5o/7/7/7/7/7/o5x o 0 1", @[1, 16, 256, 6460, 155888, 4752668]),
  ("x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1", @[1, 14, 196, 4184, 86528, 2266352]),
  ("x5o/7/2-1-2/7/2-1-2/7/o5x o 0 1", @[1, 14, 196, 4184, 86528, 2266352]),
  ("x5o/7/2-1-2/3-3/2-1-2/7/o5x x 0 1", @[1, 14, 196, 4100, 83104, 2114588]),
  ("x5o/7/2-1-2/3-3/2-1-2/7/o5x o 0 1", @[1, 14, 196, 4100, 83104, 2114588]),
  ("x5o/7/3-3/2-1-2/3-3/7/o5x x 0 1", @[1, 16, 256, 5948, 133264, 3639856]),
  ("x5o/7/3-3/2-1-2/3-3/7/o5x o 0 1", @[1, 16, 256, 5948, 133264, 3639856]),
  ("7/7/7/7/ooooooo/ooooooo/xxxxxxx x 0 1", @[1, 1, 75, 249, 14270, 452980]),
  ("7/7/7/7/ooooooo/ooooooo/xxxxxxx o 0 1", @[1, 75, 249, 14270, 452980]),
  ("7/7/7/7/xxxxxxx/xxxxxxx/ooooooo x 0 1", @[1, 75, 249, 14270, 452980]),
  ("7/7/7/7/xxxxxxx/xxxxxxx/ooooooo o 0 1", @[1, 1, 75, 249, 14270, 452980]),
  ("7/7/7/2x1o2/7/7/7 x 0 1", @[1, 23, 419, 7887, 168317, 4266992]),
  ("7/7/7/2x1o2/7/7/7 o 0 1", @[1, 23, 419, 7887, 168317, 4266992]),
  ("x5o/7/7/7/7/7/o5x x 100 1", @[1, 0, 0, 0, 0]),
  ("x5o/7/7/7/7/7/o5x o 100 1", @[1, 0, 0, 0, 0]),
  ("7/7/7/7/-------/-------/x5o x 0 1", @[1, 2, 4, 13, 30, 73, 174]),
  ("7/7/7/7/-------/-------/x5o o 0 1", @[1, 2, 4, 13, 30, 73, 174]),
  ("xxxxxxx/-------/-------/o6/7/7/7 x 0 1", @[1, 1, 8, 8, 127, 127, 2626, 2626]),
  ("xxxxxxx/ooooooo/ooooooo/7/7/7/7 x 0 1", @[1, 1, 75, 249, 14270, 452980]),
]

proc testFen(): Option[string] =
  for fen in someFens:
    if fen != fen.toPosition.fen[0 ..< fen.len]:
      return some fmt"{fen} != {fen.toPosition.fen}"

proc testPerft(): Option[string] =
  for (fen, targetNodes) in perftPositions:
    let position = fen.toPosition
    for i, nodesTarget in targetNodes:
      let nodes = position.perft(i)
      if nodesTarget != nodes:
        return some &"Perft to depth {i} for \"{fen}\" should be {nodesTarget} but is {nodes}"

func zobristPerft(position: Position, depth: int): Option[(Position, Move)] =
  if depth <= 0:
    return

  for move in position.moves:
    let newPosition = position.doMove(move)

    if newPosition.calculateZobristKey != newPosition.zobristKey:
      return some (position, move)

    let r = newPosition.zobristPerft(depth - 1)
    if r.isSome:
      return r

proc testZobristKeys(): Option[string] =
  for fen1 in someFens:
    for fen2 in someFens:
      var
        p1 = fen1.toPosition
        p2 = fen2.toPosition
      p1.halfmoveClock = p2.halfmoveClock
      p1.halfmovesPlayed = p2.halfmovesPlayed
      if p1.fen != p2.fen and p1.zobristKey == p2.zobristKey:
        return some &"Zobrist key for both \"{fen1}\" and \"{fen2}\" is the same ({fen1.toPosition.zobristKey})"

  for (fen, targetNodes) in perftPositions:
    let position = fen.toPosition
    for i, nodesTarget in targetNodes:
      let r = position.zobristPerft(i)
      if r.isSome:
        let (position, move) = r.get
        return some &"Incremental zobrist key calculation failed for position \"{position.fen}\" with move {move}"

proc legalMovePerft(position: Position, depth: int): Option[(Position, Move)] =
  if depth <= 0:
    return

  let legalMoves = position.moves

  for move in position.moves:
    let newPosition = position.doMove(move)

    let fakeMove = Move(source: rand(a1 .. noSquare), target: rand(a1 .. noSquare))
    if (fakeMove in legalMoves) != fakeMove.isLegal(position):
      return some (position, fakeMove)

    let r = newPosition.legalMovePerft(depth - 1)
    if r.isSome:
      return r

proc testLegalMoveTest(): Option[string] =
  for (fen, targetNodes) in perftPositions:
    let position = fen.toPosition
    for i, nodesTarget in targetNodes:
      let r = position.legalMovePerft(i)
      if r.isSome:
        let (position, move) = r.get
        return some &"Legal move test failed for position \"{position.fen}\" with move {move}"

proc playGames(): Option[string] =
  for fen in someFens:
    try:
      var game = newGame(fen.toPosition, maxNodes = 2_000, adjudicateThreefold = true)
      discard game.playGame()
    except CatchableError:
      return some &"Encountered error while playing a game from start position \"{fen}\": {getCurrentExceptionMsg()}"

proc positionStreams(): Option[string] =
  for fen in someFens:
    let position = fen.toPosition

    var strm = newStringStream()
    strm.writePosition position
    strm.setPosition(0)
    let position2 = strm.readPosition
    strm.close()
    if position2 != position:
      return some &"Failed to convert to binary stream and back for \"{fen}\""

proc blockerConfigurations(): Option[string] =
  let blockerConfigurations16 = getBlockerConfigurations(16)
  if blockerConfigurations16.len != 2868:
    return some &"Failed to find the right number of blocker configurations: Is {blockerConfigurations16.len}, but should be 2868"

proc positionTransforms(): Option[string] =
  for fen in someFens:
    for i, transformSeq in [
      @[swapColors, swapColors],
      @[mirrorVertically, mirrorVertically],
      @[mirrorHorizontally, mirrorHorizontally],
      @[rotate90, rotate270],
      @[rotate180, rotate180],
      @[rotate180, rotate90, rotate90],
      @[
        swapColors, mirrorHorizontally, rotate90, swapColors, mirrorVertically,
        rotate270,
      ],
    ]:
      let position = fen.toPosition
      var transformed = position
      for transform in transformSeq:
        transformed = transformed.transform
      if position != transformed:
        return some &"Failed position transform sequence number {i} for position {fen}"

proc runTests*(): bool =
  const tests = [
    (testFen, "FEN parsing"),
    (positionTransforms, "Position transform"),
    (positionStreams, "Binary position streams"),
    (testLegalMoveTest, "Legal move check"),
    (testPerft, "Move generation"),
    (testZobristKeys, "Zobrist key calculation"),
    (playGames, "Playing games"),
    (blockerConfigurations, "Blocker configurations"),
  ]

  var failedTests = 0

  for (test, testDescription) in tests:
    stdout.styledWrite fgWhite, testDescription, styleDim, " ... "
    stdout.flushFile
    let r = test()
    if r.isNone:
      stdout.styledWriteLine fgGreen, styleBright, "Done"
    else:
      stdout.styledWriteLine fgRed, styleBright, "Failed: ", resetStyle, r.get
      failedTests += 1

  if failedTests == 0:
    styledEcho fgGreen, styleBright, "Finished all tests successfully"
    true
  else:
    styledEcho fgRed, styleBright, fmt"Failed {failedTests} of {tests.len} tests"
    false

when isMainModule:
  echo "Version ", versionOrId()

  if not runTests():
    quit(QuitFailure)
