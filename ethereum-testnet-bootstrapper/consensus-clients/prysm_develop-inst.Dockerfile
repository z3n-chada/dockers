FROM z3nchada/etb-client-builder:latest as base

FROM base as builder

WORKDIR /git

ARG GIT_BRANCH="develop"

RUN mkdir -p /git/src/github.com/prysmaticlabs/
RUN mkdir -p /build

RUN cd /git/src/github.com/prysmaticlabs/ && \
    git clone --branch "$GIT_BRANCH" \
    --recurse-submodules \
    --depth 1 \
    https://github.com/prysmaticlabs/prysm

#Antithesis Instrumentation

# excluding snappy compression
RUN touch /opt/antithesis/go_instrumentation/exclusions.txt & \
echo "beacon-chain/state/genesis/genesis.go\n\
beacon-chain/p2p/encoder/ssz.go\n\
beacon-chain/p2p/encoder/message_id.go\n\
beacon-chain/db/kv/encoding.go\n\
beacon-chain/p2p/encoder/ssz_test.go\n\
beacon-chain/p2p/encoder/message_id_test.go\n\
testing" >> /opt/antithesis/go_instrumentation/exclusions.txt & cat /opt/antithesis/go_instrumentation/exclusions.txt

# Antithesis -------------------------------------------------
WORKDIR /git/src/github.com/prysmaticlabs
RUN mkdir -p prysm_instrumented && LD_LIBRARY_PATH=/opt/antithesis/go_instrumentation/lib /opt/antithesis/go_instrumentation/bin/goinstrumentor -antithesis=/opt/antithesis/go_instrumentation/instrumentation/go/wrappers/ -exclude=/opt/antithesis/go_instrumentation/exclusions.txt -stderrthreshold=INFO prysm prysm_instrumented
RUN cp -r prysm_instrumented/customer/* prysm/
RUN cd prysm && go mod edit -require=antithesis.com/instrumentation/wrappers@v1.0.0 -replace antithesis.com/instrumentation/wrappers=/opt/antithesis/go_instrumentation/instrumentation/go/wrappers 
# Antithesis -------------------------------------------------
# Get dependencies
RUN cd /git/src/github.com/prysmaticlabs/prysm && go get -t -d ./...

#Build with instrumentation
RUN cd /git/src/github.com/prysmaticlabs/prysm && CGO_CFLAGS="-I/opt/antithesis/go_instrumentation/include" CGO_LDFLAGS="-L/opt/antithesis/go_instrumentation/lib" go build -o /build ./...
RUN go env GOPATH

FROM z3nchada/etb-client-runner

ENV LD_LIBRARY_PATH=/usr/lib/

COPY --from=builder /build/beacon-chain /usr/local/bin/
COPY --from=builder /build/validator /usr/local/bin/
COPY --from=builder /build/client-stats /usr/local/bin/
COPY --from=builder /git/src/github.com/prysmaticlabs/prysm_instrumented/symbols/* /opt/antithesis/symbols/


ENTRYPOINT ["/bin/bash"]
