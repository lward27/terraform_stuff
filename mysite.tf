# install providers
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

# environment variables
variable "AWS_ACCESS_KEY_ID" {
    type = string
}
variable "AWS_SECRET_ACCESS_KEY" {
    type = string
}
variable "AWS_REGION" {
    type = string
}

# configure the AWS provider
provider "aws" {
    region = var.AWS_REGION
    access_key = var.AWS_ACCESS_KEY_ID
    secret_key = var.AWS_SECRET_ACCESS_KEY
}

variable "SUBNET_PREFIX" {
    description = "cidr block for the subnet"
    default = "10.0.66.0/24"
    #type = string
}

resource "aws_vpc" "prod_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

resource "aws_subnet" "prod_subnet_1" {
    vpc_id = aws_vpc.prod_vpc.id
    cidr_block = var.SUBNET_PREFIX[0].cidr_block
    #10.0.1.0/24
    availability_zone = "us-east-1a"

    tags = {
        Name = var.SUBNET_PREFIX[0].name
    }
}

resource "aws_subnet" "dev_subnet_1" {
    vpc_id = aws_vpc.prod_vpc.id
    cidr_block = var.SUBNET_PREFIX[1].cidr_block
    #10.0.1.0/24
    availability_zone = "us-east-1a"

    tags = {
        Name = var.SUBNET_PREFIX[1].name
    }
}

# Get traffic out to the actual internet
resource "aws_internet_gateway" "prod_gw" {
    vpc_id = aws_vpc.prod_vpc.id
    tags = {
        Name = "production"
    }
}

# Direct traffic
resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod_gw.id
  }

  tags = {
        Name = "production"
  }
}

# Need to associate our subnet with our route table
resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.prod_subnet_1.id
    route_table_id = aws_route_table.prod_route_table.id
}

# create security group and allow ports 22, 80, 44
resource "aws_security_group" "allow_web" {
    name        = "allow_web_traffic"
    description = "Allow web traffic"
    vpc_id      = aws_vpc.prod_vpc.id

    ingress {
        description      = "HTTPS traffic from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"] # you can even specify your compputers IP to allow only you to connect
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "HTTP traffic from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"] # you can even specify your compputers IP to allow only you to connect
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "SSH traffic from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"] # you can even specify your compputers IP to allow only you to connect
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow_web"
    }
}

# Network Interface - create private IP for host
resource "aws_network_interface" "web_server_nic" {
    subnet_id       = aws_subnet.prod_subnet_1.id
    private_ips     = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]

#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 1
#   }
}

# Create pubic IP (static)
resource "aws_eip" "one" {
    vpc                       = true
    network_interface         = aws_network_interface.web_server_nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [
        aws_internet_gateway.prod_gw # reference whole object, not just ID.
    ]
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

output "server_public_ip" {
    value = aws_eip.one.public_ip
}

# Create ubuntu server
resource "aws_instance" "web_server_instance" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "terraform-test-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web_server_nic.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF

    tags = {
        Name = "production"
    }
}

output "server_private_ip" {
    value = aws_instance.web_server_instance.private_ip
}
output "server_id" {
    value = aws_instance.web_server_instance.id
}









# resource "aws_vpc" "first-vpc" {
#     cidr_block = "10.0.0.0/16"
#     tags = {
#         Name = "production"
#     }
# }

# resource "aws_vpc" "second-vpc" {
#     cidr_block = "10.1.0.0/16"
#     tags = {
#         Name = "dev"
#     }
# }

# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# resource "aws_subnet" "subnet-2" {
#   vpc_id     = aws_vpc.second-vpc.id
#   cidr_block = "10.1.1.0/24"

#   tags = {
#     Name = "dev-subnet"
#   }
# }
# data "aws_ami" "ubuntu" {
#     most_recent = true

#     filter {
#         name = "name"
#         values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#     }

#     filter {
#         name = "virtualization-type"
#         values = ["hvm"]
#     }

#     owners = ["099720109477"]
# }

# # create a resource
# resource "aws_instance" "web" {
#     ami = data.aws_ami.ubuntu.id
#     instance_type = "t2.micro"

#     tags = {
#         Name = "UbuntuServer"
#     }
# }