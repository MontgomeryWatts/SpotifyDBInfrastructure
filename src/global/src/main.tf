provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "global/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

locals {
  aliases = ["${var.site_url}", "www.${var.site_url}"]
}

module "s3_static_site" {
  source = "./modules/s3/static_website"
  url    = "${var.site_url}"
}
module "acm" {
  source           = "./modules/acm"
  site_domain_name = "${var.site_url}"
}

module "route53" {
  source                    = "./modules/route53"
  domain_validation_options = "${module.acm.domain_validation_options}"
  site_domain_name          = "${var.site_url}"
  certificate_arn           = "${module.acm.certificate_arn}"
  cloudfront_domain_name    = "${module.cloudfront.domain_name}"
  cloudfront_hosted_zone_id = "${module.cloudfront.hosted_zone_id}"
}


module "cloudfront" {
  source             = "./modules/cloudfront"
  certificate_arn    = "${module.acm.certificate_arn}"
  bucket_domain_name = "${module.s3_static_site.bucket_regional_domain_name}"
  bucket_origin_id   = "S3-${var.site_url}"
  aliases            = "${local.aliases}"
}

module "remote_backend" {
  source            = "./modules/terraform_backend"
  bucket_name       = "${var.remote_backend_bucket_name}"
  terraform_arn     = "${var.terraform_arn}"
  enable_versioning = true
}

module "s3_datalake" {
  source      = "./modules/datalake"
  bucket_name = "spotifydb-datalake"
}