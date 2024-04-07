import types

import std/[tables, macros, typetraits, json, strformat]

const floatQuantizer = 1_000.0

type ParamEntry = object
  address: ptr int
  min: int
  max: int
  step: int

var paramTable: OrderedTable[string, ParamEntry]

proc getVarName(name: NimNode): NimNode =
  parseExpr($toStrLit(name) & "Var")

proc getVarString(name: NimNode): NimNode =
  parseExpr("\"" & $toStrLit(name) & "\"")

func getAsInt[T](a: T): int =
  when distinctBase(T) is SomeFloat:
    (a.float * floatQuantizer).int
  else:
    a.int

macro addParam[T](name: untyped, default, min, max, step: T, tunable: bool = true): untyped =
  let
    varName: NimNode = getVarName(name)
    varString: NimNode = getVarString(name)
  quote:
    var `varName`: int = `default`.getAsInt

    if `tunable`:
      paramTable[`varString`] = ParamEntry(
        address: addr `varName`,
        min: `min`.getAsInt,
        max: `max`.getAsInt,
        step: `step`.getAsInt,
      )

    func `name`*(): auto =
      type R = typeof(`default`)
      {.cast(noSideEffect).}:
        when distinctBase(R) is SomeFloat:
          R(R(`varName`).float / floatQuantizer)
        else:
          R(`varName`)

proc hasSearchOption*(name: string): bool =
  name in paramTable

proc setSearchOption*(name: string, value: int) =
  if name in paramTable:
    let allowedRange = paramTable[name].min .. paramTable[name].max
    if value notin allowedRange:
      raise newException(
        KeyError,
        "Parameter '" & name & "' doesn't allow values outside " & $allowedRange &
          " but value is '" & $value & "'",
      )
    paramTable[name].address[] = value
  else:
    raise newException(KeyError, "Parameter '" & name & "' doesn't exist")

proc printUaiSearchParams*() =
  for name, param in paramTable:
    echo "option name ",
      name,
      " type spin default ",
      param.address[],
      " min ",
      param.min,
      " max ",
      param.max

addParam(aspirationWindowStartingOffset, default = 8, min = 2, max = 100, step = 2)
addParam(aspirationWindowMultiplier, default = 1.9, min = 1.1, max = 10.0, step = 0.2)

addParam(minMoveCounterFutility, default = 2, min = 2, max = 20, step = 2)
addParam(futilityReductionDiv, default = 67, min = 10, max = 500, step = 30)

addParam(nullMoveDepthSub, default = 3.Ply, min = 0.Ply, max = 10.Ply, step = 1.Ply)
addParam(nullMoveDepthDiv, default = 3, min = 1, max = 15, step = 1)
addParam(minFreeSquaresNullMovePruning, default = 9, min = 0, max = 49, step = 2)

addParam(lmrDepthHalfLife, default = 37, min = 5, max = 60, step = 10)
addParam(lmrDepthSub, default = 1.Ply, min = 0.Ply, max = 5.Ply, step = 1.Ply)
addParam(minMoveCounterLmr, default = 4, min = 1, max = 15, step = 2)

addParam(iirMinDepth, default = 4.Ply, min = 0.Ply, max = 12.Ply, step = 1.Ply)

addParam(maxHistoryTableValue, default = 97000, min = 1000, max = 10000000, step = 40000)
addParam(historyTableBadMoveDivider, default = 12.7, min = 1.0, max = 100.0, step = 8.0)
addParam(historyTableShrinkDiv, default = 1.9, min = 1.1, max = 10.0, step = 0.5)
addParam(historyMoveOrderingFactor, default = 6.9, min = 0.1, max = 1000.0, step = 5.0)

proc getWeatherFactoryConfig*(): string =
  result = "{"
  for name, param in paramTable:
    result &= "\"" & name & "\": {"
    result &=
      fmt"""
          "value": {param.address[]},
          "min_value": {param.min},
          "max_value": {param.max},
          "step": {param.step}
          """
    result &= "},"
  result &= "}"
  result = result.parseJson.pretty
