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
nim genData --run Moonbird
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
nim tests --run Moonbird
```