import types

import std/[
    options,
    strutils,
    times,
    os,
    osproc
]

export options, strutils

const megaByteToByte* = 1_048_576

func boardString*(f: proc(square: Square): Option[string] {.noSideEffect.}): string =
    result = " _ _ _ _ _ _ _\n"
    for rank in countdown(6, 0):
        for file in 0..6:
            result &= "|"
            let s = f((7*rank + file).Square)
            if s.isSome:
                result &= s.get()
            else:
                result &= "_"
        result &= "|" & intToStr(rank + 1) & "\n"
    result &= " A B C D E F G"

func clampToType*[In, Out](x: In, OutType: typedesc[Out]): Out =
    x.clamp(OutType.low.In, OutType.high.In).Out

proc getCpuInfo*(): string =
    when defined(posix):
        var cpuName = execCmdEx("""
        cat /proc/cpuinfo | awk -F '\\s*: | @' '/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ { cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file"
        """).output
        return cpuName.strip


type Seconds* = distinct float

func `$`*(a: Seconds): string = $a.float & " s"

func high*(T: typedesc[Seconds]): Seconds = float.high.Seconds
func low*(T: typedesc[Seconds]): Seconds = float.low.Seconds

func `==`*(a, b: Seconds): bool {.borrow.}
func `<=`*(a, b: Seconds): bool {.borrow.}
func `<`*(a, b: Seconds): bool {.borrow.}

func `-`*(a, b: Seconds): Seconds {.borrow.}
func `+`*(a, b: Seconds): Seconds {.borrow.}
func `*`*(a: Seconds, b: SomeNumber): Seconds = Seconds(a.float * b.float)
func `*`*(a: SomeNumber, b: Seconds): Seconds = Seconds(a.float * b.float)
func `/`*(a: Seconds, b: SomeNumber): Seconds = Seconds(a.float / b.float)

func `+=`*(a: var Seconds, b: Seconds) = a = a + b
func `-=`*(a: var Seconds, b: Seconds) = a = a - b
func `*=`*(a: var Seconds, b: SomeNumber) = a = a * b
func `/=`*(a: var Seconds, b: SomeNumber) = a = a / b

func secondsSince1970*(): Seconds =
    {.cast(noSideEffect).}:
        epochTime().Seconds
