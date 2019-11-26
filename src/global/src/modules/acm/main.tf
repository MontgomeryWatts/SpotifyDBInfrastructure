resource "aws_acm_certificate" "spotifydb_cert" {
  domain_name               = "${var.site_domain_name}"
  subject_alternative_names = ["*.${var.site_domain_name}"]
  validation_method         = "DNS"
}