#!/usr/bin/env -S bun run --script
// @deps commander@^12.0.0 chalk@^5.0.0

import { existsSync, mkdirSync, readFileSync, writeFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';

class CacheManager {
  constructor() {
    this.cacheDir = join(homedir(), '.cache', 'hn-comments');
    this.ensureCacheDir();
  }

  ensureCacheDir() {
    if (!existsSync(this.cacheDir)) {
      mkdirSync(this.cacheDir, { recursive: true });
    }
  }

  getCachePath(itemId) {
    return join(this.cacheDir, `${itemId}.json`);
  }

  has(itemId, maxAgeMinutes = 60) {
    const cachePath = this.getCachePath(itemId);
    if (!existsSync(cachePath)) {
      return false;
    }

    const stats = statSync(cachePath);
    const ageMinutes = (Date.now() - stats.mtime.getTime()) / (1000 * 60);
    return ageMinutes < maxAgeMinutes;
  }

  get(itemId) {
    const cachePath = this.getCachePath(itemId);
    if (!existsSync(cachePath)) {
      return null;
    }

    try {
      const data = readFileSync(cachePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      return null;
    }
  }

  set(itemId, data) {
    const cachePath = this.getCachePath(itemId);
    try {
      writeFileSync(cachePath, JSON.stringify(data, null, 2));
    } catch (error) {
      console.warn('Failed to write cache:', error.message);
    }
  }
}

export class HackerNewsCommentsParser {
  parseComments(html) {
    const comments = [];
    const commentMatches = html.matchAll(/<tr class="athing comtr"[^>]*id="(\d+)"[\s\S]*?(?=<tr class="athing comtr"|<\/table>|$)/g);

    for (const match of commentMatches) {
      const commentHtml = match[0];
      const comment = this.parseCommentHtml(commentHtml, match[1]);
      if (comment) {
        comments.push(comment);
      }
    }

    return this.buildCommentTree(comments);
  }

  parseCommentHtml(html, id) {
    try {
      // Extract indentation level
      const indentMatch = html.match(/<td class="ind"[^>]*indent="(\d+)"/);
      const indent = indentMatch ? parseInt(indentMatch[1]) : 0;

      // Extract user
      const userMatch = html.match(/<a[^>]*class="hnuser"[^>]*>([^<]*)</);
      const user = userMatch ? this.decodeHtml(userMatch[1]) : '[deleted]';

      // Extract time - both absolute and relative
      const timeMatch = html.match(/<span class="age"[^>]*title="([^"]*)"[^>]*><a[^>]*>([^<]*)<\/a>/);
      let timeAgo = '';
      let timestamp = null;

      if (timeMatch) {
        const titleContent = timeMatch[1]; // "2025-06-13T17:19:31 1749835171"
        timeAgo = this.decodeHtml(timeMatch[2]); // "1 day ago"

        // Extract ISO timestamp from title
        const isoMatch = titleContent.match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/);
        if (isoMatch) {
          timestamp = isoMatch[1] + 'Z'; // Add Z for UTC
        }
      }

      // Extract comment text
      const textMatch = html.match(/<div class="commtext[^"]*">([\s\S]*?)<\/div>/);
      let text = '';
      if (textMatch) {
        text = textMatch[1]
          .replace(/<p>/g, '\n\n')
          .replace(/<\/p>/g, '')
          .replace(/<a[^>]*href="([^"]*)"[^>]*>([^<]*)<\/a>/g, '$2 ($1)')
          .replace(/<[^>]*>/g, '')
          .trim();
        text = this.decodeHtml(text);
      }

      return {
        id: parseInt(id),
        user,
        time: timestamp || timeAgo, // Use absolute timestamp for JSON, fallback to relative
        timeAgo, // Keep relative time for human readable output
        text,
        indent,
        children: []
      };
    } catch (error) {
      console.error('Error parsing comment:', error);
      return null;
    }
  }

  buildCommentTree(comments) {
    const roots = [];
    const stack = [];

    for (const comment of comments) {
      // Adjust stack to match indentation level
      while (stack.length > comment.indent) {
        stack.pop();
      }

      if (stack.length === 0) {
        roots.push(comment);
      } else {
        stack[stack.length - 1].children.push(comment);
      }

      stack.push(comment);
    }

    return roots;
  }

  decodeHtml(html) {
    if (typeof DOMParser !== 'undefined') {
      const doc = new DOMParser().parseFromString(html, 'text/html');
      return doc.documentElement.textContent;
    }

    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&#39;': "'",
      '&nbsp;': ' '
    };

    return html.replace(/&[#\w]+;/g, entity => entities[entity] || entity);
  }

  async fetchAndParse(itemId, useCache = true, maxAgeMinutes = 60) {
    const cache = new CacheManager();

    // Check cache first
    if (useCache && cache.has(itemId, maxAgeMinutes)) {
      const cached = cache.get(itemId);
      if (cached) {
        return cached;
      }
    }

    const url = `https://news.ycombinator.com/item?id=${itemId}`;

    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; HN-Comments/1.0)'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const html = await response.text();

      // Extract story details
      let story = null;

      // Try to find the story info
      const titleMatch = html.match(/<span class="titleline"><a[^>]*>([^<]*)</);
      if (titleMatch) {
        const title = this.decodeHtml(titleMatch[1]);

        const urlMatch = html.match(/<span class="titleline"><a href="([^"]*)"[^>]*>/);
        const storyUrl = urlMatch ? urlMatch[1] : '';

        const pointsMatch = html.match(/<span[^>]*class="score"[^>]*>(\d+) points?</);
        const points = pointsMatch ? parseInt(pointsMatch[1]) : 0;

        const userMatch = html.match(/<a[^>]*class="hnuser"[^>]*>([^<]*)</);
        const user = userMatch ? this.decodeHtml(userMatch[1]) : null;

        story = {
          id: parseInt(itemId),
          title,
          url: storyUrl.startsWith('item?id=') ? `https://news.ycombinator.com/${storyUrl}` : storyUrl,
          points,
          user
        };
      }

      const result = {
        story,
        comments: this.parseComments(html)
      };

      // Cache the result
      if (useCache) {
        cache.set(itemId, result);
      }

      return result;
    } catch (error) {
      throw new Error(`Failed to fetch HN comments: ${error.message}`);
    }
  }
}

import { Command } from 'commander';
import chalk from 'chalk';
import { spawn } from 'node:child_process';

if (typeof process !== 'undefined' && process.argv[1] && process.argv[1].endsWith('hn-comments')) {
  const program = new Command();

  program
    .name('hn-comments')
    .description('Parse Hacker News comment threads')
    .version('1.0.0')
    .argument('<item-id>', 'HN item ID or URL')
    .option('-j, --json', 'output as JSON')
    .option('-f, --flat', 'output as JSONL (one comment per line)')
    .option('--no-cache', 'disable caching')
    .option('--max-age <minutes>', 'maximum cache age in minutes', '60');

  program.parse();

  const options = program.opts();
  let itemId = program.args[0];

  // Extract ID from URL if provided
  if (itemId.includes('item?id=')) {
    const match = itemId.match(/item\?id=(\d+)/);
    if (match) {
      itemId = match[1];
    }
  }

  if (!/^\d+$/.test(itemId)) {
    console.error('Error: Invalid item ID. Please provide a numeric ID or HN URL.');
    process.exit(1);
  }

  try {
    const parser = new HackerNewsCommentsParser();
    const useCache = options.cache !== false;
    const maxAge = parseInt(options.maxAge) || 60;
    const result = await parser.fetchAndParse(itemId, useCache, maxAge);

    if (options.flat) {
      // Flatten comments in topological order (depth-first traversal)
      const flattenComments = (comments, parentId = null) => {
        const flattened = [];
        const traverse = (comments, parentId = null) => {
          comments.forEach(comment => {
            const { children, ...commentData } = comment;
            if (parentId) {
              commentData.parentId = parentId;
            }
            flattened.push(commentData);
            if (children && children.length > 0) {
              traverse(children, comment.id);
            }
          });
        };
        traverse(comments, parentId);
        return flattened;
      };

      if (options.json) {
        // JSONL output - one comment per line
        if (result.story) {
          console.log(JSON.stringify(result.story));
        }

        const flatComments = flattenComments(result.comments);
        flatComments.forEach(comment => {
          console.log(JSON.stringify(comment));
        });
      } else {
        // Human readable flat output
        if (result.story) {
          console.log(chalk.bold(result.story.title));
          console.log(chalk.dim(result.story.url || `https://news.ycombinator.com/item?id=${itemId}`));
          console.log();
        }

        const flatComments = flattenComments(result.comments);
        flatComments.forEach(comment => {
          const text = comment.text ? comment.text.replace(/\n+/g, ' ').trim() : '[deleted]';
          console.log(`${chalk.yellow(comment.user)} ${chalk.gray(comment.timeAgo)} ${text}`);
        });
      }
    } else if (options.json) {
      console.log(JSON.stringify(result, null, 2));
    } else {
      // Use tree-render for tree output (default)
      const treeRender = spawn('tree-render', ['--header=story'], {
        stdio: ['pipe', 'inherit', 'inherit']
      });

      treeRender.stdin.write(JSON.stringify(result));
      treeRender.stdin.end();

      treeRender.on('error', (err) => {
        // Fallback to simple output if tree-render not found
        console.error('Warning: tree-render not found, using simple output');

        if (result.story) {
          console.log(chalk.bold(result.story.title));
          console.log(chalk.dim(result.story.url || `https://news.ycombinator.com/item?id=${itemId}`));
          console.log(chalk.yellow(`${result.story.points} points`) + chalk.gray(` by ${result.story.user}`));
          console.log();
        }

        const printSimple = (comments, depth = 0) => {
          comments.forEach(comment => {
            const indent = '  '.repeat(depth);
            console.log(indent + chalk.yellow(comment.user) + ' ' + chalk.gray(`(${comment.timeAgo})`));
            const lines = comment.text.split('\n');
            lines.forEach(line => {
              if (line.trim()) {
                console.log(indent + '  ' + line);
              }
            });
            console.log();
            if (comment.children.length > 0) {
              printSimple(comment.children, depth + 1);
            }
          });
        };

        printSimple(result.comments);
      });
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}