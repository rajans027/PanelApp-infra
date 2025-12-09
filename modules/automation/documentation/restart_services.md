# Restart Services

## Summary

Start or stop PanelApp ECS services.

## Description

Start or stop continuously running components (ECS services) of PanelApp.
Starting an already running component forces a re-deployment.

The services are

* **web**: the main application
* **worker**: background process for report generation, large file uploads etc.
* **worker_beat**: scheduler for work tasks

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## I/O

### Input Parameter

**Action**: Whether to `start` (re-start) or `stop` the service.

**Service**: Which service to change; one of `${ join("`, `", services) }`, or `all`.

### Output

None

## Limitations

None
