data "aws_ec2_managed_prefix_list" "cloudflare_ipv4" {
  filter {
    name   = "prefix-list-name"
    values = ["cloudflare_cdn"]
  }
}

locals {
  prefixes_ipv4 = [for x in data.aws_ec2_managed_prefix_list.cloudflare_ipv4.entries : x.cidr]
  prefixes_ipv6 = local.cloudflare.ipv6

  ip_sets = local.is_default_ws ? [
    aws_wafv2_ip_set.cloudflare_ipv4[0],
    aws_wafv2_ip_set.cloudflare_ipv6[0]
    ] : [
    data.aws_wafv2_ip_set.cloudflare_ipv4[0],
    data.aws_wafv2_ip_set.cloudflare_ipv6[0]
  ]
}

resource "aws_wafv2_ip_set" "cloudflare_ipv4" {
  count              = local.is_default_ws_count
  provider           = aws.us_east_1
  name               = "${var.name.ws_product}-cloudflare-ipset-v4"
  description        = "${var.name.ws_product}-cloudflare-ipset-v4"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = local.prefixes_ipv4
}

data "aws_wafv2_ip_set" "cloudflare_ipv4" {
  count    = 1 - local.is_default_ws_count
  provider = aws.us_east_1
  name     = "panelapp-cloudflare-ipset-v4"
  scope    = "CLOUDFRONT"
}

resource "aws_wafv2_ip_set" "cloudflare_ipv6" {
  count              = local.is_default_ws_count
  provider           = aws.us_east_1
  name               = "${var.name.ws_product}-cloudflare-ipset-v6"
  description        = "${var.name.ws_product}-cloudflare-ipset-v6"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = local.prefixes_ipv6
}

data "aws_wafv2_ip_set" "cloudflare_ipv6" {
  count    = 1 - local.is_default_ws_count
  provider = aws.us_east_1
  name     = "panelapp-cloudflare-ipset-v6"
  scope    = "CLOUDFRONT"
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  provider = aws.us_east_1
  name     = "${var.name.ws_product}-cloudfront-allow-cloudflare-only"
  scope    = "CLOUDFRONT"

  default_action {
    block {}
  }

  dynamic "rule" {
    iterator = ip_set
    for_each = local.ip_sets
    content {
      name     = ip_set.value.description
      priority = ip_set.key
      action {
        allow {}
      }
      statement {
        ip_set_reference_statement {
          arn = ip_set.value.arn
        }
      }

      visibility_config {
        metric_name                = ip_set.value.description
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "BlockedList"
    sampled_requests_enabled   = true
  }
}
