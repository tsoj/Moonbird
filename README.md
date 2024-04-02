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
# The first argument ("1_000_000") is the target number of training samples
nim genData --run Moonbird 100_000_000
```

### Run SPRT
```shell
nim sprt --run Moonbird
```

### Tune eval parameters
```shell
nim tuneEvalParams --run Moonbird
```

### Run tests
```shell
./run_tests.sh
```