from z3nchada/etb-client-builder:latest as base

# build besu; no instrumentation

WORKDIR /usr/src 

ARG BESU_BRANCH="develop"

from base as builder

RUN git clone --progress https://github.com/hyperledger/besu.git && cd besu && git checkout ${BESU_BRANCH} && ./gradlew installDist

from debian:bullseye-slim

RUN apt update && apt install -y --no-install-recommends \
    openjdk-17-jre 

COPY --from=builder /usr/src/besu/build/install/besu/. /opt/besu/

ENTRYPOINT ["/bin/bash"]
