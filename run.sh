#!/bin/bash
set -e

helper() {
    echo """
usage: ./run.sh
    
create-image {{ image_folder_name }} - Create the Jenkins AMIs

deploy  - Create the infrastructure

destroy - Destroy the infrastructure

help    - Shows this help message

"""
}

build_docker_image() {
    docker build -t hashitools:local .
}

get_ami_id() {
    cat $1 | jq '.builds | last | .artifact_id' | awk -F ":" {'print $2'} | awk -F '"' {'print $1'}
}

run_packer() {

    # Check if the Packer dir exist
    if ! [[ -d "./images/${1}" ]]; then
        echo "No such file or directory: ./images/${1}"
        exit 1
    fi

    # Run Packer
    docker run \
        -v $(pwd)/images/${1}:/mnt/packer \
        -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/packer && packer build packer.json"
}

run_terraform() {

    # Building Terraform arguments
    tf_args="-var=\"jenkins_master_ami=$(get_ami_id images/master/manifest.json)\""
    for agent_ami in $(ls images/agents/); do
        ami_id=$(get_ami_id images/agents/${agent_ami}/manifest.json)
        tf_args="${tf_args} -var=\"${agent_ami}_agent_ami=${ami_id}\""
    done
    tf_args="${tf_args} -auto-approve"
    
    # Run Terraform
    docker run \
        -v $(pwd)/terraform:/mnt/terraform \
        -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
        -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --rm \
        hashitools:local sh -c "cd /mnt/terraform && terraform init && terraform $1 $tf_args"
}

main() {
    # Load credentials
    . .credz

    if [[ $1 == "create-image" ]]; then 
        build_docker_image
        run_packer $2
    elif [[ $1 == "deploy" ]]; then
        build_docker_image
        run_terraform apply
    elif [[ $1 == "destroy" ]]; then
        build_docker_image
        run_terraform destroy
    else
        helper
    fi
}

main $@
