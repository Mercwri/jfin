resource "aws_ecs_cluster" "jellyfin" {
  name = "jellyfin"
}

resource "aws_security_group" "jellyfin" {
  name        = "jellyfin-ecs-sg"
  description = "Security group for Jellyfin ECS service"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port = 8096
    to_port   = 8096
    protocol  = "tcp"
    cidr_blocks = [
      for s in aws_subnet.core : s.cidr_block
    ]
  }

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = [
      for s in aws_subnet.core : s.cidr_block
    ]
  }

  ingress {
    from_port = 2997
    to_port   = 2999
    protocol  = "tcp"
    cidr_blocks = [
    for s in aws_subnet.core : s.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "jellyfin" {
  creation_token   = "jellyfin-efs"
  performance_mode = "generalPurpose"
  encrypted        = true
  throughput_mode  = "elastic"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  lifecycle_policy {
    transition_to_archive = "AFTER_30_DAYS"
  }
  tags = {
    Name = "jellyfin-efs"
  }
}

resource "aws_efs_access_point" "jellyfin" {
  for_each       = toset(["config", "media", "cache"])
  file_system_id = aws_efs_file_system.jellyfin.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    path = "/${each.value}"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "775"
    }
  }

}

resource "aws_security_group_rule" "efs_allow" {
  security_group_id = aws_vpc.core.default_security_group_id
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [for s in aws_subnet.core : s.cidr_block]
}

resource "aws_security_group_rule" "efs_allow_2" {
  security_group_id = aws_vpc.core.default_security_group_id
  type              = "ingress"
  from_port         = 2997
  to_port           = 2999
  protocol          = "tcp"
  cidr_blocks       = [for s in aws_subnet.core : s.cidr_block]
}

resource "aws_efs_mount_target" "jellyfin" {
  for_each       = local.subnet_az_mapping
  file_system_id = aws_efs_file_system.jellyfin.id
  subnet_id      = aws_subnet.core[each.key].id
}

resource "aws_ecs_task_definition" "jellyfin" {
  family                   = "jellyfin"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  container_definitions = jsonencode([
    {
      name      = "jellyfin"
      image     = "jellyfin/jellyfin:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8096
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "efs-volume-config"
          containerPath = "/config"
        },
        {
          sourceVolume  = "efs-volume-media"
          containerPath = "/media"
        },
        {
          sourceVolume  = "efs-volume-cache"
          containerPath = "/cache"
        }
      ]
    }
  ])

  volume {
    name = "efs-volume-config"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.jellyfin.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.jellyfin["config"].id
      }
    }
  }
  volume {
    name = "efs-volume-media"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.jellyfin.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2998
      authorization_config {
        access_point_id = aws_efs_access_point.jellyfin["media"].id
      }
    }
  }
  volume {
    name = "efs-volume-cache"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.jellyfin.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2997
      authorization_config {
        access_point_id = aws_efs_access_point.jellyfin["cache"].id
      }
    }
  }
}

resource "aws_ecs_service" "jellyfin" {
  name            = "jellyfin"
  cluster         = aws_ecs_cluster.jellyfin.id
  task_definition = aws_ecs_task_definition.jellyfin.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [for s in aws_subnet.core : s.id]
    security_groups  = [aws_security_group.jellyfin.id]
    assign_public_ip = true
  }
}