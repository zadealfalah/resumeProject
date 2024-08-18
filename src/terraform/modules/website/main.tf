# Bucket Resources
resource "aws_s3_bucket" "resume_bucket" {
    bucket = "${var.bucket_name}"
}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.resume_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.bucket_access_block]
  bucket     = aws_s3_bucket.resume_bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.resume_bucket.id}/*"
        }
      ]
    }
  )
}

resource "aws_s3_object" "file" {
  for_each     = fileset("${path.module}/../../../content", "**/*.{html,css,js}")
  bucket       = aws_s3_bucket.resume_bucket.id
  key          = replace(each.value, "^../../../content/", "")
  source       = "${path.module}/../../../content/${each.value}"
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  source_hash  = filemd5("${path.module}/../../../content/${each.value}")
}


# Website resources

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.resume_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Enable and redirect to HTTPS
resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.hosting.website_endpoint
    # origin_id   = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    # domain_name = "${var.www_domain_name}"
    origin_id   = "${var.root_domain_name}"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only" 
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.root_domain_name}"
  }

  aliases = ["${var.www_domain_name}", "${var.root_domain_name}"]

}

# DNS certification
resource "aws_acm_certificate" "certificate" {
    domain_name               = "${var.root_domain_name}"
    validation_method         = "DNS"
    subject_alternative_names = ["*.${var.root_domain_name}"]

    lifecycle {
      create_before_destroy = true
    }
}

data "aws_route53_zone" "zone" {
  name         = "${var.root_domain_name}"
  private_zone = false
}

# resource "aws_route53_record" "www" {
#   zone_id = "${data.aws_route53_zone.zone.zone_id}"
#   name    = "${var.root_domain_name}"
#   type    = "A"

#   alias {
#     name                   = "${aws_cloudfront_distribution.distribution.domain_name}"
#     zone_id                = "${aws_cloudfront_distribution.distribution.hosted_zone_id}"
#     evaluate_target_health = false
#   }
# }



resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_route53_record" "root_domain_redirect" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.root_domain_name}"
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.hosting.website_endpoint
    zone_id                = aws_s3_bucket.resume_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate_validation" "validate" {
  certificate_arn = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
  timeouts {
    create = "5m"
  }
}

