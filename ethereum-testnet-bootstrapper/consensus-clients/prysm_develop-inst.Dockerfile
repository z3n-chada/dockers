FROM z3nchada/etb-client-builder:latest as base

from base as builder

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
# Antithesis -------------------------------------------------
WORKDIR /git/src/github.com/prysmaticlabs
run mkdir prysm_instrumented && LD_LIBRARY_PATH=/opt/antithesis/go_instrumentation/lib /opt/antithesis/go_instrumentation/bin/goinstrumentor -stderrthreshold=INFO prysm prysm_instrumented
run cp -r prysm_instrumented/* prysm/
run cd prysm && go mod edit -require=antithesis.com/instrumentation/wrappers@v1.0.0 -replace antithesis.com/instrumentation/wrappers=/opt/antithesis/go_instrumentation/instrumentation/go/wrappers 
# Antithesis -------------------------------------------------
# Get dependencies
run cd prysm && go get -t -d ./...

#Build with instrumentation
RUN cd prysm && CGO_CFLAGS="-I/opt/antithesis/go_instrumentation/include" CGO_LDFLAGS="-L/opt/antithesis/go_instrumentation/lib" go build -o /build ./...
RUN go env GOPATH

from z3nchada/etb-client-runner

env LD_LIBRARY_PATH=/usr/lib/

COPY --from=builder /build/beacon-chain /usr/local/bin/
COPY --from=builder /build/validator /usr/local/bin/
COPY --from=builder /build/client-stats /usr/local/bin/

ENTRYPOINT ["/bin/bash"]
