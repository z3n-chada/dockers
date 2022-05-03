from etb-client-builder:latest as builder

workdir /git

run git clone https://github.com/sigp/lighthouse.git && cd lighthouse && git checkout unstable

RUN cd lighthouse && LD_LIBRARY_PATH=/usr/lib/ RUSTFLAGS="-Cpasses=sancov -Cllvm-args=-sanitizer-coverage-level=3 -Cllvm-args=-sanitizer-coverage-trace-pc-guard -Ccodegen-units=1 -Cdebuginfo=2 -L/usr/lib/ -lvoidstar" cargo build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse


from z3nchada/etb-client-runner:latest

env LD_LIBRARY_PATH=/usr/lib/

copy --from=builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse

ENTRYPOINT ["/bin/bash"]
