#!/usr/bin/env python3

import argparse
import datetime
import io
import json

import boto3


def parse_args() -> argparse.Namespace:
    return argparse.Namespace()


def handler(events: dict, context: dict) -> dict:
    args = argparse.Namespace(
        input_bucket=events["input_bucket"].strip(),
        output_bucket=events["output_bucket"],
        data_path=events["data_path"].strip(),
        data_as_string=events["data_string"].strip(),
        exec_id=events["execution_id"].strip(),
    )
    if not args.data_path and not args.data_as_string:
        raise ValueError("Either DataString or DataPath must be provided")
    if args.data_path and args.data_as_string:
        raise ValueError("DataString and DataPath are mutually exclusive")
    return main(args)


def main(args: argparse.Namespace) -> dict:
    input_key = f"ensembl_id_update/{datetime.date.today().isoformat()}/{args.exec_id}/update_data.json"
    output_key = (
        f"ensembl_id_update/{datetime.date.today().isoformat()}/{args.exec_id}/logs"
    )
    if args.data_path:
        input_key = (
            args.data_path.removeprefix("s3://")
            .removeprefix(args.input_bucket)
            .removeprefix("/")
        )
    elif args.data_as_string:
        s3 = boto3.client("s3")
        stream = io.BytesIO(
            json.dumps(
                json.loads(args.data_as_string), sort_keys=True, indent=4
            ).encode()
        )
        s3.upload_fileobj(stream, args.input_bucket, input_key)
    else:
        raise ValueError("Missing data input")
    return {
        "output_path": f"s3://{args.output_bucket}/{output_key}",
        "input_path": f"s3://{args.input_bucket}/{input_key}",
    }
