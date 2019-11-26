output "domain_validation_options" {
  value = "${aws_acm_certificate.spotifydb_cert.domain_validation_options.0}"
}

output "certificate_arn" {
  value = "${aws_acm_certificate.spotifydb_cert.arn}"
}