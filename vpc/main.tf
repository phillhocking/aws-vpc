data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  aws_available_zones = data.aws_availability_zones.available.names[0]
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# Subnets 

resource "aws_subnet" "dev" {
  # This line is necessary to ensure that we pick availabiltiy zones that can launch any size ec2 instance
  availability_zone = local.aws_available_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 6, 2)

  tags = {
    Name = "dev-subnet"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_subnet" "staging" {
  # This line is necessary to ensure that we pick availabiltiy zones that can launch any size ec2 instance
  availability_zone = local.aws_available_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 6, 1)


  tags = {
    Name = "staging-subnet"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_subnet" "prod" {
  # This line is necessary to ensure that we pick availabiltiy zones that can launch any size ec2 instance
  availability_zone = local.aws_available_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 6, 0)

  tags = {
    Name = "prod-subnet"
  }

  depends_on = [
    aws_vpc.main,
  ]
}


resource "aws_subnet" "public" {
  # This line is necessary to ensure that we pick availabiltiy zones that can launch any size ec2 instance
  availability_zone = local.aws_available_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 254)

  tags = {
    Name = "public-subnet"
  }

  depends_on = [
    aws_vpc.main,
  ]
}


# NACL
resource "aws_network_acl" "vpc" {
  vpc_id = aws_vpc.main.id

  subnet_ids = concat(
    [aws_subnet.prod.id],
    [aws_subnet.staging.id],
    [aws_subnet.dev.id],
    [aws_subnet.public.id]
  )

  ingress {
    protocol   = -1
    rule_no    = 1000
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.vpc_name}-nacl"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

# Gateways
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-internet-gateway"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

# VPC Route Table
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.main_route_table_id

  tags = {
    Name = "${var.vpc_name}-public"
  }

  depends_on = [
    aws_internet_gateway.gw,
    aws_vpc.main,
  ]
}

# prod Subnet Route Table
resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prod-route-table"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_route_table_association" "prod_routes" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.prod.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_subnet.prod,
  ]
}

resource "aws_route" "prod_gw" {
  route_table_id         = aws_route_table.prod.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [
    aws_route_table.prod,
    aws_internet_gateway.gw,
  ]
}

# Staging Subnet Route Table
resource "aws_route_table" "staging" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "staging-route-table"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_route_table_association" "staging_routes" {
  subnet_id      = aws_subnet.staging.id
  route_table_id = aws_route_table.staging.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_subnet.staging,
    aws_route_table.staging,
  ]
}

resource "aws_route" "staging_igw" {
  route_table_id         = aws_route_table.staging.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.staging,
  ]
}

# Dev Subnet Route Table
resource "aws_route_table" "dev" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-route-table"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_route_table_association" "dev_routes" {
  subnet_id      = aws_subnet.dev.id
  route_table_id = aws_route_table.dev.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.dev,
  ]
}

resource "aws_route" "dev_igw" {
  route_table_id         = aws_route_table.dev.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.dev,
  ]
}

# Public Subnet Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }

  depends_on = [
    aws_vpc.main,
  ]
}

resource "aws_route_table_association" "public_routes" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.public,
  ]
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table.public,
  ]
}
