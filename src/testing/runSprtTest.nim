import std/[osproc, strutils]

const
    mainBranch = "main"
    workingDir = "src/testing/"
    cuteAtaxxBinary = 

let gitStatus = execProcess("git status")

doAssert "git version" in execProcess("git --version")
doAssert "not a git repository" notin gitStatus
doAssert "On branch" in gitStatus

let
  gitHasUnstagedChanges = "nothing to commit, working tree clean" notin gitStatus
  currentBranch = execProcess("git rev-parse --abbrev-ref HEAD")

doAssert currentBranch != mainBranch
doAssert not gitHasUnstagedChanges

# if ""