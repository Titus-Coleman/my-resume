provider "aws" {
  region  = var.aws_region
  profile = "default"
}


resource "aws_s3_bucket" "resume" {
  bucket = "resume.tituscoleman.dev"
  #   force_destroy = true

  tags = {
    Name = "Resume Page"
  }
}
resource "aws_s3_bucket_policy" "allow_get_access" {
  bucket = aws_s3_bucket.resume.id
  policy = data.aws_iam_policy_document.public_get.json
}

data "aws_iam_policy_document" "public_get" {
  statement {
    sid = "AllowCFServicePrincipal"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.resume.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${var.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "resume_site" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "TitusColemanResume.html"
  }

  error_document {
    key = "TitusColemanResume.html"
  }
}


locals {
  s3_origin_id = "resume-s3-origin"
}

resource "aws_cloudfront_origin_access_control" "s3_resume" {
  name                              = "${aws_s3_bucket.resume.id}.s3.${var.aws_region}.amazonaws.com"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  aliases = [
    "resume.tituscoleman.dev",
  ]
  default_root_object = "TitusColemanResume.html"
  price_class         = "PriceClass_100"
  enabled             = true

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = "resume.tituscoleman.dev.s3-website-${var.aws_region}.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
  }
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "${aws_s3_bucket.resume.id}.s3.${var.aws_region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_resume.id
    origin_id                = "${aws_s3_bucket.resume.id}.s3-website-${var.aws_region}.amazonaws.com"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }

  }
  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:${var.aws_region}:${var.account_id}:certificate/${var.cert_id}"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}
