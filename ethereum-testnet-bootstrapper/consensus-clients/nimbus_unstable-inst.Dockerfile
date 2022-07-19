FROM z3nchada/etb-client-builder:latest as builder

WORKDIR /git
# Included here to avoid build-time complaints
ARG BRANCH="unstable"

RUN git clone https://github.com/status-im/nimbus-eth2.git

RUN cd nimbus-eth2 && git checkout ${BRANCH}

RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-15 --clang.linkerexe:clang-15 --passC:'-fno-lto -fsanitize-coverage=trace-pc-guard' --passL:'-fno-lto -L/usr/lib/ -lvoidstar'" \
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-15 --clang.linkerexe:clang-15 --passC:'-fno-lto -fsanitize-coverage=trace-pc-guard' --passL:'-fno-lto -L/usr/lib/ -lvoidstar'"

RUN cd nimbus-eth2 && git log -n 1 --format=format:"%H" > /nimbus.version
from z3nchada/etb-client-runner:latest

COPY --from=builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node
COPY --from=builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client
COPY --from=builder /nimbus.version /nimbus.version
