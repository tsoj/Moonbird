```
                    __   🌕
                   / .>    
┳┳┓      ┓ •   ┓  ( ) )    
┃┃┃┏┓┏┓┏┓┣┓┓┏┓┏┫  |/ /     
┛ ┗┗┛┗┛┛┗┗┛┗┛ ┗┻━━━━>━>━─┄┈
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
nimble install taskpools@0.0.5
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