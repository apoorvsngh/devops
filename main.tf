provider "aws" {
    region = "us-east-2"
    profile = "personal"
#    shared_credentials_file = "/Users/apoorvsingh/Impo/credentials.csv"
}

variable "server_port" { }

data "aws_vpc" "default-vpc" {
    default = true
}

data "aws_subnet_ids" "default-subnet" {
    vpc_id = data.aws_vpc.default-vpc.id
    tags = {
        Name = "default*"
    }
}

/*
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

output "private-ip" { value = aws_instance.tf-instance.private_ip }
*/

resource "aws_security_group" "tf-instance-sg" {
    name              = "terraform-instance-sg"
    ingress {
        from_port     = var.server_port
        to_port       = var.server_port
        protocol      = "tcp"
        cidr_blocks   = ["0.0.0.0/0"]
    }
}

resource "aws_launch_configuration" "tf-lc" {
    image_id = "ami-02ccb28830b645a41"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.tf-instance-sg.id]
    key_name = "test-asg"
    lifecycle {
        create_before_destroy = true
    }
    user_data       = <<-EOF
                      #!/bin/bash
                      sudo yum install httpd -y
                      sudo systemctl start httpd.service
                      sudo systemctl start sshd.service
                      EOF
}

resource "aws_autoscaling_group" "tf-asg" {
    launch_configuration = aws_launch_configuration.tf-lc.name
    min_size = 1
    max_size = 10
    vpc_zone_identifier = data.aws_subnet_ids.default-subnet.ids
    target_group_arns = [aws_lb_target_group.tf-tg.arn]
    health_check_type = "ELB"
    tag { 
        key = "Name"
        value = "terraform-instance-asg"
        propagate_at_launch = true
    }
}


resource "aws_security_group" "tf-alb-sg" {
    name = "terraform-alb-sg"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "tf-alb" {
    name = "terraform-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default-subnet.ids
    security_groups = [aws_security_group.tf-alb-sg.id]
}

resource "aws_lb_listener" "tf-http-listener" {
    load_balancer_arn = aws_lb.tf-alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: Page not found"
            status_code = 404
        }
    }
}

resource "aws_lb_target_group" "tf-tg" {
    name = "terraform-target-group"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default-vpc.id
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "tf-alb-listener-rule" {
    priority = 100
    listener_arn = aws_lb_listener.tf-http-listener.arn
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tf-tg.arn
    }
}





output "alb_dns_name" {
    value = aws_lb.tf-alb.dns_name
    description = "Domain of ALB"
}