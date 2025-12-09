# Create RDS Snapshot

## Summary

Create a DB snapshot.

## Description

Create a RDS Aurora Postgres snapshot and share it with all other accounts.

The snapshot name has the format

```shell
<db_cluster>-<release>-<timestamp>
```

where `release` is the name of the release like `nembus` or `nembus-increment-1`

If no `release` is given, `ad-hoc` is used.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## I/O

### Input Parameter

**Release**: The release name associated with this snapshot (default: `ad-hoc`); must only contain lower case letters,
digits, and hyphens.

### Output

The name of the snapshot.

## Limitations

None
