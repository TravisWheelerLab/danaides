resource "aws_efs_file_system" "efs" {
  creation_token                  = "my-efs"
  performance_mode                = var.storage_performance_mode
  throughput_mode                 = var.storage_throughput_mode
  provisioned_throughput_in_mibps = var.storage_throughput_mode == "provisioned" ? var.storage_throughput_in_mibps : null
  encrypted                       = true
}

# TODO: Scrutinize the necessity/security of this rule
resource "aws_security_group" "efs_sg" {
  vpc_id      = var.vpc_id
  description = "Allow NFS traffic from the VPC"
  ingress {
    description = "Allow NFS traffic from the VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [for cidr_block in var.cidr_blocks : cidr_block]
  }
  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "alpha" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = element(var.subnet_ids, count.index)
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/export/lambda"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0777"
    }
  }
  posix_user {
    uid = 1000
    gid = 1000
  }
}

resource "aws_efs_file_system_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.efs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "efs-policy",
    Statement = [
      {
        Sid       = "efs-access",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ],
        Resource = aws_efs_file_system.efs.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}
