variable "default_agent_vpc_id" {
  type    = string
  default = "vpc-f670c791"
}

variable "default_agent_ami" {
  type = string
}

##### JENKINS AGENTS SECURITY GROUP

resource "aws_security_group" "default_agent_sg" {
  name        = "jenkins_agent_sg"
  description = "Allow HTTP/HTTPS/SSH to 0.0.0.0 and all egress connections"
  vpc_id      = var.default_agent_vpc_id

  tags = {
    Name = "jenkins_agent_sg"
  }
}

resource "aws_security_group_rule" "default_agent_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_agent_sg.id
}

resource "aws_security_group_rule" "default_agent_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_agent_sg.id
}

resource "aws_security_group_rule" "default_agent_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_agent_sg.id
}

resource "aws_security_group_rule" "default_agent_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_agent_sg.id
}
