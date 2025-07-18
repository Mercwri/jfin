resource "aws_vpc" "core" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  cidr_block           = "10.0.0.0/16"
}

resource "aws_internet_gateway" "core" {
  vpc_id = aws_vpc.core.id
}

resource "aws_route_table" "core" {
  vpc_id = aws_vpc.core.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.core.id
  }
}

resource "aws_subnet" "core" {
  for_each          = local.subnet_az_mapping
  vpc_id            = aws_vpc.core.id
  cidr_block        = each.key
  availability_zone = each.value
}

resource "aws_route_table_association" "core" {
  for_each       = aws_subnet.core
  subnet_id      = each.value.id
  route_table_id = aws_route_table.core.id
}