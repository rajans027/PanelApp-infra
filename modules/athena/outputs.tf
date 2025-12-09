output "workgroup" {
  value = {
    arn  = aws_athena_workgroup.alb.arn
    name = aws_athena_workgroup.alb.name
  }
}

output "catalog" {
  value = {
    arn  = "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"
    name = "awsdatacatalog"
  }
}

output "database" {
  value = {
    arn  = aws_glue_catalog_database.logs.arn
    name = aws_glue_catalog_database.logs.name
  }
}

output "tables" {
  value = flatten([
    {
      name = aws_glue_catalog_table.alb_logs_full.name,
      arn  = aws_glue_catalog_table.alb_logs_full.arn
    },
    {
      name = aws_glue_catalog_table.waf_logs_full.name,
      arn  = aws_glue_catalog_table.waf_logs_full.arn
    },
    [for table in aws_glue_catalog_table.cloudfront_logs_full :
      {
        name = table.name
        arn  = table.arn
      }
    ],
    local.views
  ])
}

output "buckets" {
  value = {
    query_results = {
      arn  = aws_s3_bucket.query_results.arn
      name = aws_s3_bucket.query_results.id
    }
  }
}

output "automation" {
  value = {
    ddls = local.ddl_views
  }
}
