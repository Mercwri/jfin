data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "media-read-backup-write" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.media.arn,
      "${aws_s3_bucket.media.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "allow_ssm_session_manager" {
  statement {
    actions = [
      "ssm:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "media_backup_role" {
  name               = "media_backup_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "s3" {
  role   = aws_iam_role.media_backup_role.name
  policy = data.aws_iam_policy_document.media-read-backup-write.json
}

resource "aws_iam_role_policy" "ssm" {
  role   = aws_iam_role.media_backup_role.name
  policy = data.aws_iam_policy_document.allow_ssm_session_manager.json
}

resource "aws_iam_instance_profile" "jellyfin" {
  role = aws_iam_role.media_backup_role.name
}

resource "aws_iam_role_policy_attachment" "manage_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.media_backup_role.name
}