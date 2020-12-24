locals {
  agents = <<EOT
  - amazonEC2:
      cloudName: default-agent
      useInstanceProfileForCredentials: true
      sshKeysCredentialsId: jenkins-agent-key-pair
      region: "eu-west-1"
      templates:
      - type: "T2Medium"
        ami: "${var.default_agent_ami}"
        description: "AWS default agent"
        #"sub1 sub2 sub3" 
        subnetId: "subnet-6c9a2b25"
        remoteAdmin: ec2-user
        securityGroups: "${aws_security_group.default_agent_sg.id}"
        monitoring: false
        minimumNumberOfSpareInstances: 0
        connectionStrategy: PRIVATE_IP
        associatePublicIp: false
  EOT
}