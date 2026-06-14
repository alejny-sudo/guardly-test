resource "aws_s3_bucket" "test_bucket" {
  bucket = "my-guardly-test-bucket"
  acl = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

