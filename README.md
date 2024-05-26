<div align="center">
<p><h1>Moonbird</h1>
<img src="./res/logo.png" width="384px" style="border-radius: 20px;">
<i><h4>Ataxx engine written in Nim</h4></i>
</h1>
</div>

Moonbird is a superhuman Ataxx engine. It supports the Universal Ataxx Interface (UAI), so it can be used with any Ataxx tools or GUIs that support this protocol, such as [AtaxxGUI](https://github.com/tsoj/AtaxxGUI) or [Cuteataxx](https://github.com/kz04px/cuteataxx). Moonbird is written in the programming language [Nim](https://nim-lang.org/), a modern compiled systems language.

Moonbird uses the alpha-beta search algorithm with modifications such as move ordering, transposition table, nullmove pruning, principal variation search, late move and futility reductions, and aspiration windows. The evaluation function uses large tables of 4x2 and 2x4 tuples that are tuned using stochastic gradient descent.

### Prerequisites

You need Nim 2.0 or newer.
You also need the threadpool library malebolgia:
```shell
nimble install malebolgia@1.3.2
```

### Compiling for native CPU
```shell
nim native Moonbird
```

### Compiling for generic CPUs
```shell
nim default Moonbird
```

### Run training data generation
```shell
nimble install malebolgia@1.3.2
# Arguments are: sampleGameSearchNodes targetTrainingSamples useOnlyHalfCPU
nim genData --run Moonbird 6_000 50_000_000 false
```

### Run SPRT
```shell
nim sprt --run Moonbird
```

### Tune eval parameters
```shell
nim tuneEvalParams --run Moonbird
```

### Tune search parameters
```shell
nim runWeatherFactory --run Moonbird
```

### Run tests
```shell
./run_tests.sh
```
