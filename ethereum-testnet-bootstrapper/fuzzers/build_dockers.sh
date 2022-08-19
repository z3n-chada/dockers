#!/bin/bash

# Import `record_image_failure` function
source ../common.sh

./build-tx-fuzzer.sh

BUILDKIT=1 docker build -t geth:bad-block-creator -f geth_bad-block-creator.Dockerfile . || record_image_failure "geth:bad-block-creator"
BUILDKIT=1 docker build -t geth:bad-block-creator-inst -f geth_bad-block-creator-inst.Dockerfile . || record_image_failure "geth:bad-block-creator-inst"
