#!/usr/bin/env -S bun run --script
// @deps playwright@^1 commander@^10

import { chromium, devices } from 'playwright';
import { writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { homedir } from 'os';
import { Command } from 'commander';

const program = new Command();

program
  .name('tweet-screenshot')
  .description('Take a screenshot of a tweet')
  .argument('<tweet_url>', 'The tweet URL or tweet ID to screenshot')
  .option('-o, --output <path>', 'Output file path or "stdout"', '')
  .parse();

const tweetInput = program.args[0];
const args = { output: program.opts().output };

const SCREENSHOT_DIR = join(homedir(), 'drive/tweets');

async function screenshotTweet(tweetInput, outputPath) {
  const match = tweetInput.match(/https?:\/\/(?:twitter\.com|x\.com)\/.+\/status\/(\d+)(\?.*)?$/);
  let tweetId = match?.[1];

  if (!tweetId) {
    if (/^\d+$/.test(tweetInput)) {
      tweetId = tweetInput;
    } else {
      console.error('Invalid input. Please provide a valid tweet URL or numeric tweet ID.');
      return;
    }
  }

  const browser = await chromium.launch({
    executablePath: '/Users/andrei/Library/Caches/ms-playwright/chromium-1097/chrome-mac/Chromium.app/Contents/MacOS/Chromium'
  });
  const device = devices['Desktop Chrome HiDPI'];
  const context = await browser.newContext(device);

  const page = await context.newPage();
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.goto(`https://twitter.com/i/web/status/${tweetId}`);

  await page.mouse.wheel(0, -100);
  await page.waitForTimeout(1000);
  await page.mouse.wheel(0, 100);
  await page.waitForTimeout(1000);

  try {
    await page.waitForSelector('#layers', { timeout: 3000 });
  } catch {}

  await page.evaluate(() => {
    document.querySelector('#layers')?.remove();
    document.querySelector('[aria-label="Home timeline"]')?.firstChild?.remove();
    document.querySelectorAll('[data-testid="caret"]').forEach(el => el.remove());

    const replyNode = document.querySelector('[aria-label="Reply"]');
    if (replyNode) {
      let parent = replyNode.parentNode;
      while (parent && parent.getAttribute('role') !== 'group') {
        parent = parent.parentNode;
      }
      parent?.remove();
    }
  });

  const screenshotData = await page.locator('[data-testid="tweet"]').screenshot();

  if (outputPath === '-') {
    process.stdout.write(screenshotData);
  } else {
    let screenshotPath;
    if (outputPath) {
      screenshotPath = outputPath.endsWith('/') ?
        join(outputPath, `${tweetId}.png`) : outputPath;
    } else {
      screenshotPath = join(SCREENSHOT_DIR, `${tweetId}.png`);
    }

    mkdirSync(dirname(screenshotPath), { recursive: true });
    writeFileSync(screenshotPath, screenshotData);
    console.log(`screenshot saved to: ${screenshotPath}`);
  }

  await browser.close();
}

if (args.output === '-') {
  await screenshotTweet(tweetInput, '-');
} else {
  const screenshotPath = args.output || join(SCREENSHOT_DIR, `${tweetInput.split('/').pop()}.png`);
  await screenshotTweet(tweetInput, screenshotPath);
}