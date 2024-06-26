import src/version

import std/[strutils, strformat]

#!fmt: off

# Default flags
--mm:arc
--define:useMalloc
--cc:clang
--threads:on
--styleCheck:hint

var threadPoolSize = 1024

doAssert defined(linux) or not (defined(halfCPU) or defined(almostFullCPU)), "Switches halfCPU and almostFullCPU are only supported on Linux"

if defined(halfCPU):
  threadPoolSize = max(1, staticExec("nproc").parseInt div 2)
elif defined(almostFullCPU):
  threadPoolSize = max(1, staticExec("nproc").parseInt - 2)

switch("define", fmt"ThreadPoolSize={threadPoolSize}")

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
  # --define:release
  setBinaryName("tuneEvalParams")
  setCommand "c", "src/tuning/optimization.nim"

task runWeatherFactory, "Optimizes search parameters":
  --define:release
  setBinaryName("runWeatherFactory")
  setCommand "c", "src/tuning/runWeatherFactory.nim"

#!fmt: on
