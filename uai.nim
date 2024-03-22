
import
    position,
    positionUtils,
    hashTable,
    searchParams,
    version,
    utils,
    uaiSearch,
    movegen,
    tests,
    perft


import std/[
    strutils,
    strformat
]

const
    defaultHashSizeMB = 4
    maxHashSizeMB = 1_048_576

type UaiState = object
    position: Position
    history: seq[Position]
    hashTable: HashTable

proc uai(uaiState: var UaiState) =
    echo "id name Moonbird " & versionOrId()
    echo "id author Jost Triller"
    echo "option name Hash type spin default ", defaultHashSizeMB, " min 1 max ", maxHashSizeMB
    printUaiSearchParams()
    echo "uaiok"

proc setOption(uaiState: var UaiState, params: seq[string]) =

    if params.len == 4 and
    params[0] == "name" and
    params[2] == "value":
        if params[1].toLowerAscii == "Hash".toLowerAscii:
            let newHashSizeMB = params[3].parseInt
            if newHashSizeMB < 1 or newHashSizeMB > maxHashSizeMB:
                echo "Invalid value"
            else:
                uaiState.hashTable.setByteSize(sizeInBytes = newHashSizeMB * megaByteToByte)
        else:
            if hasSearchOption(params[1]):
                setSearchOption(params[1], params[3].parseInt)
            else:
                echo "Unknown option: ", params[1]
    else:
        echo "Unknown parameters"


proc moves(position: Position, params: seq[string]): (seq[Position], Position) =
    if params.len < 1:
        echo "Missing moves"

    var
        history: seq[Position]
        position = position
    
    for i in 0..<params.len:
        history.add(position)
        position = position.doMove(params[i].toMove)

    (history, position)


proc setPosition(uaiState: var UaiState, params: seq[string]) =

    var
        index = 0
        position: Position
        history: seq[Position]
        
    if params.len >= 1 and params[0] == "startpos":
        position = startpos
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
        position = fen.toPosition
    else:
        echo "Unknown parameters"
        return



    if params.len > index and params[index] == "moves":
        index += 1
        let r = moves(position, params[index..^1])
        history = r[0]
        position = r[1]

    uaiState.position = position
    uaiState.position = position


proc go(uaiState: var UaiState, params: seq[string]) =

    var searchInfo = SearchInfo(
        position: uaiState.position,
        hashTable: addr uaiState.hashTable,
        positionHistory: uaiState.history,
        targetDepth: Ply.high,
        movesToGo: int.high,
        increment: [red: 0.Seconds, blue: 0.Seconds],
        timeLeft: [red: Seconds.high, blue: Seconds.high],
        moveTime: Seconds.high,
        nodes: int.high
    )

    for i in 0..<params.len:
        if i+1 < params.len:  
            case params[i]:
            of "depth":
                searchInfo.targetDepth = params[i+1].parseInt.clampToType(Ply)
            of "movestogo":
                searchInfo.movesToGo = params[i+1].parseInt.int16
            of "winc":
                searchInfo.increment[red] = Seconds(params[i+1].parseFloat / 1000.0)
            of "binc":
                searchInfo.increment[blue] = Seconds(params[i+1].parseFloat / 1000.0)
            of "wtime":
                searchInfo.timeLeft[red] = Seconds(params[i+1].parseFloat / 1000.0)
            of "btime":
                searchInfo.timeLeft[blue] = Seconds(params[i+1].parseFloat / 1000.0)
            of "movetime":
                searchInfo.moveTime = Seconds(params[i+1].parseFloat / 1000.0)
            of "nodes":
                searchInfo.nodes = params[i+1].parseBiggestInt
            else:
                discard

    uaiSearch(searchInfo)



proc uaiNewGame(uaiState: var UaiState) =
    uaiState.hashTable.clear()
    uaiState.history.setLen(0)

proc test() =
    discard runTests()

proc perft(uaiState: UaiState, params: seq[string]) =
    if params.len >= 1:
        let
            start = secondsSince1970()
            nodes = uaiState.position.perft(params[0].parseInt, printRootMoveNodes = true)
            s = secondsSince1970() - start
        echo nodes, " nodes in ", fmt"{s.float:0.3f}", " seconds"
        echo (nodes.float / s.float).int, " nodes per second"
    else:
        echo "Missing depth parameter"

proc uaiLoop*() =

    var uaiState = UaiState(
        position: startpos,
        hashtable: newHashTable()
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
                uaiState.setOption(params[1..^1])
            of "isready":
                echo "readyok"
            of "position":
                uaiState.setPosition(params[1..^1])
            of "go":
                uaiState.go(params[1..^1])
            of "quit":
                break
            of "uainewgame":
                uaiState.uaiNewGame()
            of "print":
                echo uaiState.position
            of "fen":
                echo uaiState.position.fen
            of "perft":
                uaiState.perft(params[1..^1])
            of "test":
                test()
            else:
                try:
                    uaiState.setPosition(@["fen"] & params)
                except CatchableError:
                    echo "Unknown command: ", params[0]
                    echo "Use 'help'"
        except EOFError:
            echo "Quitting because of reaching end of file"
            break
        except CatchableError:
            echo "Error: ", getCurrentExceptionMsg()