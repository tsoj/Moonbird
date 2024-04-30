import ../startPositions, ../positionUtils

import std/[osproc, os, strutils, strformat, json]

const
  mainBranch = "main"
  workDir = "src/testing/workdir/"
  cuteAtaxxBinary = "../cuteataxx/build/cuteataxx-cli"
  moonbirdBinaryFile = "bin/Moonbird-native"
  fenFileName = workDir & "startpos.txt"
  cuteataxxSettingsFileName = workDir & "cuteataxxSettings.json"
  timeControlMilliseconds = 10_000
  maxNumGames = 100_000

let gitStatus = execProcess("git status")

doAssert "git version" in execProcess("git --version")
doAssert execProcess("git rev-parse --is-inside-work-tree").strip == "true"

doAssert "git version" in execProcess("git --version")
doAssert "not a git repository" notin gitStatus

let
  gitHasUnstagedChanges = execProcess("git status -suno").strip != ""
  currentBranch = execProcess("git rev-parse --abbrev-ref HEAD").strip

doAssert not gitHasUnstagedChanges, "Shouldn't do SPRT with unstaged changes"

if currentBranch == mainBranch:
  while true:
    stdout.write "You are about to test the main branch against itself. Are you sure you want to do this? [y/n] "
    stdout.flushFile
    let answer = readLine(stdin).strip.toLowerAscii
    if answer == "y":
      break
    if answer == "n":
      quit(QuitFailure)

discard existsOrCreateDir workDir

proc moonbirdBinary(branch: string): string =
  fmt"{getCurrentDir()}/{workDir}Moonbird-{branch}"

try:
  for branch in [mainBranch, currentBranch]:
    discard tryRemoveFile moonbirdBinaryFile
    if execCmd("git switch " & branch) != 0:
      raise newException(CatchableError, "Failed to switch to branch " & branch)
    if execCmd("nim native -f Moonbird") != 0:
      raise newException(
        CatchableError, "Failed to compile Moonbird binary for branch " & branch
      )
    copyFileWithPermissions moonbirdBinaryFile, moonbirdBinary(branch)
finally:
  doAssert execCmd("git switch " & currentBranch) == 0

createStartPositionFile fenFileName, maxNumGames

let cuteataxxSettings =
  %*{
    "games": 100_000,
    "concurrency": max(1, countProcessors() - 2),
    "ratinginterval": 100,
    "verbose": false,
    "debug": false,
    "recover": false,
    "colour1": "Red",
    "colour2": "Blue",
    "tournament": "roundrobin",
    "print_early": true,
    "adjudicate":
      {"gamelength": 300, "material": 30, "easyfill": true, "timeout_buffer": 25},
    "openings": {"path": fenFileName, "repeat": true, "shuffle": true},
    "timecontrol":
      {"time": timeControlMilliseconds, "inc": timeControlMilliseconds div 100},
    "options": {"debug": "false", "threads": "1", "hash": "64", "ownbook": "false"},
    "sprt":
      {"enabled": true, "autostop": true, "elo0": 0.0, "elo1": 5.0, "confidence": 0.95},
    "pgn": {
      "enabled": true,
      "verbose": true,
      "override": false,
      "path": workDir & "games.pgn",
      "event": "Testing Moonbird",
    },
    "engines": [
      {
        "name": "Moonbird-" & currentBranch,
        "path": moonbirdBinary(currentBranch),
        "protocol": "UAI",
      },
      {
        "name": "Moonbird-" & mainBranch,
        "path": moonbirdBinary(mainBranch),
        "protocol": "UAI",
      },
    ],
  }

writeFile(cuteataxxSettingsFileName, cuteataxxSettings.pretty)
doAssert execCmd(cuteAtaxxBinary & " " & cuteataxxSettingsFileName) == 0

echo "Finished SPRT test"
