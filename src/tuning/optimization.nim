import ../evalParams, ../version, tuningUtils

import std/[times, strformat, random, math, os]

proc optimize(
    start: EvalParams,
    data: var seq[Entry],
    maxNumEpochs = 10, #30,
    startLr = 10.0,
    finalLr = 0.05,
): tuple[params: EvalParams, loss: float] =
  var solution = start

  echo "starting error: ", fmt"{solution.error(data):>9.7f}", ", starting lr: ", startLr

  let lrDecay = pow(finalLr / startLr, 1.0 / float(maxNumEpochs * data.len))
  doAssert startLr > finalLr,
    "Starting learning rate must be strictly bigger than the final learning rate"
  doAssert finalLr == startLr or lrDecay < 1.0,
    "lrDecay should be smaller than one if the learning rate should decrease"

  var lr = startLr

  for epoch in 1 .. maxNumEpochs:
    let startTime = now()
    data.shuffle

    for entry in data:
      solution.addGradient(lr, entry.position, entry.outcome)
      lr *= lrDecay

    let
      error = solution.error(data[0 ..< min(data.len, 1_000_000)])
      passedTime = now() - startTime
    echo fmt"Epoch {epoch}, error: {error:>9.7f}, lr: {lr:.3f}, time: {passedTime.inSeconds} s"

  let finalError = solution.error(data)
  echo fmt"Final error: {finalError:>9.7f}"

  return (solution, finalError)

let startTime = now()

var data: seq[Entry]
data.loadData "res/data/trainingSet_2024-03-26-02-25-05_766cce2.bin"
data.loadData "res/data/trainingSet_2024-04-03-00-54-04_6000_31a443c.bin"
data.loadData "res/data/trainingSet_2024-04-03-00-56-14_6000_31a443c.bin"
data.shuffle

echo "Total number of entries: ", data.len

# doAssert not gitHasUnstagedChanges,
#   "Shouldn't do training data generation with unstaged changes"

let startDate = now().format("yyyy-MM-dd-HH-mm-ss")

var startEvalParams: EvalParams
let (ep, finalError) = startEvalParams.optimize(data)

let
  outDir = "res/params/"
  fileName =
    fmt"{outDir}optimizationResult_{startDate}_{versionOrId()}_{finalError:>9.7f}.bin"

createDir outDir

writeFile fileName, ep.toString
echo "filename: ", fileName

echo "Total time: ", now() - startTime
