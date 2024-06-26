import
  position,
  positionUtils,
  hashTable,
  searchParams,
  version,
  utils,
  uaiSearch,
  movegen,
  perft,
  uaiInfos,
  ../tests/tests

import std/[strutils, strformat]

import malebolgia

const
  defaultHashSizeMB = 4
  maxHashSizeMB = 1_048_576
  defaultNumThreads = 1

type UaiState {.requiresInit.} = object
  history: seq[Position]
  hashTable: HashTable
  numThreads: int

func currentPosition(uaiState: UaiState): Position =
  doAssert uaiState.history.len >= 1
  uaiState.history[^1]

proc uai(uaiState: var UaiState) =
  echo "id name Moonbird " & versionOrId()
  echo "id author Jost Triller"
  echo "option name Hash type spin default ",
    defaultHashSizeMB, " min 1 max ", maxHashSizeMB
  echo "option name Threads type spin default ",
    defaultNumThreads, " min 1 max ", ThreadPoolSize
  printUaiSearchParams()
  echo "uaiok"

proc setOption(uaiState: var UaiState, params: seq[string]) =
  if params.len == 4 and params[0] == "name" and params[2] == "value":
    case params[1].toLowerAscii
    of "Hash".toLowerAscii:
      let newHashSizeMB = params[3].parseInt
      if newHashSizeMB < 1 or newHashSizeMB > maxHashSizeMB:
        echo "Invalid value"
      else:
        uaiState.hashTable.setByteSize(sizeInBytes = newHashSizeMB * megaByteToByte)
    of "Threads".toLowerAscii:
      let newNumThreads = params[3].parseInt
      if newNumThreads in 1 .. ThreadPoolSize:
        uaiState.numThreads = newNumThreads
      else:
        echo "Invalid value"
    else:
      if hasSearchOption(params[1]):
        setSearchOption(params[1], params[3].parseInt)
      else:
        echo "Unknown option: ", params[1]
  else:
    echo "Unknown parameters"

proc moves(position: Position, params: seq[string]): seq[Position] =
  if params.len < 1:
    echo "Missing moves"

  result = @[position]

  for i in 0 ..< params.len:
    let move = params[i].toMove
    if not move.isLegal(result[^1]):
      raise newException(ValueError, "Illegal move: " & $move)
    result.add result[^1].doMove(move)

proc setPosition(uaiState: var UaiState, params: seq[string]) =
  var
    index = 0
    history: seq[Position]

  if params.len >= 1 and params[0] == "startpos":
    history = @[startPos]
    index = 1
  elif params.len >= 1 and params[0] == "fen":
    var fen: string
    index = 1
    var numFenWords = 0
    while params.len > index and params[index] != "moves":
      if numFenWords < 6:
        numFenWords += 1
        fen &= " " & params[index]
      index += 1
    history = @[fen.toPosition]
  else:
    echo "Unknown parameters"
    return

  if params.len > index and params[index] == "moves":
    index += 1
    history = moves(history[^1], params[index ..^ 1])

  uaiState.history = history

proc go(uaiState: var UaiState, params: seq[string]) =
  var searchInfo = SearchInfo(
    positionHistory: uaiState.history,
    hashTable: addr uaiState.hashTable,
    targetDepth: Ply.high,
    movesToGo: int.high,
    increment: [red: 0.Seconds, blue: 0.Seconds],
    timeLeft: [red: Seconds.high, blue: Seconds.high],
    moveTime: Seconds.high,
    nodes: int.high,
    numThreads: uaiState.numThreads,
  )

  for i in 0 ..< params.len:
    if i + 1 < params.len:
      case params[i]
      of "depth":
        searchInfo.targetDepth = params[i + 1].parseInt.clampToType(Ply)
      of "movestogo":
        searchInfo.movesToGo = params[i + 1].parseInt.int16
      of "winc":
        searchInfo.increment[blue] = Seconds(params[i + 1].parseFloat / 1000.0)
      of "binc":
        searchInfo.increment[red] = Seconds(params[i + 1].parseFloat / 1000.0)
      of "wtime":
        searchInfo.timeLeft[blue] = Seconds(params[i + 1].parseFloat / 1000.0)
      of "btime":
        searchInfo.timeLeft[red] = Seconds(params[i + 1].parseFloat / 1000.0)
      of "movetime":
        searchInfo.moveTime = Seconds(params[i + 1].parseFloat / 1000.0)
      of "nodes":
        searchInfo.nodes = params[i + 1].parseBiggestInt
      else:
        discard

  uaiSearch(searchInfo)

proc uaiNewGame(uaiState: var UaiState) =
  uaiState.hashTable.clear()
  uaiState.history = @[startPos]

proc test() =
  discard runTests()

proc perft(uaiState: UaiState, params: seq[string]) =
  if params.len >= 1:
    let
      start = secondsSince1970()
      nodes =
        uaiState.currentPosition.perft(params[0].parseInt, printRootMoveNodes = true)
      s = secondsSince1970() - start
    echo nodes, " nodes in ", fmt"{s.float:0.3f}", " seconds"
    echo (nodes.float / s.float).int, " nodes per second"
  else:
    echo "Missing depth parameter"

proc uaiLoop*() =
  printLogo()

  var uaiState = UaiState(
    history: @[startPos], hashtable: newHashTable(), numThreads: defaultNumThreads
  )
  uaiState.hashTable.setByteSize(sizeInBytes = defaultHashSizeMB * megaByteToByte)

  while true:
    try:
      let command = readLine(stdin)
      let params = command.splitWhitespace()
      if params.len == 0 or params[0] == "":
        continue
      case params[0]
      of "uai":
        uaiState.uai()
      of "setoption":
        uaiState.setOption(params[1 ..^ 1])
      of "isready":
        echo "readyok"
      of "position":
        uaiState.setPosition(params[1 ..^ 1])
      of "go":
        uaiState.go(params[1 ..^ 1])
      of "quit":
        break
      of "uainewgame":
        uaiState.uaiNewGame()
      of "print":
        print uaiState.currentPosition
      of "fen":
        echo uaiState.currentPosition.fen
      of "perft":
        uaiState.perft(params[1 ..^ 1])
      of "test":
        test()
      of "about":
        about(extra = "extra" in params)
      of "help":
        printHelp()
      else:
        try:
          uaiState.setPosition(@["fen"] & params)
        except CatchableError:
          try:
            uaiState.setPosition(
              @["fen"] & uaiState.currentPosition.fen & "moves" & params
            )
          except CatchableError:
            echo "Unknown command: ", params[0]
            echo "Use 'help'"
    except EOFError:
      echo "Quitting because of reaching end of file"
      break
    except CatchableError:
      echo "Error: ", getCurrentExceptionMsg()
