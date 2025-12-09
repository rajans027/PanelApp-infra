resource "aws_route53_zone" "internal_domain" {
  name = var.domain_name_internal
}

resource "aws_route53_zone" "external_domain" {
  
  name = var.domain_name_external 
}



#regional certificate for application load balancer in GEL account

module "acm_OH" {
  source = "./modules/acm"

  create_regional_cert   = true
  create_cloudfront_cert = false

  public_zone_id = aws_route53_zone.internal_domain.zone_id
  dns_record     = var.dns_record_app

  env_name   = var.env_name
  account_id = var.account_id
  region     = var.region


  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "media_acm_OntarioHealth" {
  source = "./modules/acm"

  create_regional_cert   = false
  create_cloudfront_cert = true

  public_zone_id = aws_route53_zone.external_domain.zone_id
  dns_record     = var.dns_record_media

  env_name   = var.env_name
  account_id = var.account_id
  region     = var.region


  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "static_acm_OntarioHealth" {
  source = "./modules/acm"

  create_regional_cert   = false
  create_cloudfront_cert = true

  public_zone_id = aws_route53_zone.external_domain.zone_id
  dns_record     = var.dns_record_static

  env_name   = var.env_name
  account_id = var.account_id
  region     = var.region

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
