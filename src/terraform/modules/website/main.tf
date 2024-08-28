data "aws_route53_zone" "zone" {
  name         = "${var.root_domain_name}"
  private_zone = false
}

data "aws_region" "current" {}

# Add pdf as an option once resume.pdf added to assets
resource "aws_s3_object" "file" {
  for_each     = fileset("${path.module}/../../../content", "**/*.{html,css,js,png,scss,jpg,svg,eot,ttf,woff,woff2,pdf}")
  bucket       = aws_s3_bucket.hosting.id
  key          = replace(each.value, "^../../../content/", "")
  source       = "${path.module}/../../../content/${each.value}"
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  source_hash  = filemd5("${path.module}/../../../content/${each.value}")
}

resource "aws_s3_bucket" "hosting" {
  bucket = var.root_domain_name
}

resource "aws_s3_bucket_public_access_block" "hosting_public_access" {
  bucket = aws_s3_bucket.hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.hosting.id
  index_document {
    suffix = "index.html"
  }
#   error_document {
#     key = "error.html"
#   }
}


resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
  depends_on = [ aws_s3_bucket_public_access_block.hosting_public_access ]
  bucket = aws_s3_bucket.hosting.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.hosting.id}/*"
        }
      ]
    }
  )
}

resource "aws_acm_certificate" "ssl_cert" {
  domain_name = var.root_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ssl_cert_validation_records" {
for_each = {
    for dvo in aws_acm_certificate.ssl_cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_cloudfront_distribution" "static_site_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.hosting.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com" // static site domain name
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_read_timeout = 30
      origin_keepalive_timeout = 5
    }
    connection_attempts = 3
    connection_timeout = 10
  }

  enabled             = true
  comment             = var.root_domain_name
  default_root_object = "index.html"

  aliases = [var.root_domain_name]

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

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress = true
  }

#   price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


#  The viewer_certificate is for ssl certificate settings configured via the AWS Console.
  viewer_certificate {
    cloudfront_default_certificate = false
    ssl_support_method  = "sni-only"
    acm_certificate_arn = aws_acm_certificate.ssl_cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "landing_page_A_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name = var.root_domain_name
  type = "A"

  alias {
    name = aws_cloudfront_distribution.static_site_distribution.domain_name
    zone_id = "Z2FDTNDATAQYW2" # Cloudfront distibution ID
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate_validation" "validate" {
  certificate_arn = aws_acm_certificate.ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.ssl_cert_validation_records : record.fqdn]
  timeouts {
    create = "5m"
  }
}


# SES Resources
resource "aws_ses_domain_identity" "ses_domain" {
  domain = var.root_domain_name
}

# SES domain DNS 
resource "aws_route53_record" "ses_domain_verification" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name = "_amazonses.${aws_ses_domain_identity.ses_domain.domain}"
  type = "TXT"
  ttl = 1000
  records = [aws_ses_domain_identity.ses_domain.verification_token]
}

# SES domain DKIM verification
resource "aws_ses_domain_dkim" "ses_dkim_verification" {
  domain = aws_ses_domain_identity.ses_domain.domain
}

# SES DKIM DNS records
resource "aws_route53_record" "ses_dkim_verification" {
  count = 1
  zone_id = data.aws_route53_zone.zone.zone_id
  name = "${aws_ses_domain_dkim.ses_dkim_verification.dkim_tokens[count.index]}.${aws_ses_domain_identity.ses_domain.domain}"
  type = "CNAME"
  ttl = 1000
  records = [aws_ses_domain_dkim.ses_dkim_verification.dkim_tokens[count.index]]
}

# IAM policy for SES to allow sending emails
resource "aws_iam_policy" "ses_sending_policy" {
  name        = "SES_Send_Email"
  description = "Policy to allow sending emails using SES"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ses:SendEmail"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "ses:SendRawEmail"
        Resource = "*"
      }
    ]
  })
}

# Attach above policy
resource "aws_iam_role_policy_attachment" "ses_policy_attachment" {
  policy_arn = aws_iam_policy.ses_sending_policy.arn
  role = var.lambda_exec_role_name
}

# SES event tracking and configs can come later.  Added to to-dos
# # SES tracking config
# resource "aws_sesv2_configuration_set" "ses_config" {
#   configuration_set_name = "sesv2-config-set-v1.0"
# }

# # SES event destination (tracking via SNS)
# resource "aws_sesv2_configuration_set_event_destination" "sesv2_destination" {
#   configuration_set_name = aws_sesv2_configuration_set.ses_config.configuration_set_name
#   event_destination {
#     matching_event_types = ["SEND", "REJECT", "BOUNCE", "COMPLAINT"]
#     sns_destination {
#       topic_arn = aws_sns_topic
#     }
#   }
# }