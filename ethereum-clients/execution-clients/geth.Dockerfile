from eth-client-builder as builder

run mkdir /build

RUN mkdir -p /go/src/github.com/ethereum/ 

WORKDIR /go/src/github.com/ethereum/

ARG GETH_BRANCH="master"

RUN git clone https://github.com/ethereum/go-ethereum \
    && cd go-ethereum \
    && git checkout ${GETH_BRANCH} 

run cd go-ethereum && go get -t ./...

workdir /go/src/github.com/ethereum/go-ethereum/cmd/geth

from builder as default_builder
run go build -o /build
    
from builder as asan_builder
run go build -asan -o /build

from builder as race_builder
run go build -race -o /build

from builder as msan_builder

run go env -w "CC=clang-15"
run go env -w "CXX=clang-cpp-15"
run go env -w "AR=llvm-ar-15"
run go build -msan -o /build

from eth-client-runner

COPY --from=default_builder /build/geth /usr/local/bin/geth
COPY --from=asan_builder /build/geth /usr/local/bin/geth-asan
COPY --from=race_builder /build/geth /usr/local/bin/geth-race
COPY --from=msan_builder /build/geth /usr/local/bin/geth-msan


ENTRYPOINT ["/bin/bash"]
