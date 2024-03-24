import src/version

# Package
author = "Jost Triller"
description = "An Ataxx engine"
license = "MIT"
# srcDir = "src"
# bin = @["Moonbird"]

# Dependencies
requires "nim >= 2.1.1"
taskRequires "generateTrainingData", "taskpools >= 0.0.5"

#!fmt: off

# Default flags
--mm:arc
--define:useMalloc
--passL:"-static"
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
    name = binDir & projectName() & "-" & version().get(otherwise = "dev")

task debug, "debug compile":
  --define:debug
  --passC:"-O2"
  fullDebuggerInfo()
  switch("o", name & "-debug" & suffix)
  setCommand "c", projectNimFile

task profile, "profile compile":
  highPerformance()
  fullDebuggerInfo()
  switch("o", name & "-profile" & suffix)
  setCommand "c", projectNimFile

task default, "default compile":
  lightDebuggerInfo()
  highPerformance()
  switch("o", name & suffix)
  setCommand "c", projectNimFile

task native, "native compile":
  highPerformance()
  --passC:"-march=native"
  --passC:"-mtune=native"
  switch("o", name & "-native" & suffix)
  setCommand "c", projectNimFile

task generateTrainingData, "Builds the special/program.nim with specific flags":
  highPerformance()
  --passC:"-march=native"
  --passC:"-mtune=native"
  switch("o", binDir & "generateTrainingData" & suffix)
  setCommand "c", "src/tuning/generateTrainingData.nim"

#!fmt: on
