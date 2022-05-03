from z3nchada/etb-client-builder:latest as base

from base as builder

RUN mkdir -p /go/src/github.com/ethereum/ 
WORKDIR /go/src/github.com/ethereum/

ARG GETH_BRANCH="master"

RUN git clone https://github.com/ethereum/go-ethereum \
    && cd go-ethereum \
    && git checkout ${GETH_BRANCH} 

RUN cd go-ethereum \
    && go install ./...
    

from debian:bullseye-slim

COPY --from=builder /root/go/bin/geth /usr/local/bin/geth
COPY --from=builder /root/go/bin/bootnode /usr/local/bin/bootnode



ENTRYPOINT ["/bin/bash"]
