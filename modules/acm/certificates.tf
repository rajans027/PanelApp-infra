

resource "aws_acm_certificate" "regional_cert" {
  count                     = var.create_regional_cert ? 1 : 0 #decied when the module is called from root
  domain_name               = var.dns_record
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
  }
}

resource "aws_acm_certificate" "cloudfront_cert" {
  provider                  = aws.us_east_1
  count                     = var.create_cloudfront_cert ? 1 : 0
  domain_name               = var.dns_record
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
  }
}

resource "aws_route53_record" "regional_cert_record" {
  provider = aws
  count    = var.create_regional_cert ? length(aws_acm_certificate.regional_cert[0].domain_validation_options) : 0

  name = tolist(aws_acm_certificate.regional_cert[0].domain_validation_options)[count.index].resource_record_name
  type = tolist(aws_acm_certificate.regional_cert[0].domain_validation_options)[count.index].resource_record_type

  ttl     = 60
  zone_id = var.public_zone_id

  records = [
    tolist(aws_acm_certificate.regional_cert[0].domain_validation_options)[count.index].resource_record_value
  ]
}


resource "aws_acm_certificate_validation" "regional" {
  count           = var.create_regional_cert ? 1 : 0
  certificate_arn = aws_acm_certificate.regional_cert[0].arn

  validation_record_fqdns = [
    for r in aws_route53_record.regional_cert_record : r.fqdn
  ]

  timeouts {
    create = "10m"
  }
}



resource "aws_route53_record" "cloudfront_cert_record" {
  provider = aws
  count    = var.create_cloudfront_cert ? length(aws_acm_certificate.cloudfront_cert[0].domain_validation_options) : 0

  name = tolist(aws_acm_certificate.cloudfront_cert[0].domain_validation_options)[count.index].resource_record_name
  type = tolist(aws_acm_certificate.cloudfront_cert[0].domain_validation_options)[count.index].resource_record_type

  ttl     = 60
  zone_id = var.public_zone_id

  records = [
    tolist(aws_acm_certificate.cloudfront_cert[0].domain_validation_options)[count.index].resource_record_value
  ]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  count           = var.create_cloudfront_cert ? 1 : 0
  certificate_arn = aws_acm_certificate.cloudfront_cert[0].arn

  validation_record_fqdns = [
    for r in aws_route53_record.cloudfront_cert_record : r.fqdn
  ]

  timeouts {
    create = "10m"
  }
}

