#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests",
#   "click>=8.0",
#   "rich",
# ]
# ///

import os
import json
import requests
import click
from rich.console import Console
from rich.table import Table

console = Console()

SERPAPI_ENDPOINT = "https://serpapi.com/search"

def search_with_serpapi(query, lang="en", location=None, country=None, count=10, page=0,
                        engine="google", search_type="web", no_autocorrect=False,
                        no_filter=False, no_cache=False, api_key=None, **kwargs):
    """Search using SerpApi (Google or Yandex engine)"""
    params = {
        "api_key": api_key,
    }

    if engine == "yandex":
        # Yandex-specific parameters
        params["engine"] = "yandex"
        params["text"] = query
        params["p"] = page

        if lang:
            params["lang"] = lang
        if country:
            params["lr"] = country  # Yandex uses lr for region
    else:
        # Google search (default)
        params["engine"] = "google"
        params["q"] = query
        params["start"] = page * count

        if lang:
            params["hl"] = lang
        if country:
            params["gl"] = country
        if location:
            params["location"] = location

        # Handle search types
        if search_type != "web":
            type_map = {
                "images": "isch",
                "videos": "vid",
                "news": "nws",
                "shopping": "shop",
                "patents": "pts",
                "local": "lcl"
            }
            if search_type in type_map:
                params["tbm"] = type_map[search_type]

        # Google-specific options
        if no_autocorrect:
            params["nfpr"] = "1"
        if no_filter:
            params["filter"] = "0"

        # Add any extra parameters from kwargs
        for key, value in kwargs.items():
            if value is not None:
                params[key] = value

    if no_cache:
        params["no_cache"] = "true"

    # Make requests to get the desired count
    all_results = []
    max_per_request = 100 if engine == "google" else 10
    req_num = 0

    while len(all_results) < count:
        current_params = params.copy()

        if engine == "google":
            current_params["num"] = max_per_request
            current_params["start"] = page * count + len(all_results)
        else:  # yandex
            current_params["p"] = page + req_num

        try:
            response = requests.get(SERPAPI_ENDPOINT, params=current_params)
            response.raise_for_status()
            data = response.json()

            # Merge results
            if req_num == 0:
                merged_data = data
            else:
                if "organic_results" in data:
                    merged_data.setdefault("organic_results", []).extend(data["organic_results"])

            # Collect organic results
            if "organic_results" in data:
                results_this_request = len(data["organic_results"])
                all_results.extend(data["organic_results"])

                # If no results returned, we've exhausted the available results
                if results_this_request == 0:
                    break
            else:
                # No organic_results key means no more results
                break

            req_num += 1

        except requests.exceptions.RequestException as e:
            console.print(f"[red]SerpApi request failed: {e}[/red]")
            if req_num == 0:
                return None
            break

    # Return merged data with limited results
    if all_results:
        merged_data["organic_results"] = all_results[:count]

    return merged_data if 'merged_data' in locals() else None

@click.command()
@click.argument("query")
@click.option("-l", "--language", help="Language code (e.g., en, ru)")
@click.option("--location", help="Geographic location for search")
@click.option("--country", help="Country code (e.g., us, ru)")
@click.option("-c", "--count", default=10, type=int, help="Number of results")
@click.option("-p", "--page", default=0, type=int, help="Page number (0-based)")
@click.option("--engine", "-e", type=click.Choice(["google", "yandex"]),
              default="google", help="Search engine provider")
@click.option("--search-type", default="web", help="Search type: web, images, videos, news, shopping, patents, local")
@click.option("--no-autocorrect", is_flag=True, help="Disable autocorrect (Google only)")
@click.option("--no-filter", is_flag=True, help="Disable similar result filters (Google only)")
@click.option("--no-cache", is_flag=True, help="Force fresh results")
@click.option("--json-output", is_flag=True, help="Output raw JSON")
@click.option("--api-key", envvar="SERPAPI_API_KEY", help="SerpAPI key")
@click.option("--domain", help="Google domain to use (e.g., google.com, google.fr)")
def main(query, language, location, country, count, page, engine, search_type,
         no_autocorrect, no_filter, no_cache, json_output, api_key, domain):
    """Web search using Google or Yandex via SerpApi.

    Examples:
        web-search "python programming"
        web-search "кофе" -e yandex -l ru --country ru
        web-search "coffee shop" --location "New York"
    """

    if not api_key:
        console.print("[red]Error: SERPAPI_API_KEY environment variable is required[/red]")
        return 1

    if not json_output:
        console.print(f"[bold blue]Searching {engine} for:[/bold blue] {query}")
        if location:
            console.print(f"Location: {location}")

    # Build extra parameters for Google search
    extra_params = {}
    if domain and engine == "google":
        extra_params["google_domain"] = domain

    data = search_with_serpapi(
        query=query,
        lang=language,
        location=location,
        country=country,
        count=count,
        page=page,
        engine=engine,
        search_type=search_type,
        no_autocorrect=no_autocorrect,
        no_filter=no_filter,
        no_cache=no_cache,
        api_key=api_key,
        **extra_params
    )

    if data:
        if json_output:
            console.print_json(data=data)
        else:
            display_serpapi_results(data, engine)
    else:
        console.print("[red]No results found or API error[/red]")
        return 1

def display_serpapi_results(data, engine):
    """Display SerpApi results in a formatted way"""

    # Show organic results
    if "organic_results" in data and data["organic_results"]:
        results = data["organic_results"]
        console.print(f"\n[green]Found {len(results)} results[/green]\n")

        for i, result in enumerate(results, 1):
            title = result.get("title", "No title")
            link = result.get("link", "")
            snippet = result.get("snippet", "")

            console.print(f"[bold cyan]{i}. {title}[/bold cyan]")
            console.print(f"   {link}")
            if snippet:
                console.print(f"   {snippet}")
            console.print()
    else:
        console.print("[yellow]No organic results found.[/yellow]")

    # Show local results if present
    if "local_results" in data and data["local_results"]:
        local = data["local_results"]
        console.print(f"\n[green]Local results ({len(local)} places):[/green]\n")

        for i, place in enumerate(local, 1):
            name = place.get("title", "")
            address = place.get("address", "")
            rating = place.get("rating", "")

            console.print(f"[bold]{i}. {name}[/bold]")
            if address:
                console.print(f"   Address: {address}")
            if rating:
                console.print(f"   Rating: {rating}")
            console.print()

    # Show knowledge graph if present
    if "knowledge_graph" in data and data["knowledge_graph"]:
        kg = data["knowledge_graph"]
        if kg.get("title"):
            console.print("[green]Knowledge Graph:[/green]")
            console.print(f"[bold]{kg['title']}[/bold]")
            if kg.get("description"):
                console.print(kg["description"])
            console.print()

    # Show related questions
    if "related_questions" in data and data["related_questions"]:
        questions = data["related_questions"]
        console.print(f"\n[green]Related Questions:[/green]\n")
        for q in questions[:5]:
            if q.get("question"):
                console.print(f"  • {q['question']}")
        console.print()

if __name__ == "__main__":
    main()
