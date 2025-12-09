#############################################
# EXTERNAL DNS ZONE
#############################################

data "aws_route53_zone" "external_domain" {
  provider     = aws.dns
  name         = var.domain_name_external
  private_zone = false
}

#############################################
# (1) DNS → Cloudflare CNAME ENTRIES
#############################################

resource "aws_route53_record" "static_external" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id

  name = var.dns_record_static
  type = "CNAME"
  ttl  = 300

  # Cloudflare expects:  <hostname>.<domain>.cdn.cloudflare.net
  records = [
    "${var.dns_record_static}.${var.domain_name_external}.cdn.cloudflare.net"
  ]
}

resource "aws_route53_record" "media_external" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id

  name = var.dns_record_media
  type = "CNAME"
  ttl  = 300

  records = [
    "${var.dns_record_media}.${var.domain_name_external}.cdn.cloudflare.net"
  ]
}

#############################################
# (3) Cloudflare → DNS Alias → CloudFront
# Creates ALIAS records for CloudFront CDN
#############################################

resource "aws_route53_record" "static_external_cf" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id

  # Final hostname is: static.cdn.<app-domain>
  # app-domain = dns_record_app
  name = "static.cdn.${var.dns_record_app}"
  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.static.domain_name
    zone_id                = aws_cloudfront_distribution.static.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "media_external_cf" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id

  # media.cdn.<app-domain>
  name = "media.cdn.${var.dns_record_app}"
  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.media.domain_name
    zone_id                = aws_cloudfront_distribution.media.hosted_zone_id
    evaluate_target_health = false
  }
}
