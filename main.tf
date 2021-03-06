#1  Create VPC
resource "aws_vpc" "prod" {
  cidr_block = var.vpc_cidr
    tags = {
    Site = "web"
    Name = "prod-vpc"
  }
}

#2  Create subnets, internet gateways, associations
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnet1_cidr
  availability_zone = var.subnet1_az
  tags = {
    Name = "subnet1.private"
    Tier = "private"
    AZ = var.subnet1_az
    }
}
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnet2_cidr
  availability_zone = var.subnet2_az
  tags = {
    Name = "subnet2.private"
    AZ = var.subnet2_az
    Tier = "private"
  }
}
resource "aws_subnet" "private3" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnet3_cidr
  availability_zone = var.subnet3_az
  tags = {
    Name = "subnet3.private"
    AZ = var.subnet3_az
    Tier = "private"
  }
}
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnetp1_cidr
  availability_zone = var.subnet1_az
  tags = {
    Name = "subnet1.public"
    AZ = var.subnet1_az
    Tier = "public"
  }
}
resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnetp2_cidr
  availability_zone = var.subnet2_az
  tags = {
    Name = "subnet2.public"
    AZ = var.subnet2_az
    Tier = "public"
  }
}
resource "aws_subnet" "public3" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnetp3_cidr
  availability_zone = var.subnet3_az
  tags = {
    Name = "subnet3.public"
    AZ = var.subnet3_az
    Tier = "public"
  }
}
# Create Internet gateway, NAT gw + EIP, route tables and all associations
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "public"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}
resource "aws_nat_gateway" "public1" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "NAT gateway"
  }

  depends_on = [aws_internet_gateway.gw]

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  # route {
  #   ipv6_cidr_block        = "::/0"
  #   gateway_id = aws_internet_gateway.gw.id
  # }
  tags = {
    Name = "public-rtable"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public1.id
  }
    tags = {
    Name = "private-rtable"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private.id
}

#3  Create security groups to allow web traffic to servers, port 80 for ALB
resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "TLS from internet"
    from_port   = var.web_server_ssl_port
    to_port     = var.web_server_ssl_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "web from internet"
    from_port   = var.web_server_port
    to_port     = var.web_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   description = "ssh from bastion"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["108.29.90.182/32"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_ssh_remote"
  }
}
resource "aws_security_group" "alb" {

  name = var.alb_security_group_name
  vpc_id      = aws_vpc.prod.id
   
  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#4  Create launch configuration
resource "aws_launch_configuration" "as_web" {
  image_id      = var.amis[var.region]
  instance_type = "t2.micro"
  # subnet_id = aws_subnet.public1.id
  key_name="tf-lab"
  #network_interface {
  #   device_index         = 0
  #   network_interface_id = aws_network_interface.eni0.id
  #}
  
  security_groups = [aws_security_group.web.id]

  user_data = <<-EOF
		#!/bin/bash
    sudo apt update
    sudo apt install -y nginx
    sudo ufw allow 'Nginx HTTP'
    sudo systemctl enable nginx
    sudo systemctl start nginx 

    #echo "<h1>Deployed via Terraform OK</h1>" | sudo tee /var/www/html/index.html
	EOF
  
  # Required when using a launch configuration with an auto scaling group. 
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html 
  lifecycle {
    create_before_destroy = true
  }
}

#5  Create Autoscaling group
resource "aws_autoscaling_group" "as_web" {
  launch_configuration = aws_launch_configuration.as_web.name
  vpc_zone_identifier  = data.aws_subnet_ids.private.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 4

  tag {
    key                 = "Name"
    value               = "terraform-asg-web"
    propagate_at_launch = true
  }
}

#--------------------------------------------------------------
# Introspection: retrieve public and private subnet id's
# >>> depends_on is NECESSARY to ensure subnets are present
#
data "aws_vpc" "prod" {
   default = false
   id = aws_vpc.prod.id
}
data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.prod.id
  filter {
    name   = "tag:Tier"
    values = ["public"] # insert values here
  } 
  #tags = {
  #  Tier = "public"
  #}
  depends_on = [
    aws_subnet.public1
  ]
}
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.prod.id
  tags = {
    Tier = "private"
  }
  depends_on = [
    aws_subnet.private1
  ]
}
#-------------------------------------------------------------------

#6  Create ALB
resource "aws_lb" "public_web" {

  name               = var.alb_name

  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public.ids
  security_groups    = [aws_security_group.alb.id]
}

#6.1 Create Listener - add Listener rule(s)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public_web.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

#7  Create Target Group
resource "aws_lb_target_group" "asg" {

  name = var.alb_name

  port     = var.web_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.prod.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


#8 Outputs

# output "server_public_ip" {
#    value = aws_eip.public1_web1.public_ip
# }

