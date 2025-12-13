#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests",
#   "click>=8.0",
#   "rich",
#   "lxml",
# ]
# ///

import os
import sys
import subprocess
import click

@click.command()
@click.argument("query")
@click.option("-l", "--language", default="ru", help="Language code (e.g., ru, en)")
@click.option("--location", help="Geographic location for search")
@click.option("--country", default="ru", help="Country code (e.g., ru, us)")
@click.option("-c", "--count", default=10, type=int, help="Number of results")
@click.option("-p", "--page", default=0, type=int, help="Page number (0-based)")
@click.option("--provider", type=click.Choice(["yandex", "yandex-v2"]),
              default="yandex", help="Yandex search provider")
@click.option("--search-type", default="web", help="Search type: web, images, videos")
@click.option("--no-cache", is_flag=True, help="Force fresh results")
@click.option("--json-output", is_flag=True, help="Output raw JSON")
@click.option("--api-key", envvar="SERPAPI_API_KEY", help="API key")
@click.option("--yandex-api-key", envvar="YANDEX_API_KEY", help="Yandex Cloud API key")
@click.option("--yandex-folder-id", envvar="YANDEX_FOLDER_ID", help="Yandex Cloud folder ID")
@click.pass_context
def main(ctx, query, language, location, country, count, page, provider, search_type,
         no_cache, json_output, api_key, yandex_api_key, yandex_folder_id):
    """Yandex search with Russian defaults.

    This is a convenience wrapper around web-search with Yandex-optimized defaults.
    """

    # Build command for web-search
    cmd = [
        "web-search",
        query,
        "--provider", provider,
        "--language", language,
        "--country", country,
        "--count", str(count),
        "--page", str(page),
        "--search-type", search_type,
    ]

    if location:
        cmd.extend(["--location", location])
    if no_cache:
        cmd.append("--no-cache")
    if json_output:
        cmd.append("--json-output")
    if api_key:
        cmd.extend(["--api-key", api_key])
    if yandex_api_key:
        cmd.extend(["--yandex-api-key", yandex_api_key])
    if yandex_folder_id:
        cmd.extend(["--yandex-folder-id", yandex_folder_id])

    # Execute web-search
    try:
        result = subprocess.run(cmd, check=True)
        sys.exit(result.returncode)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except FileNotFoundError:
        click.echo("Error: web-search command not found", err=True)
        sys.exit(1)

if __name__ == "__main__":
    main()