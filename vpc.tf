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
  for_each = {
    "10.0.1.0/24" = "a",
    "10.0.2.0/24" = "b",
  }
  vpc_id            = aws_vpc.core.id
  cidr_block        = each.key
  availability_zone = "us-east-1${each.value}"
}