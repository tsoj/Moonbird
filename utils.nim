import types

import std/[options, strutils, times, os, osproc, terminal, streams]

export options, strutils, terminal, streams

const megaByteToByte* = 1_048_576

func printBoardString*(
    outStream: File or Stream,
    piece: proc(square: Square): Option[(string, ForegroundColor)] {.noSideEffect.},
) =
  proc print(text: string, style: set[Style] = {}, color = fgDefault) =
    {.cast(noSideEffect).}:
      when outStream is File:
        outStream.styledWrite resetStyle, color, style, text
      elif outStream is Stream:
        outStream.write text
      else:
        doAssert false

  print(" _ _ _ _ _ _ _\n", style = {styleDim})
  for rank in countdown(6, 0):
    for file in 0 .. 6:
      print("|", style = {styleDim})
      let o = piece((7 * rank + file).Square)
      if o.isSome:
        let (s, color) = o.get()
        print(s, color = color)
      else:
        print("_", style = {styleDim})
    print("|" & intToStr(rank + 1) & "\n", style = {styleDim})
  print(" A B C D E F G", style = {styleDim})

  {.cast(noSideEffect).}:
    outStream.write "\n"
    when outStream is File:
      outStream.flushFile
    elif outStream is Stream:
      outStream.flush
    else:
      doAssert false

func boardString*(
    piece: proc(square: Square): Option[(string, ForegroundColor)] {.noSideEffect.}
): string =
  {.cast(noSideEffect).}:
    var strm = newStringStream()
    strm.printBoardString(piece = piece)
    strm.setPosition(0)
    result = strm.readAll()
    strm.close()

proc getCpuInfo*(): string =
  when defined(posix):
    var cpuName = execCmdEx(
      """
        cat /proc/cpuinfo | awk -F '\\s*: | @' '/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ { cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file"
        """
    ).output
    return cpuName.strip

type Seconds* = distinct float

func `$`*(a: Seconds): string =
  $a.float & " s"

func high*(T: typedesc[Seconds]): Seconds =
  float.high.Seconds
func low*(T: typedesc[Seconds]): Seconds =
  float.low.Seconds

func `==`*(a, b: Seconds): bool {.borrow.}
func `<=`*(a, b: Seconds): bool {.borrow.}
func `<`*(a, b: Seconds): bool {.borrow.}

func `-`*(a, b: Seconds): Seconds {.borrow.}
func `+`*(a, b: Seconds): Seconds {.borrow.}
func `*`*(a: Seconds, b: SomeNumber): Seconds =
  Seconds(a.float * b.float)
func `*`*(a: SomeNumber, b: Seconds): Seconds =
  Seconds(a.float * b.float)
func `/`*(a: Seconds, b: SomeNumber): Seconds =
  Seconds(a.float / b.float)

func `+=`*(a: var Seconds, b: Seconds) =
  a = a + b
func `-=`*(a: var Seconds, b: Seconds) =
  a = a - b
func `*=`*(a: var Seconds, b: SomeNumber) =
  a = a * b
func `/=`*(a: var Seconds, b: SomeNumber) =
  a = a / b

func secondsSince1970*(): Seconds =
  {.cast(noSideEffect).}:
    epochTime().Seconds
