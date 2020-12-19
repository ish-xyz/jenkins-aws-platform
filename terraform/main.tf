# TODO
# Fix template jenkins.yaml
# take AMI-ID as parameter (variable) X

###### VARIABLES

variable "jenkins_master_ami" {
  type  = string
  value = "ami-07368ad06dc497686"
}

variable "jenkins_master_subnet_id" {
  type  = string
  value = "subnet-6c9a2b25"
}

variable "jenkins_master_vpc_id" {
  type  = string
  value = "vpc-f670c791"
}

variable "jenkins_master_instance_type" {
  type  = string
  value = "t2.medium"
}

###### SLAVE KEY

resource "tls_private_key" "jenkins_slave" {
  algorithm = "RSA"
}

resource "aws_key_pair" "jenkins_slave" {
  key_name   = "jenkins-slave"
  public_key = tls_private_key.jenkins_slave.public_key_openssh
}

resource "aws_secretsmanager_secret_version" "jenkins_slave_key" {
  secret_id     = aws_secretsmanager_secret.jenkins_slave_key.id
  secret_string = tls_private_key.jenkins_slave.private_key_pem
}

resource "aws_secretsmanager_secret" "jenkins_slave_key" {
  name = "jenkins-slave-key"
}

###### MASTER KEY

resource "tls_private_key" "jenkins_master" {
  algorithm = "RSA"
}

resource "aws_key_pair" "jenkins_master" {
  key_name   = "jenkins-master"
  public_key = tls_private_key.jenkins_master.public_key_openssh
}

resource "aws_secretsmanager_secret_version" "jenkins_master_key" {
  secret_id     = aws_secretsmanager_secret.jenkins_master_key.id
  secret_string = tls_private_key.jenkins_master.private_key_pem
}

resource "aws_secretsmanager_secret" "jenkins_master_key" {
  name = "jenkins-master-key"
}

###### IAM ROLE

resource "aws_iam_role" "jenkins_master_role" {
  name = "jenkins_master_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
}
EOF
}

resource "aws_iam_policy" "jenkins_master_policy" {
  name        = "jenkins_master_policy"
  description = "Jenkins Master Policy for Role. Provides EC2 Full access and secrets manager reader acces"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "ec2:*",
                "secretsmanager:ListSecretVersionIds",
                "secretsmanager:ListSecrets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins_master_role_attach" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = aws_iam_policy.jenkins_master_policy.arn
}

##### JENKINS MASTER INSTANCE PROFILE

resource "aws_iam_instance_profile" "jenkins_master_instance_profile" {
  name = "jenkins_master_instance_profile"
  role = aws_iam_role.jenkins_master_role.name
}

##### JENKINS MASTER SECURITY GROUP

resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins_master_sg"
  description = "Allow HTTP/HTTPS/SSH to 0.0.0.0 and all egress connections"
  vpc_id      = var.jenkins_master_vpc_id

  tags = {
    Name = "jenkins_master_sg"
  }
}


resource "aws_security_group_rule" "jenkins_master_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_master_sg.id
}

resource "aws_security_group_rule" "jenkins_master_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_master_sg.id
}

resource "aws_security_group_rule" "jenkins_master_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_master_sg.id
}

resource "aws_security_group_rule" "jenkins_master_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_master_sg.id
}

##### JENKINS MASTER EC2 INSTANCE

module "jenkins_master_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "jenkins_master"
  instance_count = 1

  ami                         = var.jenkins_master_ami
  instance_type               = var.jenkins_master_instance_type
  key_name                    = aws_key_pair.jenkins_master.name
  monitoring                  = true
  associate_public_ip_address = true
  instance_profile            = aws_iam_instance_profile.jenkins_master_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.jenkins_master_sg.id]
  subnet_id                   = var.jenkins_master_subnet_id

  tags = {
    Name       = "jenkins_master"
    created_by = "terraform"
  }
}

##### IMPORT CASC CONFIGURATION AND RESTART JENKINS

resource "null_resource" "jenkins_master_configuration" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    id = uuid()
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = module.jenkins_master_ec2.public_ip
  }

  provisioner "file" {
    source      = "files/jenkins-casc.yaml"
    destination = "/var/lib/jenkins/casc_configuration/jenkins.yaml"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chown -R jenkins:jenkins /var/lib/jenkins && systemctl restart jenkins",
    ]
  }
}