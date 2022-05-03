# build the base-images (note not needed since they pull from z3nchada/<>) uncomment to update them.

cd base-images

docker build -t etb-client-builder -f etb-client-builder.Dockerfile .
docker build -t etb-client-runner -f etb-client-runner.Dockerfile .

cd ../

# next build the fuzzers

cd fuzzers

./build_dockers.sh

cd ../

# next build the execution-clients and consensus clients.

cd execution-clients

echo "Building execution clients"

./build_dockers.sh

cd ../

cd consensus-clients

echo "Building consensus-clients"

./build_dockers.sh

cd ../

# now that we have all the prereqs build the etb-client images.

cd etb-clients

docker build -t etb-all-clients:latest -f etb-all-clients.Dockerfile
docker build -t etb-all-clients:latest-inst -f etb-all-clients_inst.Dockerfile

cd ../

# lastly we can go ahead and build the ethereum-testnet-boostrapper

# mkdir tmp
# 
# cd tmp
# 
# git clone git@github.com:z3n-chada/ethereum-testnet-bootstrapper.git
# 
# cd ethereum-testnet-boostrapper
# 
# make build-bootstrapper
# 
# cd ../../
# 
# rm -rf tmp
