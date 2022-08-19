#!/bin/bash

# Import `record_image_failure` function
source ../common.sh

for df in $(ls | grep Dockerfile); do
    echo $df
    i=`echo $df | tr '_' ':'`
    image=`echo "${i::-11}"`
    BUILDKIT=1 docker build --no-cache -f "$df" -t "$image" . || record_image_failure "${image}"
done

