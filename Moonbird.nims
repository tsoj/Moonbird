import src/version

#!fmt: off

# Default flags
--mm:arc
--define:useMalloc
# --passL:"-static"
--cc:clang
--threads:on
--styleCheck:hint

proc lto() =
  --passC:"-flto"
  --passL:"-flto"

  if defined(windows):
    --passL:"-fuse-ld=lld"

proc highPerformance() =
  --panics:on
  --define:danger
  lto()

proc lightDebuggerInfo() =
  --passC:"-fno-omit-frame-pointer -g"

proc fullDebuggerInfo() =
  lightDebuggerInfo()
  --debugger:native

let
    projectNimFile = "src/Moonbird.nim"
    suffix = if defined(windows): ".exe" else: ""
    binDir = "bin/"

proc setBinaryName(name: string) =
  switch("o", binDir & name & suffix)

task debug, "debug compile":
  --define:debug
  --passC:"-O2"
  fullDebuggerInfo()
  setBinaryName(projectName() & "-debug")
  setCommand "c", projectNimFile

task profile, "profile compile":
  highPerformance()
  fullDebuggerInfo()
  setBinaryName(projectName() & "-profile")
  setCommand "c", projectNimFile

task default, "default compile":
  lightDebuggerInfo()
  highPerformance()
  setBinaryName(projectName())
  setCommand "c", projectNimFile

task native, "native compile":
  highPerformance()
  --passC:"-march=native"
  --passC:"-mtune=native"
  setBinaryName(projectName() & "-native")
  setCommand "c", projectNimFile

task tests, "Runs tests":
  --define:release
  fullDebuggerInfo()
  setBinaryName("tests")
  setCommand "c", "tests/tests.nim"

task genData, "Generates training data by playing games":
  highPerformance()
  --passC:"-march=native"
  --passC:"-mtune=native"
  setBinaryName("genData")
  setCommand "c", "src/tuning/generateTrainingData.nim"

task sprt, "Runs an SPRT test of the current branch against the main branch":
  --define:release
  setBinaryName("sprt")
  setCommand "c", "src/testing/runSprtTest.nim"

task tuneEvalParams, "Optimizes eval parameters":
  highPerformance()
  --passC:"-march=native"
  --passC:"-mtune=native"
  setBinaryName("tuneEvalParams")
  setCommand "c", "src/tuning/optimization.nim"

#!fmt: on
