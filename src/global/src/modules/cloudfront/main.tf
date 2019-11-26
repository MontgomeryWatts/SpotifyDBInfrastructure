resource "aws_cloudfront_distribution" "cloudfront" {
  origin {
    domain_name = "${var.bucket_domain_name}"
    origin_id   = "${var.bucket_origin_id}"
  }

  wait_for_deployment = false
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = "${var.aliases}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.bucket_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${var.certificate_arn}"
    minimum_protocol_version = "TLSv1.2_2018"
    ssl_support_method       = "sni-only"
  }
}