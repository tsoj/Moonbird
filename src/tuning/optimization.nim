import ../evalParams, ../version, tuningUtils

import std/[times, strformat, random, math, os]

proc optimize(
    start: EvalParams,
    data: var seq[Entry],
    maxNumEpochs = 2, #30,
    startLr = 1000.0,
    finalLr = 1.0, #0.05,
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
data.loadData "res/data/trainingSet_2024-04-11-02-05-49_6000_0ac4353.bin"
data.loadData "res/data/trainingSet_2024-04-08-01-24-53_6000_0e77b9d.bin"
data.loadData "res/data/trainingSet_2024-04-08-01-26-28_6000_0e77b9d.bin"
data.loadData "res/data/trainingSet_2024-04-08-11-05-12_6000_0e77b9d.bin"
data.loadData "res/data/trainingSet_2024-04-12-01-37-52_1000_bc57aac.bin"
data.loadData "res/data/trainingSet_2024-04-13-03-40-00_1000_6ca7f8d.bin"
data.loadData "res/data/trainingSet_2024-04-13-03-38-27_1000_6ca7f8d.bin"
data.loadData "res/data/trainingSet_2024-04-13-03-39-29_1000_6ca7f8d.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-00-27-10_1000_2932d88.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-00-28-06_1000_2932d88.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-00-37-08_1000_2932d88.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-01-32-49_1000_ff75da3.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-01-32-54_1000_ff75da3.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-02-31-05_1000_ff75da3.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-02-32-29_1000_ff75da3.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-22-12-14-31_1000_ff75da3.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-23-00-08-14_1000_9cc126c.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-23-00-11-05_1000_9cc126c.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-23-00-11-22_1000_9cc126c.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-23-00-12-32_1000_9cc126c.bin"
data.loadData "res/data/no_gaps/trainingSet_2024-05-23-03-28-01_1000_9cc126c.bin"
data.shuffle

echo "Total number of entries: ", data.len

let startDate = now().format("yyyy-MM-dd-HH-mm-ss")

var startEvalParams = newEvalParams()
let (ep, finalError) = startEvalParams.optimize(data)

let
  outDir = "res/params/"
  fileName =
    fmt"{outDir}optimizationResult_{startDate}_{versionOrId()}_{finalError:>9.7f}.bin"

createDir outDir

writeFile fileName, ep.toString
echo "filename: ", fileName

echo "Total time: ", now() - startTime
