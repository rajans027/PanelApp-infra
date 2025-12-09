#!/usr/bin/env python3

import argparse
from typing import Any

import boto3


def handler(events: dict, context: dict) -> dict:
    services = (
        events["all_services"].keys()
        if (service := events["service"]) == "all"
        else [service]
    )
    args = argparse.Namespace(
        action=events["action"],
        services=services,
        cluster=events["cluster"],
        all_services=events["all_services"],
    )
    return main(args)


def main(args: argparse.Namespace) -> dict[str, dict[str, Any]]:
    ecs = boto3.client("ecs")
    do_restart = args.action == "start"
    for service in args.services:
        ecs.update_service(
            cluster=args.cluster,
            service=args.all_services[service]["name"],
            desiredCount=args.all_services[service]["desired_count"]
            if do_restart
            else 0,
            forceNewDeployment=True,
        )
    waiter = ecs.get_waiter("services_stable")
    waiter.wait(
        cluster=args.cluster,
        services=[service["name"] for service in args.all_services.values()],
    )

    reverse_lookup = {v["name"]: k for k, v in args.all_services.items()}
    result = ecs.describe_services(
        cluster=args.cluster,
        services=[service["name"] for service in args.all_services.values()],
    )

    return {
        reverse_lookup[service["serviceName"]]: {
            "service": service["serviceName"],
            "status": service["status"],
            "desired_count": service["desiredCount"],
            "running_count": service["runningCount"],
            "pending_count": service["pendingCount"],
            "task_definition": service["taskDefinition"],
        }
        for service in result["services"]
    }
