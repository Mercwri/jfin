data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "jellfin-server-sg" {
  name   = "jellyfin-server-sg"
  vpc_id = aws_vpc.core.id
  ingress {
    description     = "FromALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description = "SSHFromHome"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["74.64.242.71/32"] # Replace with your home IP
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_key_pair" "pubkey" {
  key_name = "pubkey"
}

resource "aws_instance" "jellyfin" {
  key_name                    = data.aws_key_pair.pubkey.key_name
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.jellyfin.name
  associate_public_ip_address = true
  root_block_device {
    volume_size = 50
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 1000
    volume_type = "st1"
  }
  vpc_security_group_ids = [aws_security_group.jellfin-server-sg.id]
  subnet_id              = aws_subnet.core["10.0.1.0/24"].id
}

resource "aws_eip" "jfin" {
  instance = aws_instance.jellyfin.id
  domain   = "vpc"
}