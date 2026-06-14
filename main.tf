resource "aws_s3_bucket" "test_bucket" {
  bucket = "my-guardly-test-bucket"
  acl    = "public-read"
}

