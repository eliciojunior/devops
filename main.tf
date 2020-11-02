locals {
  ssh_user         = "ubuntu"
  key_name         = "my_key"
  private_key_path = "~/.ssh/id_rsa"
  public_key_path  = "~/.ssh/id_rsa.pub"
}

provider "aws" {
  region = "us-east-2"
  shared_credentials_file = "{credentials_file}"
  profile = "terraform_user"
}

resource "aws_key_pair" "my_key" {
  key_name = local.key_name
  public_key = file(local.public_key_path)
}

resource "aws_instance" "example" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = local.key_name
  associate_public_ip_address = true
    
  vpc_security_group_ids = [
   aws_security_group.example-sg.id
  ]
  
  #provisioner "remote-exec" {
  #  inline = ["echo 'Wait until SSH is ready'"]
  #  
  #  connection {
  #    type        = "ssh"
  #    user        = local.ssh_user
  #    private_key = file(local.private_key_path)
  #    host        = aws_instance.example.public_ip
  #  }
  #}
  #
  #provisioner "local-exec" {
  #  command = "ansible-playbook -i ${aws_instance.example.public_ip} --private-key ${local.private_key_path} playbook.yml" 
  #}
  
  tags = {
    name = "eliciojunior-vps"
    type = "master"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
	values = ["ubuntu/images/hvm-ssd/ubuntu-groovy-20.10-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
	values = ["hvm"]
  }
  
  owners = ["099720109477"] #Canonical
}

resource "aws_security_group" "example-sg" {
  description = "Allow ssh inbound traffic"
  
  ingress {
    description = "lo-inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "web"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "lo-outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "example_public_ip" {
  value = aws_instance.example.public_ip
}

output "example_public_dns" {
  value = aws_instance.example.public_dns
}
