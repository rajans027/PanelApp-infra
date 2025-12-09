# PanelApp Maintenance Mode

## Summary

Switch PanelApp's maintenance mode on or off.

## Description

PanelApp has a limited capability of maintenance mode: the database is switched into read-only mode.
This prevents any change to the data sets.
As user sessions are stored in the database, login is no longer possible.

Also an banner is displayed stating that PanelApp is in maintenance mode:

```text
${banner}
```

It is recommended to use the Change Banner automation to add a banner explaining
the reason/duration of the maintenance mode.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## Input

**MaintenanceMode**: either `on` or `off`.

## Output

None.

## Limitations

None.
