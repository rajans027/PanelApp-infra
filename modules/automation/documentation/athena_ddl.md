# Athena DDL

## Summary

Execute Athena SQL statements to define views.

## Description

The AWS Athena API is not powerful enough to create (arbitrary) views. Therefore, this automation is used to create
the views the old-fashioned way by executing SQL queries.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## Input

None

## Output

None

## Limitations

* Used for deployment only. No need to execute manually.

## Debugging

1. Check the output of the `GetQueryExecution` steps of the automation run.
2. Full details can be optained by `aws --region ${ region } athena get-query-execution --query-execution-id "$QUERY_EXECUTION_ID"`
3. The Athena query logs are in `s3://${athena_result_bucket}/`.
