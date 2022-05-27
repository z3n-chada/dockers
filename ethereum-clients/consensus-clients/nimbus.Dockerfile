# Build Nimbus in a stock debian container
FROM debian:bullseye-slim as builder

WORKDIR /git
# Included here to avoid build-time complaints
ARG BRANCH="kiln-dev-auth"

RUN apt-get update && apt-get install -y build-essential git libpcre3-dev ca-certificates wget lsb-release wget software-properties-common

RUN wget --no-check-certificate https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 13

ENV LLVM_CONFIG=llvm-config-13

RUN git clone https://github.com/status-im/nimbus-eth2.git

RUN cd nimbus-eth2 && git checkout ${BRANCH}

from builder as default_builder
RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13"\
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13"

from builder as asan_builder
RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-g -fsanitize=address\" --passL:\"-fsanitize=address\"" \
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-fsanitize=address\" --passL:\"-fsanitize=address\""

from builder as tsan_builder
RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-g -fsanitize=thread\" --passL:\"-fsanitize=thread\"" \
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-fsanitize=thread\" --passL:\"-fsanitize=thread\""

from builder as ubsan_builder
RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-g -fsanitize=undefined\" --passL:\"-fsanitize=undefined\"" \
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-fsanitize=undefined\" --passL:\"-fsanitize=undefined\""

from builder as msan_builder
RUN cd nimbus-eth2 && make -j64 nimbus_beacon_node NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-g -fsanitize=undefined\" --passL:\"-fsanitize=memory\"" \
                   && make -j64 nimbus_validator_client NIMFLAGS="--cc:clang --clang.exe:clang-13 --clang.linkerexe:clang-13 --passC:\"-fsanitize=undefined\" --passL:\"-fsanitize=memory\""

# Pull all binaries into a second stage deploy debian container
FROM debian:bullseye-slim as base

# Copy executable
COPY --from=default_builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node
COPY --from=default_builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client
COPY --from=asan_builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node-asan
COPY --from=asan_builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client-asan
COPY --from=tsan_builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node-tsan
COPY --from=tsan_builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client-tsan
COPY --from=msan_builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node-msan
COPY --from=msan_builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client-msan
COPY --from=ubsan_builder /git/nimbus-eth2/build/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node-ubsan
COPY --from=ubsan_builder /git/nimbus-eth2/build/nimbus_validator_client /usr/local/bin/nimbus_validator_client-ubsan


env MSAN_SYMBOLIZER_PATH=llvm-symbolizer-13
# run ln -s /usr/local/bin/nimbus_beacon_node-msan /usr/local/bin/nimbus_beacon_node
# run ln -s /usr/local/bin/nimbus_validator_client-msan /usr/local/bin/nimbus_validator_client

env ASAN_SYMBOLIZER_PATH=llvm-symbolizer-13
#run ln -s /usr/local/bin/nimbus_beacon_node-asan /usr/local/bin/nimbus_beacon_node
#run ln -s /usr/local/bin/nimbus_validator_client-asan /usr/local/bin/nimbus_validator_client

env TSAN_OPTIONS="external_symbolizer_path=llvm-symbolizer-13"
# run ln -s /usr/local/bin/nimbus_beacon_node-tsan /usr/local/bin/nimbus_beacon_node
# run ln -s /usr/local/bin/nimbus_validator_client-tsan /usr/local/bin/nimbus_validator_client

ENTRYPOINT [""]
