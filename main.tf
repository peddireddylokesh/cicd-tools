# Jenkins EC2 Instance
module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                    = "jenkins"
  instance_type           = "t3.micro"
  vpc_security_group_ids  = ["sg-0df48a4504a56b775"] # replace with your SG
  subnet_id               = "subnet-0f2fcc8d17f8f9a71" # replace with your subnet
  ami                     = data.aws_ami.ami_info.id
  key_name                = "devops" # replace with your key pair
  user_data               = file("jenkins.sh")
  associate_public_ip_address = false # We will use EIP instead

  tags = {
    Name = "jenkins"
  }

  root_block_device = [
    {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
    }
  ]
}

# Elastic IP for Jenkins
resource "aws_eip" "jenkins_eip" {
  instance = module.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-eip"
  }
}

# Jenkins Agent EC2 Instance
module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                    = "jenkins-agent"
  instance_type           = "t3.micro"
  vpc_security_group_ids  = ["sg-0df48a4504a56b775"] # replace with your SG
  subnet_id               = "subnet-0f2fcc8d17f8f9a71" # replace with your subnet
  ami                     = data.aws_ami.ami_info.id
  user_data               = file("jenkins-agent.sh")
  associate_public_ip_address = false # We will use EIP instead

  tags = {
    Name = "jenkins-agent"
  }

  root_block_device = [
    {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
    }
  ]
}

# Elastic IP for Jenkins Agent
resource "aws_eip" "jenkins_agent_eip" {
  instance = module.jenkins_agent.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-agent-eip"
  }
}

# Route53 DNS Records
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 60
      records = [
        aws_eip.jenkins_eip.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 60
      records = [
        module.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    }
  ]
}
