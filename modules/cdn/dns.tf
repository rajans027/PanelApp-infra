data "aws_route53_zone" "external_domain" {
  provider     = aws.dns
  name         = var.dns.zone.external
  private_zone = false
}

#
# Workflow: DNS --(1)--> Cloudflare --(2)--> DNS/Alias --(3)--> Cloudfront/WAF --(4)--> S3
#
# (1) DNS -> Cloudflare
#

resource "aws_route53_record" "static_external" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id
  name     = var.dns.static.external
  type     = "CNAME"
  ttl      = 300
  records = [
    "${var.dns.static.external}.${var.dns.zone.external}.cdn.cloudflare.net"
  ]
}

resource "aws_route53_record" "media_external" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id
  name     = var.dns.media.external
  type     = "CNAME"
  ttl      = 300
  records = [
    "${var.dns.media.external}.${var.dns.zone.external}.cdn.cloudflare.net"
  ]
}

#
# (2) Cloudflare --(2)--> DNS/Alias
# This is configured for default and non-default workspaces in
# https://gitlab.com/genomicsengland/cloud/aws-core/external/cloudflare/-/blob/main/terraform/dns_genomicsengland.tf?ref_type=heads#L112
#
# (3) DNS/Alias --(3)--> Cloudfront
#

resource "aws_route53_record" "static_external_cf" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id
  name     = "static.cdn.${var.dns.app.external}"
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.panelapp_static_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.panelapp_static_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "media_external_cf" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.external_domain.zone_id
  name     = "media.cdn.${var.dns.app.external}"
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.panelapp_media_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.panelapp_media_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
