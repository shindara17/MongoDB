provider "aws" {
  region  = "us-east-1"
  profile = "shindara"   # Replace with your AWS profile
}

resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "my-mongodb-backups"

  # Optional: Enable versioning to keep multiple versions of an object in one bucket
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.mongodb_backups.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.mongodb_backups.arn}/*"
      }
    ]
  })
}

output "s3_bucket_name" {
  value = aws_s3_bucket.mongodb_backups.bucket
}
