# Change PanelApp Banners

## Summary

Add a banner to, or remove it from, PanelApp.

## Description

PanelApp can display one or more banners on top of the home page.
This can be used to announce for example an upcoming maintenance window.

Multiple banners are displayed in their own rows.
Some limited HTML markup is permitted, like `<strong>...</strong>` or `<a href="mailto:....">`.

## Scope

Environment: **${ env }**

Terraform workspace: **${ tf_workspace }**

## Input

**Banner**: The banner to add or to remove. Must be an exact match when removing the banner.

**Mode**: What to do with the banner; either `add` or `remove`.

## Output

A pipe (`|`) separated list of banners after the banner was added/removed. Empty if no banner as displayed.

## Limitations

* Banners must be unique.
* Do not include `<div>...</div>` markup in the banner.
