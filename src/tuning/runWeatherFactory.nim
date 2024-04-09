import ../searchParams, ../startPositions

import std/[osproc, os, strformat]

# TODO fix code duplication with testing/runSprtTest.nim

const
  minNumGames = 24
  tc = 8
  hash = 32
  workDir = "src/tuning/weather-factory-ataxx/"
  cuteAtaxxBinary = "../cuteataxx/build/cuteataxx-cli"

let
  numThreads = max(1, ((countProcessors() - 2) div 2) * 2)
  numGames = block:
    var numGames = 0
    while numGames < minNumGames:
      numGames += numThreads
    numGames

if not dirExists workDir:
  doAssert execCmd(
    "git clone \"https://github.com/tsoj/weather-factory-ataxx.git\" " & workDir
  ) == 0
  doAssert execCmd(
    fmt"git -C {workDir} checkout ac0f0134a0e86fc0caae046a51a9962450fed933"
  ) == 0

removeDir workDir & "tuner"
createDir workDir & "tuner"

doAssert execCmd("nim native -f Moonbird") == 0
copyFileWithPermissions "bin/Moonbird-native", workDir & "tuner/Moonbird-native"

copyFileWithPermissions cuteAtaxxBinary, workDir & "tuner/cuteataxx-cli"

setCurrentDir workDir

createStartPositionFile "tuner/book.txt", 10_000

writeFile "config.json", getWeatherFactoryConfig()

writeFile "cuteataxx.json",
  fmt"""{{
    "engine": "Moonbird-native",
    "book": "book.txt",
    "games": {numGames},
    "tc": {tc},
    "hash": {hash},
    "threads": {numThreads}
}}"""

doAssert execCmd(fmt"python3 main.py") == 0
