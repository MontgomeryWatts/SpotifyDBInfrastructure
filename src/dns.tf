resource "aws_acm_certificate" "spotifydb_cert" {
  domain_name               = var.site_url
  subject_alternative_names = ["*.${var.site_url}"]
  validation_method         = "DNS"
}

resource "aws_route53_zone" "spotifydb_hosted_zone" {
  name = var.site_url
}

resource "aws_route53_record" "spotifydb_cert_record" {
  name    = aws_acm_certificate.spotifydb_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.spotifydb_cert.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.spotifydb_hosted_zone.zone_id
  records = [aws_acm_certificate.spotifydb_cert.domain_validation_options.0.resource_record_value]
  ttl     = 300
}

resource "aws_route53_record" "apex_record" {
  zone_id = aws_route53_zone.spotifydb_hosted_zone.zone_id
  name    = var.site_url
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_record" {
  zone_id = aws_route53_zone.spotifydb_hosted_zone.zone_id
  name    = "www.${var.site_url}"
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate_validation" "spotifydb_cert_validation" {
  certificate_arn         = aws_acm_certificate.spotifydb_cert.arn
  validation_record_fqdns = [aws_route53_record.spotifydb_cert_record.fqdn]
}