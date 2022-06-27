from etb-client-builder:latest as builder

# requires go 1.18
run rm /usr/local/bin/gofmt
run rm /usr/local/bin/go
run rm -r /usr/local/go

RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
RUN tar -zxvf go1.18.linux-amd64.tar.gz -C /usr/local/
RUN ln -s /usr/local/go/bin/go /usr/local/bin/go
RUN ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

workdir /git

arg erigon_branch="devel"

run mkdir -p /build

# TODO: Adding --depth 1 sometimes causes issues for some reason
run git clone --recurse-submodules -j8 \
	https://github.com/ledgerwatch/erigon.git -b ${erigon_branch}

# add items to this exclusions list to exclude them from instrumentation
RUN touch /opt/antithesis/go_instrumentation/exclusions.txt
# These exclusions are mostly due to this issue:
# https://trello.com/c/Wmaxylu9/1271-go-instrumentor-strips-out-v117-conditional-compilation-comments-directives
RUN echo "accounts/abi/bind/bind.go\n\
accounts/abi/bind/template.go\n\
cmd/cons/commands/clique.go\n\
cmd/downloader/trackers/embed.go\n\
cmd/evm/internal/t8ntool/execution.go\n\
cmd/observer/observer/handshake.go\n\
cmd/pics/contracts/gen.go\n\
cmd/rpcdaemon22/commands/contracts/gen.go\n\
cmd/rpcdaemon/commands/contracts/gen.go\n\
common/debug/pprof_cgo.go\n\
common/fdlimit/fdlimit_bsd.go\n\
common/fdlimit/fdlimit_unix.go\n\
common/mclock/mclock.go\n\
consensus/aura/auraabi/abi.go\n\
consensus/aura/consensusconfig/embed.go\n\
consensus/aura/contracts/embed.go\n\
consensus/aura/test/embed.go\n\
core/genesis.go\n\
core/mkalloc.go\n\
core/state/contracts/gen.go\n\
core/types/access_list_tx.go\n\
core/types/block.go\n\
core/types/log.go\n\
core/types/receipt_codecgen_gen.go\n\
core/types/receipt.go\n\
core/vm/lightclient/multistoreproof.go\n\
core/vm/logger.go\n\
crypto/\n\
eth/ethconfig/config.go\n\
eth/gasprice/gasprice.go\n\
eth/stagedsync/stage_mining_create_block.go\n\
eth/tracers/internal/tracers/tracers.go\n\
internal/debug/loudpanic_fallback.go\n\
internal/debug/loudpanic.go\n\
internal/debug/signal.go\n\
internal/debug/signal_windows.go\n\
internal/debug/trace_fallback.go\n\
internal/debug/trace.go\n\
p2p/netutil/toobig_notwindows.go\n\
p2p/netutil/toobig_windows.go\n\
p2p/peer.go\n\
p2p/rlpx/rlpx.go\n\
p2p/transport.go\n\
params/config.go\n\
rules.go\n\
tests/contracts/gen.go\n\
tests/fuzzers/bls12381/bls12381_fuzz.go\n\
tools.go\n\
turbo/rlphacks/utils_bytes.go\n\
turbo/snapshotsync/snapshothashes/embed.go\n\
turbo/trie/trie_root.go" >> /opt/antithesis/go_instrumentation/exclusions.txt

# Antithesis -------------------------------------------------
WORKDIR /git
RUN mkdir -p erigon_instrumented && LD_LIBRARY_PATH=/opt/antithesis/go_instrumentation/lib /opt/antithesis/go_instrumentation/bin/goinstrumentor -antithesis=/opt/antithesis/go_instrumentation/instrumentation/go/wrappers/ -exclude=/opt/antithesis/go_instrumentation/exclusions.txt -stderrthreshold=INFO erigon erigon_instrumented
RUN cp -r erigon_instrumented/customer/* erigon/
RUN cd erigon && go mod edit -require=antithesis.com/instrumentation/wrappers@v1.0.0 -replace antithesis.com/instrumentation/wrappers=/opt/antithesis/go_instrumentation/instrumentation/go/wrappers
# Antithesis -------------------------------------------------

RUN cd erigon/ \
    && CGO_CFLAGS="-I/opt/antithesis/go_instrumentation/include" CGO_LDFLAGS="-L/opt/antithesis/go_instrumentation/lib" make erigon

RUN cd erigon && git log -n 1 --format=format:"%H" > /erigon.version
FROM etb-client-runner

copy --from=builder /git/erigon/build/bin/erigon /usr/local/bin/erigon
COPY --from=builder /git/erigon_instrumented/symbols/* /opt/antithesis/symbols/
COPY --from=builder /erigon.version /erigon.version

ENTRYPOINT ["/bin/bash"]
