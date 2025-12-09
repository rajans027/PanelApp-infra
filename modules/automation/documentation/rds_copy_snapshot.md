# Copy RDS Snapshot

## Summary

Copy and re-encrypts a shared DB snapshot.

## Description

Re-encrypt a copy of a shared snapshot so it can be used in this environment.

The identifier of the new snapshot is `copy-<original_snapshot_identifier>`.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## I/O

### Input Parameter

**SnapshotArn**: The ARN of the shared snapshot.

### Output

The name of the created snapshot.

## Limitations

None
