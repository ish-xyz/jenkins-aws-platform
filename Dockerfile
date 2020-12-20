FROM alpine:3.12

RUN wget -O /tmp/packer.zip https://releases.hashicorp.com/packer/1.6.5/packer_1.6.5_linux_amd64.zip && \
    unzip /tmp/packer.zip -d /usr/local/bin/ 

RUN wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin/

