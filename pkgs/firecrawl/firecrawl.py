#!/usr/bin/env -S uv run --script --quiet
"""Scrape websites using Firecrawl API."""
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "click",
#   "firecrawl-py>=1.5,<2",
#   "pydantic",
# ]
# ///


import os
import click
import json
from firecrawl import FirecrawlApp

def output_result(result, json_output=False):
    if json_output:
        click.echo(json.dumps(result, indent=2))
    elif isinstance(result, dict) and 'markdown' in result:
        click.echo(result['markdown'])
    else:
        click.echo(str(result))

@click.group()
@click.pass_context
@click.option('--json', 'json_output', is_flag=True, help="Output results as JSON")
def cli(ctx, json_output):
    api_key = os.environ.get('FIRECRAWL_API_KEY')
    if not api_key:
        click.echo(click.style("FIRECRAWL_API_KEY environment variable is not set", fg='red'))
        ctx.exit(1)
    ctx.obj = {
        'app': FirecrawlApp(api_key=api_key),
        'json_output': json_output
    }

@cli.command()
@click.argument('url')
@click.option('--format', multiple=True, type=click.Choice(['markdown', 'html']), default=['markdown'], help='Output format')
@click.option('--html', is_flag=True, help='Shortcut for --format html')
@click.pass_obj
def scrape(obj, url, format, html):
    """Scrape a single URL"""
    app = obj['app']
    json_output = obj['json_output']
    try:
        params = {}
        if html:
            formats = ['html']
        else:
            formats = list(format) if format else ['markdown']

        if formats:
            params['formats'] = formats

        result = app.scrape_url(url, params=params if params else None)

        # Handle output based on format
        if json_output:
            click.echo(json.dumps(result, indent=2))
        elif 'html' in formats and isinstance(result, dict) and 'html' in result:
            click.echo(result['html'])
        elif isinstance(result, dict) and 'markdown' in result:
            click.echo(result['markdown'])
        else:
            output_result(result, json_output)
    except Exception as e:
        click.echo(click.style(f"Error: {str(e)}", fg='red'))

@cli.command()
@click.argument('url')
@click.option('--limit', type=int, help='Max pages to crawl')
@click.option('--format', multiple=True, type=click.Choice(['markdown', 'html']), default=['markdown'], help='Output format')
@click.pass_obj
def crawl(obj, url, limit, format):
    """Crawl a website"""
    app = obj['app']
    json_output = obj['json_output']
    params = {}
    if limit:
        params['limit'] = limit
    if format:
        params['scrapeOptions'] = {'formats': list(format)}
    try:
        result = app.crawl_url(url, params=params if params else None)
        output_result(result, json_output)
    except Exception as e:
        click.echo(click.style(f"Error: {str(e)}", fg='red'))

@cli.command()
@click.argument('url')
@click.option('--exclude-subdomains', is_flag=True, help='Exclude subdomains')
@click.option('--use-sitemap', is_flag=True, help='Use sitemap for mapping')
@click.pass_obj
def map(obj, url, exclude_subdomains, use_sitemap):
    """Map a website"""
    app = obj['app']
    json_output = obj['json_output']
    kwargs = {}
    if exclude_subdomains:
        kwargs['excludeSubdomains'] = exclude_subdomains
    if use_sitemap:
        kwargs['useSitemap'] = use_sitemap
    try:
        result = app.map_url(url, **kwargs)
        output_result(result, json_output)
    except Exception as e:
        click.echo(click.style(f"Error: {str(e)}", fg='red'))

if __name__ == '__main__':
    cli()