import ../types, ../positionUtils, ../evalParams, ../evaluation

import std/[math, os, streams]

const k = 567.89

func winningProbability*(centipawn: Value): float =
  let x = centipawn.float
  1.0 / (1.0 + pow(10.0, -x / k))

func winningProbabilityDerivative*(centipawn: Value): float =
  let x = centipawn.float
  ln(10.0) * pow(10.0, x / k) / (k * pow(pow(10.0, x / k) + 1.0, 2.0))

type Entry* = object
  position*: Position
  outcome*: float

proc loadData*(
    data: var seq[Entry], fileName: string, maxLen = int.high, suppressOutput = false
) =
  doAssert fileExists fileName, "File should exist"

  var
    inFileStream = newFileStream(fileName, fmRead)
    numEntries = 0

  while not inFileStream.atEnd:
    let
      position = inFileStream.readPosition
      value = inFileStream.readFloat64

    data.add Entry(position: position, outcome: value)
    numEntries += 1

    if numEntries >= maxLen:
      break

  if not suppressOutput:
    debugEcho fileName & ": ", numEntries, " entries"

func error*(outcome, estimate: float): float =
  (outcome - estimate) ^ 2

func errorDerivative*(outcome, estimate: float): float =
  2.0 * (outcome - estimate)

func error*(evalParams: EvalParams, entry: Entry): float =
  let estimate = evalParams.absoluteEvaluate(entry.position).winningProbability
  error(entry.outcome, estimate)

func error*(evalParams: EvalParams, data: openArray[Entry]): float =
  for entry in data:
    result += evalParams.error(entry)
  result /= data.len.float

    
func addGradient*(
    params: var EvalParams,
    lr: float,
    position: Position, outcome: float
) =
    let currentValue = params.absoluteEvaluate(position)
    var currentGradient = Gradient(
        g: errorDerivative(outcome, currentValue.winningProbability) * currentValue.winningProbabilityDerivative * lr,
        gradient: addr params
    )
    currentGradient.absoluteEvaluate(position)
