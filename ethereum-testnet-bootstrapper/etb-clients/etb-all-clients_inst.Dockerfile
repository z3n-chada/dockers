# all of the built execution clients.
from besu:main as besu_builder
from erigon:devel as erigon_builder
from geth:master as geth_builder
from nethermind:kiln as nethermind_builder
from geth:bad-block-creator as geth_bad_block_builder
from tx-fuzzer:latest as tx_fuzzer_builder
from lighthouse:unstable-inst as lh_builder
from nimbus:kiln-dev-auth-inst as nimbus_builder
from prysm:develop-inst as prysm_builder
from teku:master as teku_builder
from lodestar:master as ls_builder

from z3nchada/etb-client-runner:latest

# now copy in all the execution clients.

copy --from=tx_fuzzer_builder /run/tx-fuzz.bin /usr/local/bin/tx-fuzz
copy --from=geth_bad_block_builder /usr/local/bin/geth-bad-block /usr/local/bin/geth-bad-block-creator
copy --from=geth_builder /usr/local/bin/geth /usr/local/bin/geth
copy --from=geth_builder /usr/local/bin/bootnode /usr/local/bin/bootnode
copy --from=besu_builder /opt/besu /opt/besu
run ln -s /opt/besu/bin/besu /usr/local/bin/besu 
copy --from=nethermind_builder /nethermind/ /nethermind/
run ln -s /nethermind/Nethermind.Runner /usr/local/bin/nethermind
copy --from=erigon_builder /usr/local/bin/erigon /usr/local/bin/erigon

# copy in all of the consensus clients
env LD_LIBRARY_PATH=/usr/lib

copy --from=lh_builder /usr/local/bin/lighthouse /usr/local/bin/lighthouse
copy --from=nimbus_builder /usr/local/bin/nimbus_beacon_node /usr/local/bin/nimbus_beacon_node
copy --from=nimbus_builder /usr/local/bin/nimbus_validator_client /usr/local/bin/nimbus_validator_client
copy --from=prysm_builder /usr/local/bin/beacon-chain /usr/local/bin/beacon-chain
copy --from=prysm_builder /usr/local/bin/validator /usr/local/bin/validator
copy --from=teku_builder /opt/teku /opt/teku
run ln -s /opt/teku/bin/teku /usr/local/bin/teku
copy --from=ls_builder /usr/app/ /usr/app/
run ln -s /usr/app/node_modules/.bin/lodestar /usr/local/bin/lodestar

entrypoint ["/bin/bash"]
