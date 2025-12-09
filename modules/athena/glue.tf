resource "aws_glue_catalog_database" "logs" {
  name = "${replace(var.name.ws_product, "-", "_")}_logs"
}

locals {
  data_locations = {
    alb_logs = "s3://${var.alb_logs_bucket.name}/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${data.aws_region.current.region}"
    waf_logs = "s3://${var.waf_logs_bucket.name}/AWSLogs/${data.aws_caller_identity.current.account_id}/WAFLogs/${data.aws_region.current.region}/${var.alb_waf.name}"
    cloudfront_logs = {
      media  = "s3://${var.cloudfront_logs_bucket.name}/media/"
      static = "s3://${var.cloudfront_logs_bucket.name}/statics/"
    }
  }
  table_columns = {
    alb_logs = [
      "type string",
      "time string",
      "elb string",
      "client_ip string",
      "client_port int",
      "target_ip string",
      "target_port int",
      "request_processing_time double",
      "target_processing_time double",
      "response_processing_time double",
      "elb_status_code int",
      "target_status_code string",
      "received_bytes bigint",
      "sent_bytes bigint",
      "request_verb string",
      "request_url string",
      "request_proto string",
      "user_agent string",
      "ssl_cipher string",
      "ssl_protocol string",
      "target_group_arn string",
      "trace_id string",
      "domain_name string",
      "chosen_cert_arn string",
      "matched_rule_priority string",
      "request_creation_time string",
      "actions_executed string",
      "redirect_url string",
      "lambda_error_reason string",
      "target_port_list string",
      "target_status_code_list string",
      "classification string",
      "classification_reason string",
      "conn_trace_id string",
    ]
    waf_logs = [
      "timestamp bigint",
      "formatversion int",
      "webaclid string",
      "terminatingruleid string",
      "terminatingruletype string",
      "action string",
      "terminatingrulematchdetails array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>",
      "httpsourcename string",
      "httpsourceid string",
      "rulegrouplist array<struct<rulegroupid:string,terminatingrule:struct<ruleid:string,action:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>>,nonterminatingmatchingrules:array<struct<ruleid:string,action:string,overriddenaction:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>,challengeresponse:struct<responsecode:string,solvetimestamp:string>,captcharesponse:struct<responsecode:string,solvetimestamp:string>>>,excludedrules:string>>",
      "ratebasedrulelist array<struct<ratebasedruleid:string,limitkey:string,maxrateallowed:int>>",
      "nonterminatingmatchingrules array<struct<ruleid:string,action:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>,challengeresponse:struct<responsecode:string,solvetimestamp:string>,captcharesponse:struct<responsecode:string,solvetimestamp:string>>>",
      "requestheadersinserted array<struct<name:string,value:string>>",
      "responsecodesent string",
      "httprequest struct<clientip:string,country:string,headers:array<struct<name:string,value:string>>,uri:string,args:string,httpversion:string,httpmethod:string,requestid:string,fragment:string,scheme:string,host:string>",
      "labels array<struct<name:string>>",
      "captcharesponse struct<responsecode:string,solvetimestamp:string,failurereason:string>",
      "challengeresponse struct<responsecode:string,solvetimestamp:string,failurereason:string>",
      "ja3fingerprint string",
      "ja4fingerprint string",
      "oversizefields string",
      "requestbodysize int",
      "requestbodysizeinspectedbywaf int",
    ]
    cloudfront_logs = [
      "date DATE",
      "time STRING",
      "x_edge_location STRING",
      "sc_bytes BIGINT",
      "c_ip STRING",
      "cs_method STRING",
      "cs_host STRING",
      "cs_uri_stem STRING",
      "sc_status INT",
      "cs_referrer STRING",
      "cs_user_agent STRING",
      "cs_uri_query STRING",
      "cs_cookie STRING",
      "x_edge_result_type STRING",
      "x_edge_request_id STRING",
      "x_host_header STRING",
      "cs_protocol STRING",
      "cs_bytes BIGINT",
      "time_taken FLOAT",
      "x_forwarded_for STRING",
      "ssl_protocol STRING",
      "ssl_cipher STRING",
      "x_edge_response_result_type STRING",
      "cs_protocol_version STRING",
      "fle_status STRING",
      "fle_encrypted_fields INT",
      "c_port INT",
      "time_to_first_byte FLOAT",
      "x_edge_detailed_result_type STRING",
      "sc_content_type STRING",
      "sc_content_len BIGINT",
      "sc_range_start BIGINT",
      "sc_range_end BIGINT",
    ]
  }
}

resource "aws_glue_catalog_table" "alb_logs_full" {
  database_name = aws_glue_catalog_database.logs.name
  name          = "alb_logs_full"
  description   = "Full data of ALB access logs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                       = "TRUE"
    "projection.enabled"           = "true",
    "projection.day.type"          = "date",
    "projection.day.format"        = "yyyy/MM/dd",
    "projection.day.range"         = "2025/01/01,NOW",
    "projection.day.interval"      = "1",
    "projection.day.interval.unit" = "DAYS",
    "storage.location.template"    = "${local.data_locations.alb_logs}/$${day}"
  }

  partition_keys {
    name    = "day"
    type    = "string"
    comment = "format: yyyy/mm/dd"
  }

  storage_descriptor {
    location      = local.data_locations.alb_logs
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      parameters = {
        "serialization.format" = 1
        # The documented format is:
        # "input.regex" = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\\s]+?)\" \"([^\\s]+)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)?"
        # However, it appears that sometimes three extra fields (usually "-" "-" "-") are present at the end.
        "input.regex" = "([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\\s]+?)\" \"([^\\s]+)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)? ?(\"[^ ]*\")? ?(\"[^ ]*\")? ?(\"[^ ]*\")?"
      }
    }

    dynamic "columns" {
      for_each = local.table_columns.alb_logs
      content {
        name = split(" ", columns.value)[0]
        type = split(" ", columns.value)[1]
      }
    }
  }
}

resource "aws_glue_catalog_table" "waf_logs_full" {
  database_name = aws_glue_catalog_database.logs.name
  name          = "waf_logs_full"
  description   = "Full data of WAF logs"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                            = "TRUE"
    "projection.enabled"                = "true",
    "projection.log_time.format"        = "yyyy/MM/dd/HH/mm",
    "projection.log_time.interval"      = "1",
    "projection.log_time.interval.unit" = "minutes",
    "projection.log_time.range"         = "2025/01/01/00/00,NOW",
    "projection.log_time.type"          = "date",
    "storage.location.template"         = "${local.data_locations.waf_logs}/$${log_time}"
  }

  partition_keys {
    name    = "log_time"
    type    = "string"
    comment = "format: yyyy/mm/dd"
  }

  storage_descriptor {
    location      = local.data_locations.waf_logs
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "serialization.format" = 1
      }
    }

    dynamic "columns" {
      for_each = local.table_columns.waf_logs
      content {
        name = split(" ", columns.value)[0]
        type = split(" ", columns.value)[1]
      }
    }
  }
}

resource "aws_glue_catalog_table" "cloudfront_logs_full" {
  for_each      = toset(["media", "static"])
  database_name = aws_glue_catalog_database.logs.name
  name          = "cloudfront_logs_${each.value}_full"
  description   = "Full data of CloudFront logs (${each.value})"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "2"
  }

  storage_descriptor {
    location      = local.data_locations.cloudfront_logs[each.value]
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "serialization.format" = 1
        "field.delim"          = "\t"
      }
    }

    dynamic "columns" {
      for_each = local.table_columns.cloudfront_logs
      content {
        name = split(" ", columns.value)[0]
        type = split(" ", columns.value)[1]
      }
    }
  }
}

locals {
  _alb_views = {
    for days in ["1", "3", "7", "30"] : days => {
      name = "alb_logs_short_${days}day${days == "1" ? "" : "s"}"
      table = {
        arn  = aws_glue_catalog_table.alb_logs_full.arn
        name = aws_glue_catalog_table.alb_logs_full.name
      }
    }
  }
  _waf_views = {
    for days in ["1", "3", "7"] : days => {
      name = "waf_logs_short_${days}day${days == "1" ? "" : "s"}"
      table = {
        arn  = aws_glue_catalog_table.waf_logs_full.arn
        name = aws_glue_catalog_table.waf_logs_full.name
      }
    }
  }

  ddl_views = concat(
    [
      for key, value in local._alb_views :
      templatefile("${path.module}/templates/alb_logs_short_view.tftpl", {
        view_name = value.name
        days      = key
      })
    ],
    [
      for key, value in local._waf_views :
      templatefile("${path.module}/templates/waf_logs_short_view.tftpl", {
        view_name = value.name
        days      = key
      })
    ]
  )
  views = [
    for key, value in concat(values(local._alb_views), values(local._waf_views)) : {
      name = value.name
      arn  = replace(value.table.arn, value.table.name, value.name)
    }
  ]
}

locals {
  named_queries = {
    "WAF summary today" = templatefile("${path.module}/templates/waf_summary.sql.tftpl", {
      from = "waf_logs_short_1day"
    })
    "WAF summary 3 days" = templatefile("${path.module}/templates/waf_summary.sql.tftpl", {
      from = "waf_logs_short_3days"
    })
    "Slowest requests today"  = templatefile("${path.module}/templates/alb_slowest_requests.sql.tftpl", { days = "1" })
    "Slowest requests 3 days" = templatefile("${path.module}/templates/alb_slowest_requests.sql.tftpl", { days = "3" })
    "Requests per minute"     = templatefile("${path.module}/templates/requests_per_minute.sql.tftpl", {})
  }
}

resource "aws_athena_named_query" "named_queries" {
  for_each  = local.named_queries
  name      = each.key
  database  = aws_glue_catalog_database.logs.name
  workgroup = aws_athena_workgroup.alb.name
  query     = each.value
}
