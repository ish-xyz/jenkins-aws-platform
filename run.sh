#!/bin/bash
set -e

#DEPRECATED: This script will soon become a github action
echo "DEPRECATED: This script will soon become a github action"

build() {
    docker build -t hashitools:local .
}

create-image() {
    if ! [[ -d "./images/${1}" ]]; then
        echo "No such file or directory: ./images/${1}"
        exit 1
    fi

    docker run \
        -v $(pwd)/images/${1}:/mnt/packer \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/packer && packer build packer.json"
}

deploy() {
    echo "TODO"
}

main() {
    . .credz
    if [[ $1 == "create-image" ]]; then 
        build
        create-image $2
    fi
}

main $@
