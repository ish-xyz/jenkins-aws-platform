###### VARIABLES

variable "jenkins_master_ami" {
  type    = string
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

###### RANDOM ID

resource "random_id" "id" {
  byte_length = 8
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
  name        = "jenkins-slave-key-${random_id.id.hex}"
  description = "Jenkins Slave RSA PEM PRIVATE KEY"
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
  name        = "jenkins-master-key-${random_id.id.hex}"
  description = "Jenkins Master RSA PEM PRIVATE KEY"
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
  key_name                    = aws_key_pair.jenkins_master.key_name
  monitoring                  = true
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_master_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.jenkins_master_sg.id]
  subnet_id                   = var.jenkins_master_subnet_id

  tags = {
    Name       = "jenkins_master"
    created_by = "terraform"
  }
}
##### CREATE JENKINS.YAML CASC

resource "local_file" "foo" {
  content  = templatefile("templates/jenkins-casc.yaml.tpl", {jenkins-slave-key = aws_secretsmanager_secret.jenkins_slave_key.name})
  filename = "jenkins.yaml"
}

##### IMPORT CASC CONFIGURATION AND RESTART JENKINS

resource "null_resource" "jenkins_master_configuration" {
  # Bootstrap Jenkins

  triggers = {
    id = uuid()
  }


  connection {
    type        = "ssh"
    host        = flatten(module.jenkins_master_ec2.public_ip)[0]
    user        = var.jenkins_master_ssh_user
    private_key = tls_private_key.jenkins_master.private_key_pem
  }

  provisioner "file" {
    source      = "jenkins.yaml"
    destination = "/tmp/jenkins.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/jenkins.yaml /var/lib/jenkins/casc_configs/jenkins.yaml",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins",
      "sudo systemctl restart jenkins",
    ]
  }
}

##### DEBUG
resource "local_file" "jenkins_master_keyfile" {
  content  = tls_private_key.jenkins_master.private_key_pem
  filename = "${path.module}/jenkins-master.pem"
}

output "instance_ip_addr" {
  value = element(module.jenkins_master_ec2[*].public_ip, 0)
}

output "ssh_user" {
  value = var.jenkins_master_ssh_user
}

output "ssh_keyfile" {
  value = "${path.module}/jenkins-master.pem"
}