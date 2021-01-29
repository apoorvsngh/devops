provider "aws" {
    region = "us-east-2"
    profile = "personal"
#    shared_credentials_file = "/Users/apoorvsingh/Impo/credentials.csv"
}

resource "aws_instance" "tf-instance" {
    instance_type = "t2.micro"
    ami = "ami-02ccb28830b645a41"
}

