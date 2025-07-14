resource "aws_s3_bucket" "media" {
  bucket = "media-jf-mikeell"
}

resource "aws_s3_bucket" "backup" {
  bucket = "backup-jf-mikeell"
}

resource "aws_s3_bucket_acl" "acl" {
  for_each = toset([
    "media-jf-mikeell",
    "backup-jf-mikeell"
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
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
    filter {
      prefix = "/"
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
    filter {
      prefix = "/"
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
