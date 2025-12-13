#!/usr/bin/env -S bun run --script
// @deps commander@^12.0.0 chalk@^5.0.0

import { Command } from 'commander';
import chalk from 'chalk';

// Hacker News API Parser
class HackerNewsParser {
  async fetchStory(id) {
    const response = await fetch(`https://hacker-news.firebaseio.com/v0/item/${id}.json`);
    if (!response.ok) return null;
    return await response.json();
  }

  async fetchTopStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/topstories.json');
    if (!response.ok) throw new Error('Failed to fetch top stories');
    return await response.json();
  }

  async fetchNewStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/newstories.json');
    if (!response.ok) throw new Error('Failed to fetch new stories');
    return await response.json();
  }

  async fetchBestStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/beststories.json');
    if (!response.ok) throw new Error('Failed to fetch best stories');
    return await response.json();
  }

  async fetchAskStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/askstories.json');
    if (!response.ok) throw new Error('Failed to fetch ask stories');
    return await response.json();
  }

  async fetchShowStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/showstories.json');
    if (!response.ok) throw new Error('Failed to fetch show stories');
    return await response.json();
  }

  async fetchJobStories() {
    const response = await fetch('https://hacker-news.firebaseio.com/v0/jobstories.json');
    if (!response.ok) throw new Error('Failed to fetch job stories');
    return await response.json();
  }

  formatStory(item, rank) {
    if (!item) return null;

    const now = Date.now() / 1000;
    const timeAgo = this.formatTimeAgo(now - item.time);

    return {
      id: item.id,
      title: item.title || '',
      url: item.url || `https://news.ycombinator.com/item?id=${item.id}`,
      domain: this.extractDomain(item.url),
      points: item.score || 0,
      user: item.by || null,
      timeAgo: this.shortenTimeAgo(timeAgo),
      originalTimeAgo: timeAgo,
      commentsCount: item.descendants || 0,
      commentsUrl: `https://news.ycombinator.com/item?id=${item.id}`,
      rank
    };
  }

  formatTimeAgo(seconds) {
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    const weeks = Math.floor(days / 7);
    const months = Math.floor(days / 30);
    const years = Math.floor(days / 365);

    if (years > 0) return `${years} year${years > 1 ? 's' : ''} ago`;
    if (months > 0) return `${months} month${months > 1 ? 's' : ''} ago`;
    if (weeks > 0) return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
    if (days > 0) return `${days} day${days > 1 ? 's' : ''} ago`;
    if (hours > 0) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    if (minutes > 0) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    return 'just now';
  }

  parseTimeToMinutes(timeAgo) {
    if (!timeAgo) return 0;

    const timeStr = timeAgo.toLowerCase();
    const match = timeStr.match(/(\d+)\s*(minute|hour|day|week|month|year)/);
    if (!match) return 0;

    const value = parseInt(match[1]);
    const unit = match[2];

    switch (unit) {
      case 'minute': return value;
      case 'hour': return value * 60;
      case 'day': return value * 60 * 24;
      case 'week': return value * 60 * 24 * 7;
      case 'month': return value * 60 * 24 * 30;
      case 'year': return value * 60 * 24 * 365;
      default: return 0;
    }
  }

  shortenTimeAgo(timeAgo) {
    if (!timeAgo) return null;

    return timeAgo
      .replace(/(\d+)\s*minutes?/i, '$1m')
      .replace(/(\d+)\s*hours?/i, '$1h')
      .replace(/(\d+)\s*days?/i, '$1d')
      .replace(/(\d+)\s*weeks?/i, '$1w')
      .replace(/(\d+)\s*months?/i, '$1mo')
      .replace(/(\d+)\s*years?/i, '$1y')
      .replace(/\s+ago/i, '')
      .replace(/just now/i, 'now')
      .trim();
  }

  extractDomain(url) {
    try {
      if (!url || url.startsWith('item?id=')) return 'news.ycombinator.com';
      const urlObj = new URL(url);
      return urlObj.hostname.replace('www.', '');
    } catch {
      return null;
    }
  }

  async fetchAndParse(page = '', targetCount = 30) {
    try {
      let storyIds;

      switch (page) {
        case 'newest':
        case 'new':
          storyIds = await this.fetchNewStories();
          break;
        case 'best':
          storyIds = await this.fetchBestStories();
          break;
        case 'ask':
          storyIds = await this.fetchAskStories();
          break;
        case 'show':
          storyIds = await this.fetchShowStories();
          break;
        case 'jobs':
          storyIds = await this.fetchJobStories();
          break;
        case '':
        case 'front':
        default:
          storyIds = await this.fetchTopStories();
          break;
      }

      // Limit to requested count
      const limitedIds = storyIds.slice(0, targetCount);

      // Fetch stories in parallel
      const storyPromises = limitedIds.map(id => this.fetchStory(id));
      const stories = await Promise.all(storyPromises);

      // Format and filter out null stories
      return stories
        .map((story, index) => this.formatStory(story, index + 1))
        .filter(story => story !== null);

    } catch (error) {
      throw new Error(`Failed to fetch HN data: ${error.message}`);
    }
  }
}

async function shortenUrl(url, timeout = 2000, retries = 2) {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      const response = await fetch('http://xs/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: `url=${encodeURIComponent(url)}`,
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        const shortUrl = await response.text();
        if (shortUrl && shortUrl.startsWith('http://xs/')) {
          return shortUrl.trim();
        }
      }

      if (attempt < retries) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (error) {
      if (attempt < retries) {
        await new Promise(resolve => setTimeout(resolve, 500));
        continue;
      }
    }
  }

  return url;
}

async function shortenUrls(urls) {
  const results = [];
  const batchSize = 10;

  for (let i = 0; i < urls.length; i += batchSize) {
    const batch = urls.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(url => shortenUrl(url, 2000))
    );
    results.push(...batchResults);
  }

  return results;
}

if (import.meta.main) {
  const program = new Command();

  const pages = ['', 'newest', 'front', 'ask', 'show', 'jobs', 'best'];

  program
    .name('hn')
    .description('Parse Hacker News pages using API')
    .version('1.0.0')
    .argument('[page]', 'HN page type (default: front page)', '')
    .option('-j, --json', 'output as JSON')
    .option('-v, --verbose', 'verbose output with details')
    .option('-t, --table', 'compact table output with shortened URLs')
    .option('-n, --count <number>', 'limit number of stories', '30')
    .option('-s, --sort <field>', 'sort by field (points, comments, time)', 'rank')
    .addHelpText('after', `
Pages: ${pages.map(p => p || 'front').join(', ')}`);

  program.parse();

  const options = program.opts();
  const page = program.args[0] || '';

  if (!pages.includes(page)) {
    console.error(`Error: Unknown page '${page}'. Available: ${pages.join(', ')}`);
    process.exit(1);
  }

  try {
    const parser = new HackerNewsParser();
    const count = parseInt(options.count);
    let stories = await parser.fetchAndParse(page, count > 0 ? count : 30);

    // Sort stories if requested
    if (options.sort && options.sort !== 'rank') {
      stories = stories.sort((a, b) => {
        switch (options.sort) {
          case 'points':
            return (b.points || 0) - (a.points || 0);
          case 'comments':
            return (b.commentsCount || 0) - (a.commentsCount || 0);
          case 'time':
            return parser.parseTimeToMinutes(a.originalTimeAgo) - parser.parseTimeToMinutes(b.originalTimeAgo);
          default:
            return 0;
        }
      });
    }

    if (options.json) {
      console.log(JSON.stringify(stories, null, 2));
    } else if (options.verbose) {
      stories.forEach(story => {
        console.log(chalk.bold(`[${story.title}](${story.url})`));
        const commentsUrl = story.commentsUrl || `https://news.ycombinator.com/item?id=${story.id}`;
        console.log(
          chalk.yellow(`${story.points || 0} points`) +
          chalk.gray(` • ${story.user || 'unknown'} • ${story.timeAgo || 'unknown'} • `) +
          chalk.dim(`[${story.commentsCount || 0} comments](${commentsUrl})`)
        );
        console.log();
      });
    } else if (options.table || !options.verbose) {
      // Shorten URLs for both table and default views
      const isAskHN = page === 'ask';

      // Collect all URLs to shorten in one batch
      const allUrls = [];
      stories.forEach(story => {
        if (!isAskHN) {
          allUrls.push(story.url);
        }
        allUrls.push(story.commentsUrl || `https://news.ycombinator.com/item?id=${story.id}`);
      });

      // Batch shorten all URLs
      const shortenedUrls = await shortenUrls(allUrls);

      // Map shortened URLs back to stories
      const shortenedStories = stories.map((story, index) => {
        let shortUrl, shortCommentsUrl;

        if (isAskHN) {
          shortCommentsUrl = shortenedUrls[index];
          shortUrl = story.url;
        } else {
          shortUrl = shortenedUrls[index * 2];
          shortCommentsUrl = shortenedUrls[index * 2 + 1];
        }

        return {
          ...story,
          shortUrl,
          shortCommentsUrl,
          truncatedTitle: story.title.length > 80 ? story.title.substring(0, 77) + '...' : story.title
        };
      });

      if (options.table) {
        // Table format
        const titleWidth = Math.max(5, Math.min(80, Math.max(...shortenedStories.map(s => s.truncatedTitle.length))));
        const urlWidth = isAskHN ? 0 : Math.max(3, Math.max(...shortenedStories.map(s => s.shortUrl.length)));
        const timeWidth = Math.max(4, Math.max(...shortenedStories.map(s => (s.timeAgo || '').length)));
        const commentsWidth = Math.max(8, Math.max(...shortenedStories.map(s => s.shortCommentsUrl.length)));

        shortenedStories.forEach((story, index) => {
          const rowParts = [
            story.truncatedTitle.padEnd(titleWidth)
          ];

          if (!isAskHN) {
            rowParts.push(chalk.dim(story.shortUrl.padEnd(urlWidth)));
          }

          rowParts.push(
            chalk.yellow((story.points || 0).toString().padStart(4)),
            chalk.gray((story.timeAgo || '').padEnd(timeWidth)),
            chalk.gray((story.commentsCount || 0).toString().padStart(4)),
            chalk.dim(story.shortCommentsUrl.padEnd(commentsWidth))
          );

          console.log(rowParts.join(' '));
        });
      } else {
        // Default format: all metadata on one line
        shortenedStories.forEach(story => {
          const meta = [
            chalk.yellow(`${story.points || 0}p`),
            chalk.gray(story.user || 'unknown'),
            chalk.gray(story.timeAgo || ''),
            chalk.gray(`${story.commentsCount || 0}c`)
          ].join(' ');

          console.log(`${story.title} ${chalk.dim(story.shortUrl)} ${meta} ${chalk.dim(story.shortCommentsUrl)}`);
        });
      }
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}