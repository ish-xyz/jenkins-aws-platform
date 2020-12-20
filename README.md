# Work in progress - expect incorrect docs and flaky workflows :D 
----

# BRIEF DESCRIPTION

This repository contains the infrastructure as code needed to automate the setup of Jenkins and its jobs, secrets, and needed AWS infrastructure.

The platform takes advantage of 4 main tools/systems:

Terraform
Packer + Ansible
Jenkins CASC 
Jenkins DSL 

The infrastructure layer chosen here is AWS but the architecture could potentially work in every cloud provider.<br><br><br>


# CONCEPTS

The design I have decided to go for this platform is "Immutable infrastructure". 
For this particular reason I have used Packer to build the images (Jenkins master and agent AMIs) and Terraform to deploy the infrastructure.
<br><br>

### Jenkins Master: AMI creation with Packer + Ansible

With the code defined in `/images/master` packer will create a new AMI with our Jenkins Master pre-configured in it.

When you execute Packer (see section: Tutorial) it will:

1. Create a temporary instance
2. Connect to the instance and execute the ansible playbook defined here -> `/images/master/ansible/playbook`
3. Save a new AMI from the early configured EC2 Instance and destroy it.
4. It will output some metadata to a file called `/images/master/manifest.json`
<br><br><br>



### Jenkins Master: Infrastructure provisioning with Terraform

If you know Terraform already, I have done nothing out of the ordinary here.

Terraform will create the following resources:

- IAM Role + IAM Policy (Necessary for the Jenkins to connect to the AWS Services) <br>

- PEM Keys (With RSA Algorithm) <- This are the keys used for the master & agent SSH connections. <br>

- Save the early created keys to AWS Secret Manager <br>
  (**NOTE: Using the Jenkins AWS Credential plugin the agent' SSH key will be automatically be created as credentials within Jenkins**) <br>

- Render the CASC file (`/terraform/templates/jenkins.yaml.tpl`). <br>
  **NOTE:** <br>
  The config is a template because Terraform needs to update the value of ${jenkins-slave-ssh-keypair}. <br>
  Jenkins using CASC will create a credential called "Jenkins Agent SSH Key" which is needed by Jenkins JClouds to provision Agents automatically. <br>
  The content of the actual key is stored in AWS Secret Manager by Terraform itself and is accesible by Jenkins using the configured IAM role. <br>
  However since the name of the secret, in AWS Secret Manager, changes at every Terraform run, I needed to template the CASC configuration, making the value dynamic. <br>

- Provision the required Security Groups.

- Create the EC2 Instance to host the Jenkins Master and deploy the rendered jenkins.yaml (CASC file) inside it.
<br><br><br>


### JClouds (not implemented in CASC yet)

Using Jenkins functionality clouds Jenkins will be able to deploy agents on-demand and destroy them when they're not needed anymore AUTOMATICALLY.

You'll also be able to tell Jenkins (from the CASC configuration) which AMI use to spawn user, hence you'll be able to use MACOS, WINDOWS or LINUX instances as Jenkins agents.
<br><br><br>


### Seed JOB + DSL JOBS (not implemented in the code yet)
<br><br><br>


# Tutorial (not finished yet)

### Requirements:

* docker >= 20.10.0


### Steps

0. Create AWS keys with admin access.

1. Create a file called ./.credz as follow:

```
export AWS_SECRET_ACCESS_KEY=<aws-credential>
export AWS_ACCESS_KEY_ID=<aws-credential>
```

2. Create the Jenkins master image

```
bash run.sh create-image master
```

3. Deploy Jenkins
```
bash run.sh deploy
```
