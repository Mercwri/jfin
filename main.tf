data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "media" {
  bucket = "media-jf-mikeell"
}

resource "aws_s3_bucket" "backup" {
  bucket = "backup-jf-mikeell"
}

resource "aws_s3_bucket_acl" "acl" {
  for_each = toset([
    aws_s3_bucket.media.id,
    aws_s3_bucket.backup.id,
  ])
  bucket     = each.value
  acl        = "private"
  depends_on = [aws_s3_bucket.backup, aws_s3_bucket.media]
}

resource "aws_s3_bucket_lifecycle_configuration" "itc" {
  bucket = aws_s3_bucket.media.id
  rule {
    status = "Enabled"
    id     = "itc"
    expiration {
      days = 365
    }
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    status = "Enabled"
    id     = "backup"
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}