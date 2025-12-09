#!/usr/bin/env python3

import argparse

import boto3

START_MARKER = "<div>"
END_MARKER = "</div>"


def parse_args() -> argparse.Namespace:
    return argparse.Namespace()


def handler(events: dict, context: dict) -> dict:
    args = argparse.Namespace(
        action=events["action"],
        banner=events["banner"].strip(),
        ssm_parameter=events["ssm_parameter"],
        web_service=events["web_service"],
        cluster=events["cluster"],
    )
    if not args.banner:
        raise ValueError("Banner can not be empty")
    return main(args)


def main(args: argparse.Namespace) -> dict[str, str]:
    ssm = boto3.client("ssm")
    response = ssm.get_parameter(Name=args.ssm_parameter, WithDecryption=False)
    old_banners = response["Parameter"]["Value"]
    banners = old_banners.strip()
    new_banner = f"{START_MARKER}{args.banner}{END_MARKER}"
    if args.action == "add":
        if new_banner not in banners:
            new_banners = f"{banners}{new_banner}"
        else:
            new_banners = banners
    elif args.action == "remove":
        new_banners = banners.replace(new_banner, "")
    else:
        new_banners = banners
    if not new_banners.strip():
        new_banners = " "

    if new_banners != old_banners:
        parameters = dict(
            Name=args.ssm_parameter,
            Value=new_banners,
            Type="String",
            Overwrite=True,
            Tier="Standard",
            DataType="text",
        )
        ssm.put_parameter(**parameters)

        ecs = boto3.client("ecs")
        ecs.update_service(
            cluster=args.cluster,
            service=args.web_service,
            forceNewDeployment=True,
        )
        waiter = ecs.get_waiter("services_stable")
        waiter.wait(
            cluster=args.cluster,
            services=[args.web_service],
        )
    return {"Banners": banner_list(new_banners)}


def banner_list(banners: str) -> str:
    banner_list_ = banners.strip().split(END_MARKER + START_MARKER)
    if banner_list_:
        banner_list_[0] = banner_list_[0].replace(START_MARKER, "")
        banner_list_[-1] = banner_list_[-1].replace(END_MARKER, "")
    return "|".join(banner_list_)


if __name__ == "__main__":
    main(parse_args())
