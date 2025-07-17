locals {
  region = "us-east-1"
  subnet_az_mapping = tomap({
    "10.0.1.0/24" = "us-east-1a"
  "10.0.2.0/24" = "us-east-1b" })
}