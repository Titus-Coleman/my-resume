provider "aws" {
  region  = "us-east-1"
  profile = "default"
}


resource "aws_s3_bucket" "resume" {
  bucket = "resume.tituscoleman.dev"

  tags = {
    Name = "Resume Page"
  }
}
# resource "aws_s3_bucket_acl" "resume_acl" {
#   bucket = aws_s3_bucket.resume.id
#   acl    = "private"
# }


# Upload an object
resource "aws_s3_object" "resume_upload" {
  key                    = "TitusColemanResume.html"
  bucket                 = aws_s3_bucket.resume.id
  source                 = "../TitusColemanResume.html"
  server_side_encryption = "aws:kms"
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
  name                              = "Resume_on_S3"
  description                       = "s3 resume Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_resume.id
    origin_id                = local.s3_origin_id

  }
  aliases             = ["resume.tituscoleman.dev"]
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Resume Source Bucket"
  default_root_object = "TitusColemanResume.html"

  #   logging_config {
  #     include_cookies = false
  #     bucket          = "mylogs.s3.amazonaws.com"
  #     prefix          = "resume_bucket"
  #   }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
