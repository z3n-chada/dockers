from z3nchada/etb-client-builder:latest as builder

run rustup toolchain install nightly

workdir /git

run git clone https://github.com/sigp/lighthouse.git && cd lighthouse && git checkout unstable

from builder as default_builder

run cd lighthouse && RUSTFLAGS="-Zunstable-options" cargo +nightly build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

from builder as asan_builder
run cd lighthouse && RUSTFLAGS="-Zsanitizer=address" cargo +nightly build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

from builder as tsan_builder
run cd lighthouse && RUSTFLAGS="-Zsanitizer=thread" cargo +nightly build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

from builder as msan_builder
run cd lighthouse && RUSTFLAGS="-Zsanitizer=memory" cargo +nightly build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

from builder as leak_builder
run cd lighthouse && RUSTFLAGS="-Zsanitizer=leak" cargo +nightly build --release --manifest-path lighthouse/Cargo.toml --target x86_64-unknown-linux-gnu --features modern --verbose --bin lighthouse

from debian:bullseye-slim

copy --from=default_builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse
copy --from=asan_builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse-asan
copy --from=tsan_builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse-tsan
copy --from=msan_builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse-msan
copy --from=leak_builder /git/lighthouse/target/x86_64-unknown-linux-gnu/release/lighthouse /usr/local/bin/lighthouse-leak

ENTRYPOINT [""]
