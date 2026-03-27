# No provider blocks inside a module.
# Providers are injected by the calling root configuration via the providers map.

# ── Primary bucket — uses aws.primary alias (us-east-1) ──────────────────────
resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = "${var.app_name}-primary-bucket"
  force_destroy = true

  tags = {
    Name        = "${var.app_name}-primary"
    Role        = "primary"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Replica bucket — uses aws.replica alias (us-west-2) ──────────────────────
resource "aws_s3_bucket" "replica" {
  provider      = aws.replica
  bucket        = "${var.app_name}-replica-bucket"
  force_destroy = true

  tags = {
    Name        = "${var.app_name}-replica"
    Role        = "replica"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
