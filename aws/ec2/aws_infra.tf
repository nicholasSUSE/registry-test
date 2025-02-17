resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix}-vpc"
    Creator = var.user
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-gateway"
    Creator = var.user
  }
}

# Create a subnet within the VPC using a CIDR block
resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id

  cidr_block        = "10.0.0.0/24"
  availability_zone = var.aws_zone

  tags = {
    Name = "${var.prefix}-subnet"
    Creator = var.user
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.prefix}-route-table"
    Creator = var.user
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg_allowall" {
  name        = "${var.prefix}-sg-allowall"
  description = "Rancher quickstart - allow all traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sec-group"
    Creator = var.user
  }
}

#---------------------------------------------------------------------------------------------------------
# SSH key management
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${path.root}/certs/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.root}/certs/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

resource "aws_key_pair" "key_pair" {
  key_name_prefix = "${var.prefix}-key-pair"
  public_key      = tls_private_key.global_key.public_key_openssh
}
