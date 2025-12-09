#!/usr/bin/env python3


def handler(events: dict, context: dict) -> dict:
    source_arn = events["source_snapshot_arn"]
    return {"target_snapshot_name": f"copy-{source_arn.split(':')[-1]}"}
