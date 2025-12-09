#!/usr/bin/env python3

import argparse
import itertools
from typing import Iterable, Iterator

import boto3


def batched(iterable: Iterable, n: int) -> Iterator[tuple[str]]:
    # only available in Python 3.12
    # batched('ABCDEFG', 3) → ABC DEF G
    if n < 1:
        raise ValueError("n must be at least one")
    iterator = iter(iterable)
    while batch := tuple(itertools.islice(iterator, n)):
        yield batch


def get_inactive_task_definition_arns(client) -> list[str]:
    task_definitions = []
    paginator = client.get_paginator("list_task_definitions")
    for page in paginator.paginate(status="INACTIVE"):
        task_definitions.extend(page["taskDefinitionArns"])
    return task_definitions


def delete_inactive_task_definition(client, task_definitions: Iterable[str]) -> None:
    deleted = 0
    for batch in batched(task_definitions, n=10):
        result = client.delete_task_definitions(taskDefinitions=batch)
        deleted += len(result["taskDefinitions"])
    print(f"Deleted {deleted} inactive task definitions", flush=True)


def parse_args() -> argparse.Namespace:
    return argparse.Namespace()


def handler(events: dict, context: dict) -> None:
    args = argparse.Namespace()
    main(args)


def main(args: argparse.Namespace) -> None:
    client = boto3.client("ecs")
    task_definitions = get_inactive_task_definition_arns(client)
    delete_inactive_task_definition(client, task_definitions)


if __name__ == "__main__":
    main(parse_args())
