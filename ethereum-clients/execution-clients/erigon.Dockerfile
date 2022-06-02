from eth-client-builder as builder

workdir /git

arg erigon_branch="devel"

run mkdir -p /build

WORKDIR /go/src/github.com/ledgerwatch/

run git clone https://github.com/ledgerwatch/erigon.git \
    && cd erigon \
    && git checkout ${erigon_branch} \
    && git submodule update --init

run cd erigon && go get -t ./...

from builder as default_builder

run cd erigon/cmd/erigon && go build -o /build

from builder as race_builder

run cd erigon/cmd/erigon && go build -race -o /build

from builder as asan_builder

run cd erigon/cmd/erigon && go build -asan -o /build

# msan not working
# github.com/torquem-ch/mdbx-go/mdbx
#In file included from _cgo_export.c:4:
#In file included from msgfunc.go:4:
#/root/go/pkg/mod/github.com/torquem-ch/mdbx-go@v0.24.1/mdbx/mdbxgo.h:47:47: error: a function declaration without a prototype is deprecated in all versions of C [-Werror,-Wstrict-prototypes]
## github.com/ledgerwatch/secp256k1
#cgo: malformed DWARF TagVariable entry

# from builder as msan_builder
# 
# WORKDIR /go/src/github.com/ledgerwatch/erigon/cmd/erigon
# run go env -w "CC=clang-15"
# run go env -w "CXX=clang-cpp-15"
# run go env -w "AR=llvm-ar-15"
# run go build -msan -o /build

from eth-client-runner

env MSAN_SYMBOLIZER_PATH=llvm-symbolizer-15
copy --from=default_builder /build/erigon /usr/local/bin/erigon
copy --from=race_builder /build/erigon /usr/local/bin/erigon-race
copy --from=asan_builder /build/erigon /usr/local/bin/erigon-asan

ENTRYPOINT ["/bin/bash"]
