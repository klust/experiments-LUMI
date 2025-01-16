#!/bin/bash

echo "Number of arguments is $#"

for num in $(seq 1 $#)
do
    echo "Argument: $1"
    shift
done
