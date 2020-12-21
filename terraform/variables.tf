###### VARIABLES

variable "jenkins_master_ami" {
  type    = string
}

variable "jenkins_master_subnet_id" {
  type    = string
  default = "subnet-6c9a2b25"
}

variable "jenkins_agents_subnet_ids" {
  type = list(string)
  default = ["subnet-6c9a2b25"]
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

variable "jenkins_agent_vpc_id" {
    type = string
    default = "vpc-f670c791"
}