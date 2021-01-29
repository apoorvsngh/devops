provider "aws" {
    region = "us-east-2"
    profile = "personal"
#    shared_credentials_file = "/Users/apoorvsingh/Impo/credentials.csv"
}

variable "server_port" { }

resource "aws_instance" "tf-instance" {
    instance_type   = "t2.micro"
    ami             = "ami-0eb9463ef8c71ad92"
    security_groups = [aws_security_group.tf-instance-sg.name]
    tags            = {
        Name        = "terraform-instance"
    }
    user_data       = <<-EOF
                      #!/bin/bash
                      echo "Hello World" > index.html
                      nohup busybox httpd -f -p 8080 &
                      EOF
}

resource "aws_security_group" "tf-instance-sg" {
    name              = "terraform-instance-sg"
    ingress {
        from_port     = var.server_port
        to_port       = var.server_port
        protocol      = "tcp"
        cidr_blocks   = ["0.0.0.0/0"]
    }
}

