#!/bin/bash

while true; do

    inotifywait -e modify,create,delete -r ./src/game &&
    (cd build && make -j4 && pkill -USR1 logzig)

done
