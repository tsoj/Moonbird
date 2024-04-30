import
  ../position,
  ../hashTable,
  ../evaluation,
  ../positionUtils,
  ../game,
  ../version,
  ../startPositions,
  tuningUtils

import malebolgia

import std/[os, random, locks, atomics, streams, strformat, times, cpuinfo, strutils]

doAssert commandLineParams().len == 3,
  "Need the following parameters in that order (int, int, bool): sampleGameSearchNodes targetTrainingSamples useOnlyHalfCPU"

let
  sampleGameSearchNodes = commandLineParams()[0].parseInt
  targetTrainingSamples = commandLineParams()[1].parseInt
  useOnlyHalfCPU = commandLineParams()[2].parseBool

doAssert not useOnlyHalfCPU or ThreadPoolSize <= max(1, countProcessors() div 2),
  "To use only half half of the CPU, the program must be compiled with the switch \"--define:halfCPU\""

const
  # We need a minimum number of start positions, as otherwise it's difficult to adjust the number
  # of randomly selected leaves to get to the target number of training sample
  minNumStartPositions = 1000
  randRatio = 0.0005
  sampleFrequencyInGameHalfmove = 20 .. 40
  ratioGameResultSearchValue = 0.5

doAssert not gitHasUnstagedChanges,
  "Shouldn't do training data generation with unstaged changes"

let
  startDate = now().format("yyyy-MM-dd-HH-mm-ss")
  outDir = "res/data/"
  outputFilename =
    fmt"{outDir}trainingSet_{startDate}_{sampleGameSearchNodes}_{versionOrId()}.bin"

discard existsOrCreateDir outDir
doAssert not fileExists outputFilename,
  "Can't overwrite existing file: " & outputFilename

func isValidSamplePosition(position: Position): bool =
  position.gameStatus == running and position.halfmoveClock < 50
    # otherwise the position is probably just shuffling

proc playGame(startPos: Position, hashTable: ref HashTable): seq[(Position, float)] =
  var game = newGame(
    startPosition = startPos,
    maxNodes = sampleGameSearchNodes,
    adjudicateThreefold = true,
    hashTable = hashTable,
  )
  let
    gameResult = game.playGame # (printInfo = true)
    positionHistory = game.getPositionHistory
  doAssert gameResult in 0.0 .. 1.0

  var
    rg = initRand()
    index = 0

  while index < positionHistory.len:
    let
      (position, value) = positionHistory[index]
      searchWinningProb = value.winningProbability

    if position.isValidSamplePosition:
      let label =
        ratioGameResultSearchValue * gameResult +
        (1.0 - ratioGameResultSearchValue) * searchWinningProb

      result.add (position, label)
      index += rg.rand(sampleFrequencyInGameHalfmove)
    else:
      index += 1

let
  openingPositions = block:
    var positions = getStartPositions(max(minNumStartPositions, 10_000))
    var rg = initRand()
    rg.shuffle(positions)
    positions

  expectedNumberSamplesPerOpening = targetTrainingSamples div openingPositions.len

var
  outFileStream = newFileStream(outputFilename, fmWrite)
  outFileMutex = Lock()
  openingSearchNodes: Atomic[float]
initLock outFileMutex

const expectedNumPliesPerGame = 120
# This is just a first very rough guess:
openingSearchNodes.store(
  targetTrainingSamples.float /
    (expectedNumPliesPerGame.float * randRatio * openingPositions.len.float)
)

echo fmt"{outputFilename = }"
echo fmt"{ThreadPoolSize = }"
echo fmt"{targetTrainingSamples = }"
echo fmt"{sampleGameSearchNodes = }"
echo fmt"{openingSearchNodes.load = }"
echo fmt"{openingPositions.len = }"
echo fmt"{expectedNumberSamplesPerOpening = }"

proc findStartPositionsAndPlay(startPos: Position, stringIndex: string) =
  try:
    var
      rg = initRand()
      numSamples = 0

    {.warning[ProveInit]: off.}:
      var sampleGameHashTable = new HashTable
    sampleGameHashTable[] = newHashTable(len = sampleGameSearchNodes * 2)

    func specialEval(position: Position): Value =
      result = position.perspectiveEvaluate
      {.cast(noSideEffect).}:
        if rg.rand(1.0) <= randRatio and position.isValidSamplePosition:
          let samples = position.playGame(sampleGameHashTable)
          numSamples += samples.len

          withLock outFileMutex:
            for (position, value) in samples:
              outFileStream.writePosition position
              outFileStream.write value
              outFileStream.flush

    var game = newGame(
      startPosition = startPos,
      maxNodes = openingSearchNodes.load.int,
      hashTable = nil,
      evaluation = specialEval,
    )
    discard game.playGame

    echo fmt"Finished opening {stringIndex}, {numSamples = }"

    openingSearchNodes.store openingSearchNodes.load *
      clamp(expectedNumberSamplesPerOpening.float / numSamples.float, 0.99, 1.01)

    echo fmt"{openingSearchNodes.load.int = }"
  except Exception:
    echo "ERROR: EXCEPTION: ", getCurrentExceptionMsg()
    quit(QuitFailure)

let startTime = now()

var threadpool = createMaster()

threadpool.awaitAll:
  for i, position in openingPositions:
    let stringIndex = fmt"{i+1}/{openingPositions.len}"
    threadpool.spawn position.findStartPositionsAndPlay(stringIndex)

echo "Wrote to file ", outputFilename
echo "Total time: ", now() - startTime
