variable "region" {
  default = "us-west-2"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}


variable "subnet1_cidr" {
  type = string
  default = "10.0.1.0/24"
}
variable "subnet1_az" {
  type = string
  default = "us-west-2a"
}

variable "subnet2_cidr" {
  type = string
  default = "10.0.2.0/24"
}
variable "subnet2_az" {
  type = string
  default = "us-west-2b"
}

variable "subnet3_cidr" {
  type = string
  default = "10.0.3.0/24"
}
variable "subnet3_az" {
  type = string
  default = "us-west-2c"
}


variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-0885b1f6bd170450c"
    "us-west-2" = "ami-07dd19a7900a1f049"
  }
}

variable "web_server_port" {
  type = number
  default = 80
}

variable "web_server_ssl_port" {
  type = number
  default = 443
}
