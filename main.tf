# Get VPC ID from subnet
data "aws_subnet" "selected" {
  id = "subnet-0f2fcc8d17f8f9a71"
}

# Random suffix for unique naming
resource "random_pet" "suffix" {
  length = 2
}

# Security Groups
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg-${random_pet.suffix.id}"
  vpc_id = data.aws_subnet.selected.vpc_id  # Use the same VPC as subnet
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Simplified - agent will connect
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_agent_sg" {
  name   = "jenkins-agent-sg-${random_pet.suffix.id}"
  vpc_id = data.aws_subnet.selected.vpc_id  # Use the same VPC as subnet
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins Master
module "jenkins" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "jenkins"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = "subnet-0f2fcc8d17f8f9a71"
  ami                         = data.aws_ami.ami_info.id
  key_name                    = "devops"
  user_data                   = file("jenkins.sh")
  associate_public_ip_address = false
  
  root_block_device = {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
}

resource "aws_eip" "jenkins_eip" {
  instance = module.jenkins.id
  domain   = "vpc"
}

# Jenkins Agent
module "jenkins_agent" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = "jenkins-agent"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.jenkins_agent_sg.id]
  subnet_id                   = "subnet-0f2fcc8d17f8f9a71"
  ami                         = data.aws_ami.ami_info.id
  key_name                    = "devops"
  user_data                   = file("jenkins-agent.sh")
  associate_public_ip_address = false
  
  root_block_device = {
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
}

resource "aws_eip" "jenkins_agent_eip" {
  instance = module.jenkins_agent.id
  domain   = "vpc"
}

# Route53 DNS
module "records" {
  source    = "terraform-aws-modules/route53/aws//modules/records"
  version   = "~> 2.0"
  zone_name = var.zone_name
  
  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 60
      records = [aws_eip.jenkins_eip.public_ip]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 60
      records = [aws_eip.jenkins_agent_eip.public_ip]
      allow_overwrite = true
    }
  ]
}

# Outputs
output "jenkins_url" {
  value = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "jenkins_dns_url" {
  value = "http://jenkins.${var.zone_name}:8080"
}