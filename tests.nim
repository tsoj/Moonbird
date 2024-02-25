import
    positionUtils,
    perft

import std/[
    strformat,
    terminal,
    options
]


proc testFen(): Option[string] =
    const fens = [
        "x5o/7/7/7/7/7/o5x x 0 1",
        "x5o/7/2-1-2/7/2-1-2/7/o5x x 0 1",
        "x5o/7/3-3/2-1-2/3-3/7/o5x x 0 1",
        "7/7/7/7/7/7/7 x 0 1",
        "7/7/7/7/7/7/7 o 0 1",
        "7/7/7/7/7/7/7 x 100 1",
        "7/7/7/7/7/7/7 o 100 1",
        "7/7/7/7/7/7/7 x 0 100",
        "7/7/7/7/7/7/7 o 0 100",
        "7/7/7/7/7/7/7 x 100 200",
        "7/7/7/7/7/7/7 o 100 200",
        "x5o/7/7/7/7/7/o5x x", 
        "x5o/7/7/7/7/7/o5x x 0",
        "x5o/7/2-1-2/7/2-1-2/7/o5x x", 
        "x5o/7/2-1-2/7/2-1-2/7/o5x x 0"
    ]

    for fen in fens:
        if fen != fen.toPosition.fen[0..<fen.len]:
            return some fmt"{fen} != {fen.toPosition.fen}"

proc testPerft(): Option[string] =

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

    for (fen, targetNodes) in perftPositions:
        let position = fen.toPosition
        for i, nodesTarget in targetNodes:
            let nodes = position.perft(i)
            if nodesTarget != nodes:
                return some &"Perft to depth {i} for \"{fen}\" should be {nodesTarget} but is {nodes}"

when isMainModule:
    const tests = [
        (testFen, "FEN parsing"),
        (testPerft, "Move generation")
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
    else:
        styledEcho fgRed, styleBright, fmt"Failed {failedTests} of {tests.len} tests"
        


