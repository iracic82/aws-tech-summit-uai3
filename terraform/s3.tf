# --- S3 Bucket (conditional) ---

resource "aws_s3_bucket" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = var.s3_bucket_name

  tags = { Name = var.s3_bucket_name }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.this[0].arn}/uploads/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# --- S3 CNAME in Route53 (conditional) ---

resource "aws_route53_record" "s3_cname" {
  count   = var.enable_s3_bucket ? 1 : 0
  zone_id = aws_route53_zone.private.zone_id
  name    = "s3.${var.route53_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_s3_bucket.this[0].bucket}.s3.${var.aws_region}.amazonaws.com"]
}
