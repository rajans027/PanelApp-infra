output "api_key" {
  value = {
    arn = local.cloudflare_api_key.arn
  }
}
