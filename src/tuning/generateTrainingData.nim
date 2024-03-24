import
  ../position,
  ../hashTable,
  ../evaluation,
  ../positionUtils,
  ../game

import taskpools

import std/[os, random, locks, atomics, streams, strformat, times, cpuinfo]

const
  openingFilename = "res/startpos.txt"
  targetTrainingSamples = 50_000_000
  randRatio = 0.0005
  sampleGameSearchNodes = 6_000
  minNumStartPositions = 1000
  # We need a minimum number of start positions, as otherwise it's difficult to adjust the number
  # of randomly selected leaves to get to the target number of training samples

let
  startDate = now().format("yyyy-MM-dd-HH-mm-ss")
  outDir = "res/data/"
  outputFilename = fmt"{outDir}trainingSet_{startDate}.bin"

discard existsOrCreateDir outDir
doAssert not fileExists outDir, "Can't overwrite existing file"

func isValidSamplePosition(position: Position): bool =
  position.gameStatus == running and position.halfmoveClock < 50
    # otherwise the position is probably just shuffling

proc playGame(startPos: Position, hashTable: ref HashTable): float =
  var game = newGame(
    startingPosition = startPos, maxNodes = sampleGameSearchNodes, hashTable = hashTable
  )
  let gameResult = game.playGame # (printInfo = true)
  doAssert gameResult in 0.0 .. 1.0
  return gameResult

let
  openingLines = block:
    let f = open(openingFilename)
    var
      lines: seq[string]
      line: string
    while f.readLine(line):
      lines.add line
    while lines.len < minNumStartPositions:
      lines = lines & lines
    var rg = initRand()
    rg.shuffle(lines)
    lines
  expectedNumberSamplesPerOpening = targetTrainingSamples div openingLines.len

var
  outFileStream = newFileStream(outputFilename, fmWrite)
  outFileMutex = Lock()
  openingSearchNodes: Atomic[float]
initLock outFileMutex

const expectedNumPliesPerGame = 120
# This is just a first very rough guess:
openingSearchNodes.store(
  targetTrainingSamples.float /
    (expectedNumPliesPerGame.float * randRatio * openingLines.len.float)
)

echo fmt"{openingSearchNodes.load = }"
echo fmt"{openingLines.len = }"
echo fmt"{expectedNumberSamplesPerOpening = }"

# doAssert false

proc findStartPositionsAndPlay(startPos: Position, stringIndex: string) =
  try:
    var
      rg = initRand()
      numSamples = 0

    {.warning[ProveInit]: off.}:
      var sampleGameHashTable = new HashTable
    sampleGameHashTable[] = newHashTable(len = sampleGameSearchNodes * 2)

    func specialEval(position: Position): Value =
      result = position.evaluate
      {.cast(noSideEffect).}:
        if rg.rand(1.0) <= randRatio and position.isValidSamplePosition:
          let gameResult = position.playGame(sampleGameHashTable)
          numSamples += 1

          withLock outFileMutex:
            if (numSamples mod 10_000) == 0:
              echo "numSamples: ", numSamples

            outFileStream.writePosition position
            outFileStream.write gameResult
            outFileStream.flush

    var game = newGame(
      startingPosition = startPos,
      maxNodes = openingSearchNodes.load.int,
      hashTable = nil,
      evaluation = specialEval,
    )
    discard game.playGame

    echo fmt"Finished opening {stringIndex}, {numSamples = }"

    openingSearchNodes.store openingSearchNodes.load *
      clamp(expectedNumberSamplesPerOpening.float / numSamples.float, 0.95, 1.05)

    echo fmt"{openingSearchNodes.load = }"
  except Exception:
    echo "ERROR: EXCEPTION: ", getCurrentExceptionMsg()
    quit(QuitFailure)

let startTime = now()

var threadpool = Taskpool.new(numThreads = 30) #countProcessors() div 2)#

for i, fen in openingLines:
  let
    position = fen.toPosition
    stringIndex = fmt"{i+1}/{openingLines.len}"

  threadpool.spawn position.findStartPositionsAndPlay(stringIndex)
  # position.findStartPositionsAndPlay(stringIndex)

threadpool.syncAll()

echo "Total time: ", now() - startTime
