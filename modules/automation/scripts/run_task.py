#!/usr/bin/env python3
"""Run an ECS task and wait for completion"""

import argparse

import boto3


def parse_args() -> argparse.Namespace:
    return argparse.Namespace()


def handler(events: dict, context: dict) -> None:
    args = argparse.Namespace(
        cluster=events["cluster"],
        task_arn=events["task_arn"],
        subnets=events["subnets"],
        security_groups=events["security_groups"],
        exec_id=events["execution_id"],
        environment=events.get("environment", {}),
        container_name=events["task_arn"].rpartition("/")[-1].partition(":")[0],
    )
    main(args)


def main(args: argparse.Namespace) -> None:
    ecs = boto3.client("ecs")
    container_overrides = []
    if args.environment:
        container_overrides = [
            {
                "name": args.container_name,
                "environment": [
                    {"name": k, "value": v} for k, v in args.environment.items()
                ],
            }
        ]
    response = ecs.run_task(
        cluster=args.cluster,
        taskDefinition=args.task_arn,
        count=1,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": args.subnets,
                "securityGroups": args.security_groups,
                "assignPublicIp": "DISABLED",
            }
        },
        overrides={"containerOverrides": container_overrides},
        propagateTags="TASK_DEFINITION",
        enableECSManagedTags=True,
        startedBy=args.exec_id,
    )

    tasks = [task["taskArn"] for task in response["tasks"]]
    waiter = ecs.get_waiter("tasks_stopped")
    waiter.wait(cluster=args.cluster, tasks=tasks)

    result = ecs.describe_tasks(cluster=args.cluster, tasks=tasks)
    for task in result["tasks"]:
        for container in task["containers"]:
            if (rc := container["exitCode"]) != 0:
                raise RuntimeError(
                    f"Non-zero exit code: task: {task['taskArn']}, container: {container['name']}, code: {rc}"
                )


if __name__ == "__main__":
    main(parse_args())
