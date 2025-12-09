#cloud-config
runcmd:
- [ yum-config-manager, --disable, datadog ]
- [ systemctl, enable, --now, docker ]
- [ usermod, -a, -G, docker, ec2-user ]
- [ usermod, -a, -G, docker, ssm-user ]
- [ yum, install, -y, jq, python3-pip, postgresql17 ]
- 'curl -fL "https://github.com/docker/compose/releases/download/v2.38.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
- [ chmod, a+rx, /usr/local/bin/docker-compose ]
- [ mkdir, /home/ec2-user/.docker ]
- [ chown, "ec2-user:ec2-user", /home/ec2-user/.docker ]



write_files:
- path: /etc/profile.d/ssm_vars.sh
  content: |
    export PGPASSWORD=$(aws --region eu-west-2 ssm get-parameters --name /panelapp/database/master_password --with-decryption --query 'Parameters[].Value' --output text)
    export PGHOST=${database_host}
    export PGUSER=${database_user}
    export PGDATABASE=${database_name}
    export AWS_S3_ARTIFACTS_BUCKET_NAME=${panelapp_artifacts}
    [ "$PS1" = "\\s-\\v\\\$ " ] && PS1="[\u@\h \W]\\$ "
- path: /home/ec2-user/docker-compose.yml
  content: |
    services:
      web:
        image: ${image_name}
        restart: "no"
        environment:
          - DATABASE_HOST=$PGHOST
          - DATABASE_PASSWORD=$PGPASSWORD
          - DATABASE_NAME=$PGDATABASE
          - DATABASE_USER=$PGUSER
          - DATABASE_PORT=${database_port}
          - AWS_REGION=${aws_region}
          - AWS_S3_STATICFILES_BUCKET_NAME=${panelapp_statics}
          - AWS_S3_MEDIAFILES_BUCKET_NAME=${panelapp_media}
          - AWS_S3_STATICFILES_CUSTOM_DOMAIN=${cdn_domain_name}
          - AWS_S3_MEDIAFILES_CUSTOM_DOMAIN=${cdn_domain_name}
          - DJANGO_SETTINGS_MODULE=${django_settings_module}
          - DJANGO_LOG_LEVEL=INFO
          # Not used by the management box
          - DEFAULT_FROM_EMAIL=dummy@dummy.com
          - PANEL_APP_EMAIL=dummy@dummy.com
          - EMAIL_HOST=localhost
          - EMAIL_PORT=25
          - PANEL_APP_BASE_URL=http://localhost
        entrypoint:
          - manage
          - shell
