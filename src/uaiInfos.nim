import version

import std/[terminal]

proc printSeperatorLine() =
  styledEcho {styleDim}, "-----------------------------------------"

proc printHelp*() =
  printSeperatorLine()
  #!fmt: off
  styledEcho styleDim, "• ", resetStyle, "uai"
  styledEcho styleDim, "• ", resetStyle, "setoption", styleDim, " name <id> [value <x>]"
  styledEcho styleDim, "• ", resetStyle, "isready"
  styledEcho styleDim, "• ", resetStyle, "position", styleDim, " [fen <fenstring> | startpos] moves <move_1> ... <move_i>"
  styledEcho styleDim, "• ", resetStyle, "go", styleDim, " [wtime|btime|winc|binc|movestogo|movetime|depth|infinite [<x>]]..."
  styledEcho styleDim, "• ", resetStyle, "quit"
  styledEcho styleDim, "• ", resetStyle, "uainewgame"
  styledEcho styleDim, "• ", resetStyle, "print"
  styledEcho styleDim, "• ", resetStyle, "fen"
  styledEcho styleDim, "• ", resetStyle, "perft", styleDim, " <depth>"
  styledEcho styleDim, "• ", resetStyle, "test"
  styledEcho styleDim, "• ", resetStyle, "about", styleDim, " [extra]"
  #!fmt: on
  printSeperatorLine()

proc printLogo*() =
  echo "                    __   🌖"
  echo "                   / .>    "
  echo "┳┳┓      ┓ •   ┓  ( ) )    "
  echo "┃┃┃┏┓┏┓┏┓┣┓┓┏┓┏┫  |/ /     "
  echo "┛ ┗┗┛┗┛┛┗┗┛┗┛ ┗┻━━━━>━>━─┄┈"
  echo "                           "
  styledEcho {styleDim}, "      by Jost Triller      "

proc about*(extra = true) =
  const readme = readFile("README.md")
  printSeperatorLine()
  echo "Moonbird ", versionOrId()
  echo "Compiled at ", compileDate()
  echo "Copyright © ", compileYear(), " by Jost Triller"
  echo "git hash: ", commitHash()
  printSeperatorLine()
  if extra:
    echo readme
    printSeperatorLine()
