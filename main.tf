provider "aws" {
    region = "us-east-1"
    profile = "personal"
}

resource "aws_instance" "tf-instance" {
    instance_type = "t2.micro"
    ami = "ami-02ccb28830b645a41"
}

