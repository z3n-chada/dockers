#!/usr/bin/env bash
# build the base-images (note not needed since they pull from z3nchada/<>) uncomment to update them.

export FAILED_IMAGES_LOG=`pwd`/failed_images.log
echo -n > $FAILED_IMAGES_LOG
# Import `record_image_failure` function
source ./common.sh

cd base-images

docker build -t etb-client-builder -f etb-client-builder.Dockerfile . || record_image_failure "etb-client-builder"
docker build -t etb-client-runner -f etb-client-runner.Dockerfile . || record_image_failure "etb-client-runner"

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

docker build -t etb-all-clients:latest -f etb-all-clients.Dockerfile || record_image_failure "etb-all-clients:latest"
docker build -t etb-all-clients:latest-inst -f etb-all-clients_inst.Dockerfile  || record_image_failure "etb-all-clients:latest-inst"

# Check if log contains entries
if [ -s $FAILED_IMAGES_LOG ]; then
	printf "\n\n"
	RED='\033[0;31m'
	NO_COLOR='\033[0m'
	printf "${RED}The following images failed to build:${NO_COLOR}\n"
	cat $FAILED_IMAGES_LOG
	printf "\n\n"
else
	rm $FAILED_IMAGES_LOG
	echo "Done: etb-all-clients built successfully."
fi
