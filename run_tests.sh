#!/bin/bash
set -e
nimble install malebolgia@1.3.2
nim Moonbird.nims | grep -v "^Hint:" | cut -d' ' -f1 | xargs -I {} nim {} Moonbird.nims
find . -name *.nim -print0 | xargs -n 1 -0 nim check $1
nim tests --run Moonbird.nims