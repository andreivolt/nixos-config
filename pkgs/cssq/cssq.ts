#!/usr/bin/env -S deno run --allow-read --allow-net

import { Command } from "https://deno.land/x/cliffy@v1.0.0-rc.4/command/mod.ts";
import { selectAll } from "https://esm.sh/css-select@5.1.0";
import { parseDocument } from "https://esm.sh/htmlparser2@9.1.0";

// Function to read HTML input
async function readHTML(source?: string): Promise<string> {
  if (!source || source === "-") {
    // Read from stdin
    const stdinContent = await new Response(Deno.stdin.readable).text();
    return stdinContent;
  }

  if (source.startsWith("http://") || source.startsWith("https://")) {
    // Fetch HTML from URL
    const response = await fetch(source);
    return await response.text();
  }

  // Read from file
  try {
    return await Deno.readTextFile(source);
  } catch (error) {
    console.error(`Error reading file "${source}": ${error.message}`);
    Deno.exit(1);
  }
}

// Function to process and output matched elements
function processMatches(matches: any[], options: any) {
  if (matches.length === 0) {
    console.error("No matches found.");
    Deno.exit(0);
  }

  for (const elem of matches) {
    if (options.attribute) {
      const attrValue = elem.attribs?.[options.attribute];
      if (attrValue !== undefined) {
        console.log(attrValue);
      } else {
        console.error(`Element does not have attribute "${options.attribute}".`);
      }
    } else if (options.text) {
      console.log(getTextContent(elem));
    } else {
      // Default to outer HTML
      console.log(getOuterHTML(elem));
    }
  }
}

// Helper function to get text content
function getTextContent(node: any): string {
  if (node.type === 'text') {
    return node.data;
  }
  if (node.children) {
    return node.children.map((child: any) => getTextContent(child)).join('');
  }
  return '';
}

// Helper function to get outer HTML
function getOuterHTML(node: any): string {
  if (node.type === 'text') {
    return node.data;
  }
  if (node.type === 'tag') {
    const attrs = node.attribs ? Object.entries(node.attribs)
      .map(([key, value]) => ` ${key}="${value}"`)
      .join('') : '';
    const children = node.children ? node.children.map((child: any) => getOuterHTML(child)).join('') : '';
    return `<${node.name}${attrs}>${children}</${node.name}>`;
  }
  return '';
}

async function main(options: any, inputFile?: string) {
  const html = await readHTML(inputFile);

  try {
    const document = parseDocument(html);
    const matches = selectAll(options.selector, document);
    processMatches(matches, options);
  } catch (error) {
    console.error(`Error applying selector: ${error.message}`);
    Deno.exit(1);
  }
}

// Create command with automatic help generation
await new Command()
  .name("cssq")
  .version("1.0.0")
  .description("Query HTML using CSS selectors")
  .arguments("[file:string]")
  .option("-s, --selector <selector:string>", "CSS selector to apply", { required: true })
  .option("-a, --attribute <attribute:string>", "Extract a specific attribute from matched elements")
  .option("-t, --text", "Extract text content from matched elements")
  .option("-o, --html", "Output the outer HTML of matched elements (default)", { default: true })
  .action(async (options, inputFile) => {
    await main(options, inputFile);
  })
  .parse(Deno.args);