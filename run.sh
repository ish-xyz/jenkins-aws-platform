#!/bin/bash
set -e

build() {
    docker build -t hashitools:local .
}

helper() {
    echo """
usage: ./run.sh
    
create-image {{ image_folder_name }} - Create the Jenkins AMI

deploy  - Create the infrastructure

destroy - Destroy the infrastructure

help    - Shows this help message

"""
}

create-image() {
    if ! [[ -d "./images/${1}" ]]; then
        echo "No such file or directory: ./images/${1}"
        exit 1
    fi

    docker run \
        -v $(pwd)/images/${1}:/mnt/packer \
        -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/packer && packer build packer.json"
}

run_terraform() {
    JENKINS_MASTER_AMI_ID=$(cat images/master/manifest.json | jq '.builds | last | .artifact_id' | awk -F ":" {'print $2'} | awk -F '"' {'print $1'})
    JENKINS_DEFAULT_AGENT_AMI_ID=$(cat images/default-agent/manifest.json | jq '.builds | last | .artifact_id' | awk -F ":" {'print $2'} | awk -F '"' {'print $1'})
    docker run \
        -v $(pwd)/terraform:/mnt/terraform \
        -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/terraform && terraform init && terraform $1 \
        -var=\"jenkins_agent_ami_id=${JENKINS_DEFAULT_AGENT_AMI_ID}\" \
        -var=\"jenkins_master_ami=${JENKINS_MASTER_AMI_ID}\" -auto-approve"
}

main() {
    . .credz
    if [[ $1 == "create-image" ]]; then 
        build
        create-image $2
    elif [[ $1 == "deploy" ]]; then
        build
        run_terraform apply
    elif [[ $1 == "destroy" ]]; then
        build
        run_terraform destroy
    else
        helper
    fi
}

main $@
