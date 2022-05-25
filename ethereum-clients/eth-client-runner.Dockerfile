from eth-client-builder as rocks_builder

workdir /git

RUN cd rocksdb && make clean && make -j32 shared_lib

run mkdir -p /rocksdb/lib && cd rocksdb && cp librocksdb.so* /rocksdb/lib/

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libpcre3-dev \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    build-essential \
    wget \
    tzdata \
    bash \
    python3-dev \
    gnupg \
    cmake \
    libc6-dev \
    libsnappy-dev \
    python3-dev \
    git

RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb

RUN apt update && apt install -y --no-install-recommends dotnet-runtime-6.0 aspnetcore-runtime-6.0

WORKDIR /git

RUN wget --no-check-certificate https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 15

ENV LLVM_CONFIG=llvm-config-15

# get go1.18
RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
RUN tar -zxvf go1.18.linux-amd64.tar.gz -C /usr/local/
RUN ln -s /usr/local/go/bin/go /usr/local/bin/go
RUN ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

run rm -rf /git/*

copy --from=rocks_builder /rocksdb/lib/ /usr/local/rocksdb/lib/

run cp /usr/local/rocksdb/lib/librocksdb.so* /usr/lib

