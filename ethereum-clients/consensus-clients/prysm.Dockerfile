from z3nchada/etb-client-builder:latest as builder

# requires go 1.18
run rm /usr/local/bin/gofmt
run rm /usr/local/bin/go
run rm -r /usr/local/go

RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
RUN tar -zxvf go1.18.linux-amd64.tar.gz -C /usr/local/
RUN ln -s /usr/local/go/bin/go /usr/local/bin/go
RUN ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

RUN mkdir -p /build && mkdir -p /git

ENV GOPATH="/git"
ARG GIT_BRANCH="develop"
# Install prysm

RUN mkdir -p /git/src/github.com/prysmaticlabs/

workdir /git/src/github.com/prysmaticlabs/prysm

RUN cd /git/src/github.com/prysmaticlabs/ && \
    git clone --branch "$GIT_BRANCH" \
    --recurse-submodules \
    --depth 1 \
    https://github.com/prysmaticlabs/prysm

# Get dependencies
RUN go get -t -d ./... 

from builder as default_builder

run go build -o /build ./...

from builder as race_builder
run go build -race -o /build ./...

from builder as asan_builder
run go build -asan -o /build ./...

# FROM z3nchada/etb-client-runner:latest
# 
# RUN apt-get update && apt-get install -y --no-install-recommends \
#   ca-certificates curl bash tzdata \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*
from debian:bullseye-slim

# Copy executable
COPY --from=default_builder /build/beacon-chain /usr/local/bin/
COPY --from=default_builder /build/validator /usr/local/bin/
COPY --from=race_builder /build/beacon-chain /usr/local/bin/beacon-chain-race
COPY --from=race_builder /build/validator /usr/local/bin/validator-race
COPY --from=asan_builder /build/beacon-chain /usr/local/bin/beacon-chain-asan
COPY --from=asan_builder /build/validator /usr/local/bin/validator-asan

ENTRYPOINT [""]
