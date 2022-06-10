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

run git clone --depth 1 --recurse-submodules -j8 \
	https://github.com/ledgerwatch/erigon.git -b ${erigon_branch}

run cd erigon/ \
    && make erigon

RUN cd erigon && git log -n 1 --format=format:"%H" > /erigon.version
from debian:bullseye-slim

copy --from=builder /git/erigon/build/bin/erigon /usr/local/bin/erigon
COPY --from=builder /erigon.version /erigon.version

ENTRYPOINT ["/bin/bash"]
