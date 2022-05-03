#!/bin/bash

for df in $(ls | grep Dockerfile); do
    i=`echo $df | tr '_' ':'`
    image="${i::-11}"
    BUILDKIT=1 docker build -f "$df" -t "$image" . &
done


