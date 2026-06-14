# TerraWatch Test File — Multiple Intentional Vulnerabilities

# ─── S3 BUCKETS ───────────────────────────────────────────
resource "aws_s3_bucket" "public_data" {
  bucket = "acme-public-data"
  acl    = "public-read"
}

resource "aws_s3_bucket" "backups" {
  bucket = "acme-backups-prod"
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad" {
  bucket = aws_s3_bucket.backups.id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "none"
      }
    }
  }
}

# ─── IAM ──────────────────────────────────────────────────
resource "aws_iam_policy" "admin_policy" {
  name = "admin-policy"
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["*"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = "deploy-role"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "root_user" {
  name = "root"
  tags = {
    principal = "arn:aws:iam::123456789012:root\""
  }
}

# ─── SECURITY GROUPS ──────────────────────────────────────
resource "aws_security_group" "wide_open" {
  name = "wide-open-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── DATABASE ─────────────────────────────────────────────
resource "aws_db_instance" "production" {
  identifier        = "prod-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  username          = "admin"
  password          = "supersecret123"
  publicly_accessible = true
  storage_encrypted = false
}

# ─── EBS VOLUMES ──────────────────────────────────────────
resource "aws_ebs_volume" "data" {
  availability_zone = "eu-west-1a"
  size              = 100
  encrypted         = false
}

# ─── EKS ──────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name = "prod-cluster"

  kubernetes_network_config {}

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = false
  }
}

# ─── CLOUDTRAIL ───────────────────────────────────────────
resource "aws_cloudtrail" "main" {
  name                = "prod-trail"
  s3_bucket_name      = "audit-logs"
  enable_logging      = false
}

# ─── LOAD BALANCER ────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "prod-lb"
  internal           = false
  load_balancer_type = "application"
  scheme             = "internet-facing"
}

# ─── SECRETS HARDCODED ────────────────────────────────────
resource "aws_ssm_parameter" "api_key" {
  name  = "/prod/api_secret"
  type  = "String"
  value = "hardcoded-api-secret = \"abc123xyz\""
}

resource "aws_elasticache_cluster" "main" {
  cluster_id        = "prod-cache"
  engine            = "redis"
  enforce_https     = false
}

# ─── IMDSv1 VULNERABLE ────────────────────────────────────
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  metadata_options {
    http_tokens = "optional"
  }
}

# ─── ALL PORTS OPEN ───────────────────────────────────────
resource "aws_security_group" "all_open" {
  name = "all-open"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── ALL TRAFFIC ──────────────────────────────────────────
resource "aws_security_group_rule" "all_traffic" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.all_open.id
}

# ─── RDS NO BACKUP + NO DELETION PROTECTION ───────────────
resource "aws_db_instance" "no_backup" {
  identifier             = "no-backup-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "badpassword"
  backup_retention_period = 0
  deletion_protection    = false
}

# ─── LAMBDA PUBLIC ────────────────────────────────────────
resource "aws_lambda_permission" "public" {
  action        = "lambda:InvokeFunction"
  function_name = "my-function"
  principal     = "*"
}

# ─── SNS UNENCRYPTED ──────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "prod-alerts"
}

# ─── SQS UNENCRYPTED ──────────────────────────────────────
resource "aws_sqs_queue" "jobs" {
  name = "prod-jobs"
}

# ─── MFA DELETE DISABLED ──────────────────────────────────
resource "aws_s3_bucket_versioning" "main" {
  bucket = "prod-bucket"
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}
