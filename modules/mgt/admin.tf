resource "aws_launch_template" "mgt" {
  name                   = "${var.name.ws_product}-mgt"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  ebs_optimized          = false
  user_data              = terraform_data.user_data.output
  update_default_version = true

  dynamic "tag_specifications" {
    for_each = [for y in ["instance", "volume", "network-interface"] : { name = y }]
    iterator = x
    content {
      resource_type = x.value.name
      tags          = var.tags
    }
  }

  block_device_mappings {
    device_name = data.aws_ami.amazon_linux_2.root_device_name
    ebs {
      encrypted             = true
      delete_on_termination = true
      kms_key_id            = var.ebs_key_arn
    }
  }
  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = [for x in data.aws_subnet.private : x.id][0]
    security_groups             = [aws_security_group.postgres_client.id]
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
  }
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.mgt_session.name
  }

  # https://cnfl.extge.co.uk/display/security/SCP+-+IMDSv2
  metadata_options {
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
    http_endpoint               = "enabled"
  }

  # Work-around a bug in Terraform where unchanged user_data triggers a replacement;
  # https://github.com/hashicorp/terraform-provider-aws/issues/5011#issuecomment-1515154772
  lifecycle {
    ignore_changes = [
      user_data,
    ]

    replace_triggered_by = [
      terraform_data.user_data,
    ]
  }
}

resource "terraform_data" "user_data" {
  input = base64encode(
    templatefile(
      "${path.module}/templates/user_data.tpl",
      {
        image_name             = var.image_name
        database_host          = var.database_host
        database_port          = var.database_port
        database_name          = var.database_name
        database_user          = var.database_user
        aws_region             = data.aws_region.current.region
        panelapp_statics       = var.panelapp_statics
        panelapp_media         = var.panelapp_media
        panelapp_artifacts     = var.artifacts_bucket
        cdn_domain_name        = var.cdn_domain_name
        django_settings_module = var.django_settings_module
      }
    )
  )
}

resource "aws_instance" "mgt" {
  # checkov:skip=CKV_AWS_8: decommissioned soon
  # checkov:skip=CKV_AWS_126: decommissioned soon
  # checkov:skip=CKV_AWS_135: decommissioned soon
  # checkov:skip=CKV2_AWS_41: decommissioned soon
  launch_template {
    id      = aws_launch_template.mgt.id
    version = aws_launch_template.mgt.latest_version
  }

  # https://cnfl.extge.co.uk/display/security/SCP+-+IMDSv2
  metadata_options {
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
    http_endpoint               = "enabled"
  }

  # Work-around a bug in Terraform where unchanged user_data triggers a replacement;
  # https://github.com/hashicorp/terraform-provider-aws/issues/5011#issuecomment-1515154772
  lifecycle {
    ignore_changes = [
      user_data,
    ]

    replace_triggered_by = [
      terraform_data.user_data,
    ]
  }

  tags = {
    Name = aws_launch_template.mgt.name
  }
}
