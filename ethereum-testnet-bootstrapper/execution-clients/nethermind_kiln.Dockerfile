# from debian:bullseye-slim as base
# 
# RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev make g++
# 
# RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
# 
# RUN apt update && apt install -y --no-install-recommends dotnet-runtime-6.0 aspnetcore-runtime-6.0
# 
# from z3nchada/etb-client-builder:latest as rocks_builder
# 
# workdir /git
# 
# # run apt install -y --no-install-recommends git
# # 
# # RUN git clone https://github.com/facebook/rocksdb.git 
# 
# RUN cd rocksdb && make clean && make -j32 shared_lib
# 
# run mkdir -p /rocksdb/lib && cd rocksdb && cp librocksdb.so* /rocksdb/lib/

from z3nchada/etb-client-builder:latest as builder

WORKDIR /git

ARG NETHERMIND_BRANCH="kiln"

RUN git clone https://github.com/NethermindEth/nethermind && cd nethermind && git checkout ${NETHERMIND_BRANCH}

RUN cd nethermind && git submodule update --init src/Dirichlet src/int256 src/rocksdb-sharp src/Math.Gmp.Native

RUN cd /git/nethermind &&  dotnet publish src/Nethermind/Nethermind.Runner -c release -o out

RUN cd /git/nethermind && git log -n 1 --format=format:"%H" > /nethermind.version

from z3nchada/etb-client-runner:latest 

RUN apt remove git wget ca-certificates make g++ -y \
    && apt autoremove -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /git/nethermind/out /nethermind/
COPY --from=builder /nethermind.version /nethermind.version

RUN chmod +x /nethermind/Nethermind.Runner

entrypoint ["/bin/bash"]
