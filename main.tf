resource "aws_s3_bucket" "test_bucket" {
  bucket = "my-guardly-production-test"
  acl    = "public-read"
}

