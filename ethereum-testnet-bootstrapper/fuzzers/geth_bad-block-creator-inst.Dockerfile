FROM etb-client-builder as builder

COPY antitheis-rand-source__oracles.patch /opt/antithesis/patch/antithesis.patch

RUN git clone https://github.com/MariusVanDerWijden/go-ethereum.git \
    && cd go-ethereum \
    && git checkout merge-bad-block-creator \
    && git apply /opt/antithesis/patch/antithesis.patch\
    && make geth

FROM etb-client-runner

COPY --from=builder /git/go-ethereum/build/bin/geth /usr/local/bin/geth-bad-block

ENTRYPOINT ["/bin/bash"]
