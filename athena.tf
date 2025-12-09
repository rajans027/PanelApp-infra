module "athena" {
  source                 = "./modules/athena"
  name                   = "athena-${var.project_name}-${var.env_name}"
  alb_logs_bucket        = module.services.buckets.elb_logs
  waf_logs_bucket        = module.services.buckets.waf_logs
  cloudfront_logs_bucket = module.cdn_ws.buckets.logs
  alb_waf                = module.services.alb_waf
}
