###### VARIABLES

variable "jenkins_master_ami" {
  type = string
}

variable "jenkins_master_subnet_id" {
  type    = string
  default = "subnet-6c9a2b25"
}

variable "jenkins_master_vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "jenkins_master_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "jenkins_master_ssh_user" {
  type    = string
  default = "ec2-user"
}

variable "jenkins_agent_default_vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "jenkins_agent_default_ami" {
  type = string
}

locals {
  agents = <<EOT
  - amazonEC2:
      cloudName: default-agent
      useInstanceProfileForCredentials: true
      sshKeysCredentialsId: jenkins-agent-key-pair
      region: "eu-west-1"
      templates:
      - type: "T2Medium"
        ami: "${var.jenkins_agent_default_ami}"
        description: "AWS default agent"
        #"sub1 sub2 sub3" 
        subnetId: "subnet-6c9a2b25"
        remoteAdmin: ec2-user
        securityGroups: "${aws_security_group.jenkins_agent_sg.id}"
        monitoring: false
        minimumNumberOfSpareInstances: 0
        connectionStrategy: PRIVATE_IP
        associatePublicIp: false
  EOT
}