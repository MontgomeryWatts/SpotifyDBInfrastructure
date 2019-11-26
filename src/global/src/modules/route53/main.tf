resource "aws_route53_zone" "spotifydb_hosted_zone" {
  name = "${var.site_domain_name}"
}

resource "aws_route53_record" "spotifydb_cert_record" {
  name    = "${var.domain_validation_options.resource_record_name}"
  type    = "${var.domain_validation_options.resource_record_type}"
  zone_id = "${aws_route53_zone.spotifydb_hosted_zone.zone_id}"
  records = ["${var.domain_validation_options.resource_record_value}"]
  ttl     = 300
}

resource "aws_route53_record" "apex_record" {
  zone_id = "${aws_route53_zone.spotifydb_hosted_zone.zone_id}"
  name    = "${var.site_domain_name}"
  type    = "A"

  alias {
    name                   = "${var.cloudfront_domain_name}"
    zone_id                = "${var.cloudfront_hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_record" {
  zone_id = "${aws_route53_zone.spotifydb_hosted_zone.zone_id}"
  name    = "www.${var.site_domain_name}"
  type    = "A"

  alias {
    name                   = "${var.cloudfront_domain_name}"
    zone_id                = "${var.cloudfront_hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate_validation" "spotifydb_cert_validation" {
  certificate_arn         = "${var.certificate_arn}"
  validation_record_fqdns = ["${aws_route53_record.spotifydb_cert_record.fqdn}"]
}