#!/usr/bin/env python3
import datetime


def handler(events: dict, context: dict) -> dict:
    db_cluster = events["db_cluster"]
    release = events["release"]
    return {
        "name": f"{db_cluster}-{release}-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d-%H-%M')}"
    }
