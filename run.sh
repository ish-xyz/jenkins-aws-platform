#!/bin/bash
set -e

build() {
    docker build -t hashitools:local .
}

helper() {
    echo """
    ./run.sh create-image master
    ./run.sh deploy    
    """
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
    JENKINS_MASTER_AMI_ID=$(cat images/master/manifest.json | jq '.builds | last | .artifact_id' | awk -F ":" {'print $2'} | awk -F '"' {'print $1'})
    docker run \
        -v $(pwd)/terraform:/mnt/terraform \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/terraform && terraform init && terraform apply -var=\"jenkins_master_ami=${JENKINS_MASTER_AMI_ID}\" -auto-approve"
}

main() {
    . .credz
    if [[ $1 == "create-image" ]]; then 
        build
        create-image $2
    elif [[ $1 == "deploy" ]]; then
        build
        deploy
    else
        helper
    fi
}

main $@
