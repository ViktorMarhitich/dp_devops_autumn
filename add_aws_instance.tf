provider "aws" {
    access_key = "AKIA4RONLHMGRYYKXDPE"
    secret_key = "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"
    region = "eu-central-1"
}

# Security Group
variable "ingressrules" {
  type    = list(number)
  default = [9000, 8080, 22]
}

resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "true"
  }
}


resource "aws_instance" "dev_server" {
    ami = "ami-05d34d340fb1d89e5"
    instance_type = "t2.medium"
    security_groups = [aws_security_group.web_traffic.name]
    key_name = "dev"

  provisioner "remote-exec"  {
    inline  = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install epel -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo yum install git -y",
      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash",
      ". ~/.nvm/nvm.sh",
      "nvm install node",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade -y",
      "sudo yum install jenkins -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl start jenkins",
      ]
   }
 connection {
    type         = "ssh"
    host         = self.public_ip
    user         = "ec2-user"
    private_key  = file("./dev.pem" )
   }
  tags  = {
    "Name"      = "Dev"
      }
}

