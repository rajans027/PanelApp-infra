#############################################
# CLOUDFRONT WAF – CLOUDFLARE ALLOW LIST
#############################################

# Cloudflare IPv4 prefix list from AWS-managed prefix lists
data "aws_ec2_managed_prefix_list" "cloudflare_ipv4" {
  filter {
    name   = "prefix-list-name"
    values = ["cloudflare_cdn"]
  }
}

locals {
  cloudflare_ipv4_prefixes = [
    for entry in data.aws_ec2_managed_prefix_list.cloudflare_ipv4.entries : entry.cidr
  ]

  # IPv6 prefixes will come from variables for flexibility
  cloudflare_ipv6_prefixes = var.cloudflare_ipv6
}

#############################################
# IPv4 IP Set
#############################################

resource "aws_wafv2_ip_set" "cloudflare_ipv4" {
  provider           = aws.us_east_1
  name               = "panelapp-${var.env_name}-cloudflare-ipset-v4"
  description        = "Cloudflare IPv4 ranges for ${var.env_name}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = local.cloudflare_ipv4_prefixes
}

#############################################
# IPv6 IP Set
#############################################

resource "aws_wafv2_ip_set" "cloudflare_ipv6" {
  provider           = aws.us_east_1
  name               = "panelapp-${var.env_name}-cloudflare-ipset-v6"
  description        = "Cloudflare IPv6 ranges for ${var.env_name}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = local.cloudflare_ipv6_prefixes
}

#############################################
# CLOUDFRONT WAF ACL — ALLOW ONLY CLOUDFLARE
#############################################

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  provider = aws.us_east_1
  name     = "panelapp-${var.env_name}-cloudfront-allow-cloudflare-only"
  scope    = "CLOUDFRONT"

  default_action {
    block {}
  }

  #############################################
  # RULE: Allow traffic from Cloudflare IP sets
  #############################################

  rule {
    name     = "allow-cloudflare-ipv4"
    priority = 0
    action { allow {} }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cloudflare_ipv4.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cloudflare-ipv4"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "allow-cloudflare-ipv6"
    priority = 1
    action { allow {} }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.cloudflare_ipv6.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cloudflare-ipv6"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }
}
