FROM etb-client-builder:latest as base

FROM base as builder

# requires go 1.18
run rm /usr/local/bin/gofmt
run rm /usr/local/bin/go
run rm -r /usr/local/go

RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
RUN tar -zxvf go1.18.linux-amd64.tar.gz -C /usr/local/
RUN ln -s /usr/local/go/bin/go /usr/local/bin/go
RUN ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

WORKDIR /git

ARG GIT_BRANCH="develop"

RUN mkdir -p /git/src/github.com/prysmaticlabs/
RUN mkdir -p /build

RUN cd /git/src/github.com/prysmaticlabs/ && \
    git clone --branch "$GIT_BRANCH" \
    --recurse-submodules \
    --depth 1 \
    https://github.com/prysmaticlabs/prysm

RUN cd /git/src/github.com/prysmaticlabs/prysm && git log -n 1 --format=format:"%H" > /prysm.version

#Antithesis Instrumentation

# excluding snappy compression
RUN touch /opt/antithesis/go_instrumentation/exclusions.txt && \
echo "beacon-chain/blockchain/checktags_test.go\n\
beacon-chain/cache/active_balance_disabled.go\n\
beacon-chain/cache/active_balance.go\n\
beacon-chain/cache/active_balance_test.go\n\
beacon-chain/cache/committee_disabled.go\n\
beacon-chain/cache/committee_fuzz_test.go\n\
beacon-chain/cache/committee.go\n\
beacon-chain/cache/committee_test.go\n\
beacon-chain/cache/proposer_indices_disabled.go\n\
beacon-chain/cache/proposer_indices.go\n\
beacon-chain/cache/proposer_indices_test.go\n\
beacon-chain/cache/sync_committee_disabled.go\n\
beacon-chain/cache/sync_committee.go\n\
beacon-chain/p2p/pubsub_fuzz_test.go\n\
beacon-chain/state/state-native/beacon_state_mainnet.go\n\
beacon-chain/state/state-native/beacon_state_mainnet_test.go\n\
beacon-chain/state/state-native/beacon_state_minimal.go\n\
beacon-chain/state/state-native/beacon_state_minimal_test.go\n\
beacon-chain/state/v1/state_fuzz_test.go\n\
beacon-chain/state/v2/state_fuzz_test.go\n\
beacon-chain/state/v3/state_fuzz_test.go\n\
beacon-chain/sync/fuzz_exports.go\n\
beacon-chain/sync/sync_fuzz_test.go\n\
build/bazel/bazel.go\n\
build/bazel/non_bazel.go\n\
config/fieldparams/mainnet.go\n\
config/fieldparams/mainnet_test.go\n\
config/fieldparams/minimal.go\n\
config/fieldparams/minimal_test.go\n\
config/params/checktags_test.go\n\
config/params/config_utils_develop.go\n\
config/params/config_utils_prod.go\n\
crypto/bls/blst/aliases.go\n\
crypto/bls/blst/bls_benchmark_test.go\n\
crypto/bls/blst/init.go\n\
crypto/bls/blst/public_key.go\n\
crypto/bls/blst/public_key_test.go\n\
crypto/bls/blst/secret_key.go\n\
crypto/bls/blst/secret_key_test.go\n\
crypto/bls/blst/signature.go\n\
crypto/bls/blst/signature_test.go\n\
crypto/bls/blst/stub.go\n\
encoding/ssz/htrutils_fuzz_test.go\n\
monitoring/journald/journald.go\n\
monitoring/journald/journald_linux.go\n\
proto/eth/v1/attestation.pb.gw.go\n\
proto/eth/v1/beacon_block.pb.gw.go\n\
proto/eth/v1/beacon_chain.pb.gw.go\n\
proto/eth/v1/beacon_state.pb.gw.go\n\
proto/eth/v1/events.pb.gw.go\n\
proto/eth/v1/node.pb.gw.go\n\
proto/eth/v1/validator.pb.gw.go\n\
proto/eth/v2/beacon_block.pb.gw.go\n\
proto/eth/v2/beacon_state.pb.gw.go\n\
proto/eth/v2/ssz.pb.gw.go\n\
proto/eth/v2/sync_committee.pb.gw.go\n\
proto/eth/v2/validator.pb.gw.go\n\
proto/eth/v2/version.pb.gw.go\n\
proto/prysm/v1alpha1/attestation.pb.gw.go\n\
proto/prysm/v1alpha1/beacon_block.pb.gw.go\n\
proto/prysm/v1alpha1/beacon_state.pb.gw.go\n\
proto/prysm/v1alpha1/finalized_block_root_container.pb.gw.go\n\
proto/prysm/v1alpha1/p2p_messages.pb.gw.go\n\
proto/prysm/v1alpha1/powchain.pb.gw.go\n\
proto/prysm/v1alpha1/sync_committee_mainnet.go\n\
proto/prysm/v1alpha1/sync_committee_minimal.go\n\
proto/prysm/v1alpha1/sync_committee.pb.gw.go\n\
proto/testing/gocast.go\n\
runtime/debug/cgo_symbolizer.go\n\
validator/accounts/wallet_recover_fuzz_test.go" >> /opt/antithesis/go_instrumentation/exclusions.txt && cat /opt/antithesis/go_instrumentation/exclusions.txt

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
COPY --from=builder /prysm.version /prysm.version
COPY --from=builder /git/src/github.com/prysmaticlabs/* /git/src/github.com/prysmaticlabs/

ENTRYPOINT ["/bin/bash"]
