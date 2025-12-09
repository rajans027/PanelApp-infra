# Run Standalone Tasks

## Summary

Run standalone tasks needed for deployment.

## Description

Internal automation runbook to run standalone ECS tasks as part of the normal
deployment process.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## Input

**Tasks**: (Required) The task to run; one of ${ choices }.

### Output

None

## Limitations

**Do not run** this automation **manually**. It is meant to be used as part of deployment.
