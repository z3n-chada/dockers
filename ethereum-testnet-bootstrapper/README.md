# Ethereum-Testnet-Bootstrapper
docker build scripts for building all combinations of el/cl clients, repo specific dockers, and fuzzers.

base-images
    builds the etb-client-builder which has the prereqs to build all of the execution clients and required libs.    
    builds the etb-client-runner which is what all clients are moved into to launch them.

consensus-clients:
    builds all consensus clients off of the etb-client-builder image.

execution clients:
    builds all of the execution clients off of the etb-client-builder image. 

fuzzers:
    builds the various fuzzers that we take advantage of.

etb-tools:
    creates the docker images for running the actual ethereum-testnet-bootstrapper suite.
