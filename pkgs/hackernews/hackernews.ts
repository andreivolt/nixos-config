#!/usr/bin/env -S deno run --allow-net --allow-read --allow-write --allow-env
// /// script
// dependencies = []
// ///

import { serve } from "jsr:@std/http/server@1.0.10";
import { Database } from "jsr:@db/sqlite@0.11";

const db = new Database("hackernews.db");

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    karma INTEGER DEFAULT 0,
    about TEXT DEFAULT ''
  );

  CREATE TABLE IF NOT EXISTS stories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    url TEXT DEFAULT '',
    text TEXT DEFAULT '',
    points INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL,
    type TEXT DEFAULT 'url',
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    story_id INTEGER NOT NULL,
    parent_id INTEGER DEFAULT NULL,
    user_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    points INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL,
    edited_at INTEGER DEFAULT NULL,
    depth INTEGER DEFAULT 0,
    FOREIGN KEY (story_id) REFERENCES stories(id),
    FOREIGN KEY (parent_id) REFERENCES comments(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS votes_stories (
    user_id INTEGER NOT NULL,
    story_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, story_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (story_id) REFERENCES stories(id)
  );

  CREATE TABLE IF NOT EXISTS votes_comments (
    user_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, comment_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (comment_id) REFERENCES comments(id)
  );

  CREATE TABLE IF NOT EXISTS favorites_stories (
    user_id INTEGER NOT NULL,
    story_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, story_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (story_id) REFERENCES stories(id)
  );

  CREATE TABLE IF NOT EXISTS favorites_comments (
    user_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, comment_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (comment_id) REFERENCES comments(id)
  );

  CREATE TABLE IF NOT EXISTS hidden_stories (
    user_id INTEGER NOT NULL,
    story_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, story_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (story_id) REFERENCES stories(id)
  );

  CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories(created_at DESC);
  CREATE INDEX IF NOT EXISTS idx_stories_type ON stories(type);
  CREATE INDEX IF NOT EXISTS idx_comments_story_id ON comments(story_id);
  CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id);
`);

async function hashPassword(password: string): Promise<string> {
  const msgBuffer = new TextEncoder().encode(password);
  const hashBuffer = await crypto.subtle.digest("SHA-256", msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

function timeAgo(timestamp: number): string {
  const now = Date.now();
  const seconds = Math.floor((now - timestamp) / 1000);

  if (seconds < 60) return `${seconds} second${seconds === 1 ? '' : 's'} ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} minute${minutes === 1 ? '' : 's'} ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days} day${days === 1 ? '' : 's'} ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months} month${months === 1 ? '' : 's'} ago`;
  const years = Math.floor(days / 365);
  return `${years} year${years === 1 ? '' : 's'} ago`;
}

function hnRank(points: number, ageHours: number): number {
  return (points - 1) / Math.pow(ageHours + 2, 1.8);
}

function getDomain(url: string): string {
  try {
    const u = new URL(url);
    return u.hostname.replace(/^www\./, '');
  } catch {
    return '';
  }
}

function getUserFromCookie(req: Request): any {
  const cookie = req.headers.get("cookie");
  if (!cookie) return null;

  const sessionMatch = cookie.match(/session=([^;]+)/);
  if (!sessionMatch) return null;

  const sessionId = sessionMatch[1];
  const now = Date.now();

  const session = db.query("SELECT * FROM sessions WHERE id = ? AND expires_at > ?", [sessionId, now])[0];
  if (!session) return null;

  const user = db.query("SELECT * FROM users WHERE id = ?", [session[1]])[0];
  if (!user) return null;

  return { id: user[0], username: user[1], karma: user[4], about: user[5] };
}

function createSession(userId: number): string {
  const sessionId = crypto.randomUUID();
  const expiresAt = Date.now() + (30 * 24 * 60 * 60 * 1000);
  db.query("INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, ?)", [sessionId, userId, expiresAt]);
  return sessionId;
}

function setCookie(name: string, value: string): string {
  return `${name}=${value}; Path=/; HttpOnly; Max-Age=${30 * 24 * 60 * 60}`;
}

const CSS = `
body { font-family: Verdana, Geneva, sans-serif; font-size: 10pt; color: #828282; background: #f6f6ef; margin: 0; padding: 0; }
a { color: #000; text-decoration: none; }
a:visited { color: #828282; }
.header { background: #ff6600; padding: 2px; }
.header a { color: #000; }
.header .logo { border: 1px solid white; margin-right: 4px; padding: 0px 2px; font-weight: bold; }
.header .title { font-weight: bold; margin-right: 10px; }
.header .nav { }
.header .user { float: right; }
.content { padding: 8px; }
.itemlist { background: #f6f6ef; }
.athing { margin: 0; padding: 0; }
.athing .title { }
.athing .rank { color: #828282; text-align: right; padding-right: 5px; min-width: 25px; }
.athing .votelinks { text-align: center; min-width: 15px; }
.subtext { padding-left: 40px; color: #828282; font-size: 8pt; }
.subtext a { color: #828282; }
.comment { margin-top: 8px; font-size: 9pt; }
.comment .comhead { color: #828282; font-size: 8pt; }
.comment .comhead a { color: #828282; }
.comment .commtext { margin-top: 4px; }
.comment .reply { font-size: 8pt; text-decoration: underline; }
.comment .collapse { color: #828282; cursor: pointer; }
.spacer { height: 10px; }
.yclinks { text-align: center; color: #828282; font-size: 8pt; margin-top: 20px; }
.yclinks a { color: #828282; }
textarea { font-family: monospace; }
input[type=text], input[type=password] { font-family: monospace; padding: 2px; }
.indent0 { margin-left: 0px; }
.indent1 { margin-left: 40px; }
.indent2 { margin-left: 80px; }
.indent3 { margin-left: 120px; }
.indent4 { margin-left: 160px; }
.indent5 { margin-left: 200px; }
.pagetop { padding: 2px; }
table { border-collapse: collapse; }
table td { padding: 0; }
.votearrow { color: #828282; font-size: 10pt; }
.votearrow:hover { color: #ff6600; }
`;

function layout(title: string, body: string, user: any = null): string {
  const userSection = user
    ? `<span class="user"><a href="/user?id=${user.username}">${user.username}</a> (${user.karma}) | <a href="/logout">logout</a></span>`
    : `<span class="user"><a href="/login">login</a></span>`;

  return `<!DOCTYPE html>
<html>
<head>
  <title>${title}</title>
  <style>${CSS}</style>
</head>
<body>
  <table class="header" width="100%" cellspacing="0">
    <tr>
      <td class="pagetop">
        <span class="logo">Y</span>
        <span class="title"><a href="/">Hacker News</a></span>
        <span class="nav">
          <a href="/newest">new</a> |
          <a href="/front">past</a> |
          <a href="/newcomments">comments</a> |
          <a href="/ask">ask</a> |
          <a href="/show">show</a> |
          <a href="/jobs">jobs</a> |
          <a href="/submit">submit</a>
        </span>
        ${userSection}
      </td>
    </tr>
  </table>
  <div class="content">
    ${body}
  </div>
  <div class="yclinks">
    <a href="/guidelines">Guidelines</a> |
    <a href="/faq">FAQ</a> |
    <a href="/lists">Lists</a> |
    <a href="https://github.com/HackerNews/API">API</a> |
    <a href="/security">Security</a> |
    <a href="/legal">Legal</a> |
    <a href="https://www.ycombinator.com/apply/">Apply to YC</a> |
    <a href="mailto:hn@ycombinator.com">Contact</a>
  </div>
</body>
</html>`;
}

function storyRow(story: any, rank: number, user: any | null, showVote: boolean = true): string {
  const voted = user && db.query("SELECT 1 FROM votes_stories WHERE user_id = ? AND story_id = ?", [user.id, story.id]).length > 0;
  const hidden = user && db.query("SELECT 1 FROM hidden_stories WHERE user_id = ? AND story_id = ?", [user.id, story.id]).length > 0;

  if (hidden) return '';

  const voteLink = showVote && user && !voted
    ? `<a href="/vote?id=${story.id}&type=story&dir=up" class="votearrow">▲</a>`
    : '';

  const titleLink = story.url
    ? `<a href="${story.url}">${story.title}</a> <span class="sitestr">(<a href="from?site=${getDomain(story.url)}">${getDomain(story.url)}</a>)</span>`
    : `<a href="/item?id=${story.id}">${story.title}</a>`;

  const commentsText = story.comment_count === 1 ? '1 comment' : `${story.comment_count} comments`;
  const discussLink = story.url ? `<a href="/item?id=${story.id}">${commentsText}</a>` : `<a href="/item?id=${story.id}">discuss</a>`;

  return `
    <tr class="athing" id="${story.id}">
      <td class="rank" valign="top" align="right">${rank}.</td>
      <td class="votelinks" valign="top" align="center">${voteLink}</td>
      <td class="title"><span class="titleline">${titleLink}</span></td>
    </tr>
    <tr>
      <td colspan="2"></td>
      <td class="subtext">
        ${story.points} point${story.points === 1 ? '' : 's'} by <a href="/user?id=${story.username}">${story.username}</a>
        <a href="/item?id=${story.id}">${timeAgo(story.created_at)}</a> |
        <a href="/hide?id=${story.id}">hide</a> |
        ${discussLink} |
        <a href="/fav?id=${story.id}&type=story">favorite</a>
      </td>
    </tr>
    <tr class="spacer" style="height:5px"></tr>
  `;
}

function commentTree(comment: any, user: any | null, storyId: number): string {
  const voted = user && db.query("SELECT 1 FROM votes_comments WHERE user_id = ? AND comment_id = ?", [user.id, comment.id]).length > 0;
  const favorited = user && db.query("SELECT 1 FROM favorites_comments WHERE user_id = ? AND comment_id = ?", [user.id, comment.id]).length > 0;

  const voteLink = user && !voted
    ? `<a href="/vote?id=${comment.id}&type=comment&dir=up&goto=item?id=${storyId}" class="votearrow">▲</a> `
    : '';

  const canEdit = user && user.id === comment.user_id && (Date.now() - comment.created_at < 2 * 60 * 60 * 1000);
  const editLink = canEdit ? ` | <a href="/edit?id=${comment.id}">edit</a>` : '';
  const deleteLink = canEdit ? ` | <a href="/delete?id=${comment.id}&type=comment">delete</a>` : '';

  const favText = favorited ? 'unfavorite' : 'favorite';

  let html = `
    <div class="comment indent${Math.min(comment.depth, 5)}" id="c${comment.id}">
      <div class="comhead">
        ${voteLink}
        <a href="/user?id=${comment.username}">${comment.username}</a>
        <a href="/item?id=${comment.id}">${timeAgo(comment.created_at)}</a>
        ${comment.edited_at ? ' <i>(edited)</i>' : ''}
        | <a href="/item?id=${comment.id}">parent</a>
        | <a href="/context?id=${comment.id}">context</a>
        | <a href="/fav?id=${comment.id}&type=comment">${favText}</a>
        ${editLink}${deleteLink}
        | <span class="collapse" onclick="toggleCollapse(${comment.id})">[–]</span>
      </div>
      <div class="commtext" id="text${comment.id}">${comment.text.replace(/\n/g, '<p>')}</div>
      ${user ? `<div class="reply"><a href="/reply?id=${comment.id}&goto=item?id=${storyId}">reply</a></div>` : ''}
      <div id="children${comment.id}">
  `;

  const children = db.query(
    `SELECT c.*, u.username
     FROM comments c
     JOIN users u ON c.user_id = u.id
     WHERE c.parent_id = ?
     ORDER BY c.created_at ASC`,
    [comment.id]
  );

  for (const child of children) {
    const childObj = {
      id: child[0],
      story_id: child[1],
      parent_id: child[2],
      user_id: child[3],
      text: child[4],
      points: child[5],
      created_at: child[6],
      edited_at: child[7],
      depth: child[8],
      username: child[9]
    };
    html += commentTree(childObj, user, storyId);
  }

  html += `</div></div>`;
  return html;
}

async function handleRequest(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname;
  const user = getUserFromCookie(req);

  if (path === "/") {
    const page = parseInt(url.searchParams.get("p") || "0");
    const limit = 30;
    const offset = page * limit;

    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       ORDER BY (s.points - 1) / POWER((? - s.created_at) / 3600000.0 + 2, 1.8) DESC
       LIMIT ? OFFSET ?`,
      [Date.now(), limit + 1, offset]
    );

    const hasMore = stories.length > limit;
    const displayStories = stories.slice(0, limit);

    let html = '<table class="itemlist" cellspacing="0">';
    displayStories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, offset + i + 1, user);
    });
    html += '</table>';

    if (hasMore) {
      html += `<div style="margin-top:10px; margin-left:40px;"><a href="/?p=${page + 1}">More</a></div>`;
    }

    return new Response(layout("Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/newest") {
    const page = parseInt(url.searchParams.get("p") || "0");
    const limit = 30;
    const offset = page * limit;

    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       ORDER BY s.created_at DESC
       LIMIT ? OFFSET ?`,
      [limit + 1, offset]
    );

    const hasMore = stories.length > limit;
    const displayStories = stories.slice(0, limit);

    let html = '<table class="itemlist" cellspacing="0">';
    displayStories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, offset + i + 1, user);
    });
    html += '</table>';

    if (hasMore) {
      html += `<div style="margin-top:10px; margin-left:40px;"><a href="/newest?p=${page + 1}">More</a></div>`;
    }

    return new Response(layout("New Links | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/front") {
    const filter = url.searchParams.get("day") || "";

    let html = `<div>
      <a href="/front?day=">day</a> |
      <a href="/front?day=month">month</a> |
      <a href="/front?day=year">year</a>
    </div><br>`;

    let cutoff = Date.now();
    if (filter === "month") cutoff -= 30 * 24 * 60 * 60 * 1000;
    else if (filter === "year") cutoff -= 365 * 24 * 60 * 60 * 1000;
    else cutoff -= 24 * 60 * 60 * 1000;

    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE s.created_at >= ?
       ORDER BY s.created_at DESC
       LIMIT 30`,
      [cutoff]
    );

    html += '<table class="itemlist" cellspacing="0">';
    stories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, i + 1, user);
    });
    html += '</table>';

    return new Response(layout("Past Links | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/ask") {
    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE s.type = 'ask'
       ORDER BY s.created_at DESC
       LIMIT 30`
    );

    let html = '<table class="itemlist" cellspacing="0">';
    stories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, i + 1, user);
    });
    html += '</table>';

    return new Response(layout("Ask | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/show") {
    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE s.type = 'show'
       ORDER BY s.created_at DESC
       LIMIT 30`
    );

    let html = '<table class="itemlist" cellspacing="0">';
    stories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, i + 1, user);
    });
    html += '</table>';

    return new Response(layout("Show | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/jobs") {
    return new Response(layout("Jobs | Hacker News", "<p>No jobs posted yet.</p>", user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/newcomments") {
    const comments = db.query(
      `SELECT c.*, u.username, s.title
       FROM comments c
       JOIN users u ON c.user_id = u.id
       JOIN stories s ON c.story_id = s.id
       ORDER BY c.created_at DESC
       LIMIT 30`
    );

    let html = '<table cellspacing="0">';
    for (const comment of comments) {
      const commentObj = {
        id: comment[0],
        story_id: comment[1],
        user_id: comment[3],
        text: comment[4],
        created_at: comment[6],
        username: comment[9],
        title: comment[10]
      };

      html += `
        <tr><td>
          <div class="comment">
            <div class="comhead">
              <a href="/user?id=${commentObj.username}">${commentObj.username}</a>
              <a href="/item?id=${commentObj.id}">${timeAgo(commentObj.created_at)}</a>
              | <a href="/item?id=${commentObj.story_id}">on: ${commentObj.title}</a>
            </div>
            <div class="commtext">${commentObj.text.substring(0, 200)}${commentObj.text.length > 200 ? '...' : ''}</div>
          </div>
        </td></tr>
      `;
    }
    html += '</table>';

    return new Response(layout("New Comments | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/item") {
    const id = url.searchParams.get("id");
    if (!id) {
      return new Response("Not found", { status: 404 });
    }

    const isComment = db.query("SELECT 1 FROM comments WHERE id = ?", [parseInt(id)]).length > 0;

    if (isComment) {
      const comment = db.query(
        `SELECT c.*, u.username, s.id as story_id, s.title
         FROM comments c
         JOIN users u ON c.user_id = u.id
         JOIN stories s ON c.story_id = s.id
         WHERE c.id = ?`,
        [parseInt(id)]
      )[0];

      if (!comment) {
        return new Response("Not found", { status: 404 });
      }

      const commentObj = {
        id: comment[0],
        story_id: comment[1],
        parent_id: comment[2],
        user_id: comment[3],
        text: comment[4],
        points: comment[5],
        created_at: comment[6],
        edited_at: comment[7],
        depth: comment[8],
        username: comment[9],
        story_title: comment[11]
      };

      let html = `<div style="margin-bottom:20px;">
        <a href="/item?id=${commentObj.story_id}">${commentObj.story_title}</a>
      </div>`;

      html += commentTree(commentObj, user, commentObj.story_id);

      html += `<script>
        function toggleCollapse(id) {
          const text = document.getElementById('text' + id);
          const children = document.getElementById('children' + id);
          if (text.style.display === 'none') {
            text.style.display = 'block';
            children.style.display = 'block';
          } else {
            text.style.display = 'none';
            children.style.display = 'none';
          }
        }
      </script>`;

      return new Response(layout(commentObj.story_title + " | Hacker News", html, user), {
        headers: { "Content-Type": "text/html" }
      });
    }

    const story = db.query(
      `SELECT s.*, u.username
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE s.id = ?`,
      [parseInt(id)]
    )[0];

    if (!story) {
      return new Response("Not found", { status: 404 });
    }

    const storyObj = {
      id: story[0],
      user_id: story[1],
      title: story[2],
      url: story[3],
      text: story[4],
      points: story[5],
      created_at: story[6],
      type: story[7],
      username: story[8]
    };

    const voted = user && db.query("SELECT 1 FROM votes_stories WHERE user_id = ? AND story_id = ?", [user.id, storyObj.id]).length > 0;
    const voteLink = user && !voted
      ? `<a href="/vote?id=${storyObj.id}&type=story&dir=up&goto=item?id=${storyObj.id}" class="votearrow">▲</a> `
      : '';

    let html = `<div style="margin-bottom:20px;">
      <div style="font-size:11pt;">
        ${voteLink}
        ${storyObj.url ? `<a href="${storyObj.url}">${storyObj.title}</a>` : storyObj.title}
        ${storyObj.url ? `<span class="sitestr"> (${getDomain(storyObj.url)})</span>` : ''}
      </div>
      <div style="margin-top:5px; color:#828282; font-size:8pt;">
        ${storyObj.points} points by <a href="/user?id=${storyObj.username}">${storyObj.username}</a>
        ${timeAgo(storyObj.created_at)} |
        <a href="/hide?id=${storyObj.id}&goto=/">hide</a> |
        <a href="/fav?id=${storyObj.id}&type=story">favorite</a>
      </div>
      ${storyObj.text ? `<div style="margin-top:10px;">${storyObj.text.replace(/\n/g, '<p>')}</div>` : ''}
    </div>`;

    if (user) {
      html += `<form method="POST" action="/comment">
        <input type="hidden" name="story_id" value="${storyObj.id}">
        <textarea name="text" rows="6" cols="60"></textarea><br>
        <input type="submit" value="add comment">
      </form><br>`;
    }

    const comments = db.query(
      `SELECT c.*, u.username
       FROM comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.story_id = ? AND c.parent_id IS NULL
       ORDER BY c.created_at ASC`,
      [storyObj.id]
    );

    for (const comment of comments) {
      const commentObj = {
        id: comment[0],
        story_id: comment[1],
        parent_id: comment[2],
        user_id: comment[3],
        text: comment[4],
        points: comment[5],
        created_at: comment[6],
        edited_at: comment[7],
        depth: comment[8],
        username: comment[9]
      };
      html += commentTree(commentObj, user, storyObj.id);
    }

    html += `<script>
      function toggleCollapse(id) {
        const text = document.getElementById('text' + id);
        const children = document.getElementById('children' + id);
        if (text.style.display === 'none') {
          text.style.display = 'block';
          children.style.display = 'block';
        } else {
          text.style.display = 'none';
          children.style.display = 'none';
        }
      }
    </script>`;

    return new Response(layout(storyObj.title + " | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/submit") {
    if (!user) {
      return new Response("", {
        status: 302,
        headers: { "Location": "/login?goto=submit" }
      });
    }

    if (req.method === "POST") {
      const formData = await req.formData();
      const title = formData.get("title") as string;
      const url = formData.get("url") as string;
      const text = formData.get("text") as string;

      if (!title) {
        return new Response(layout("Submit | Hacker News", "<p>Title required</p>", user), {
          headers: { "Content-Type": "text/html" }
        });
      }

      let type = "url";
      if (title.toLowerCase().startsWith("ask hn:")) type = "ask";
      else if (title.toLowerCase().startsWith("show hn:")) type = "show";
      else if (!url) type = "text";

      const result = db.query(
        "INSERT INTO stories (user_id, title, url, text, points, created_at, type) VALUES (?, ?, ?, ?, 1, ?, ?) RETURNING id",
        [user.id, title, url || "", text || "", Date.now(), type]
      );

      const storyId = result[0][0];
      db.query("INSERT INTO votes_stories (user_id, story_id, created_at) VALUES (?, ?, ?)", [user.id, storyId, Date.now()]);

      return new Response("", {
        status: 302,
        headers: { "Location": `/item?id=${storyId}` }
      });
    }

    const html = `<form method="POST">
      <table>
        <tr><td>title</td><td><input type="text" name="title" size="50"></td></tr>
        <tr><td>url</td><td><input type="text" name="url" size="50"></td></tr>
        <tr><td>or</td><td></td></tr>
        <tr><td>text</td><td><textarea name="text" rows="4" cols="50"></textarea></td></tr>
        <tr><td></td><td><input type="submit" value="submit"></td></tr>
      </table>
      <div style="margin-top:10px; color:#828282; font-size:9pt;">
        Leave url blank to submit a question for discussion. If there is no url, text will appear at the top of the thread.
        <br>You can also submit <b>Show HN</b> or <b>Ask HN</b> by starting your title with those words.
      </div>
    </form>`;

    return new Response(layout("Submit | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/comment") {
    if (!user || req.method !== "POST") {
      return new Response("", { status: 302, headers: { "Location": "/" } });
    }

    const formData = await req.formData();
    const storyId = parseInt(formData.get("story_id") as string);
    const parentId = formData.get("parent_id") ? parseInt(formData.get("parent_id") as string) : null;
    const text = formData.get("text") as string;

    if (!text) {
      return new Response("", { status: 302, headers: { "Location": `/item?id=${storyId}` } });
    }

    let depth = 0;
    if (parentId) {
      const parent = db.query("SELECT depth FROM comments WHERE id = ?", [parentId])[0];
      if (parent) depth = parent[0] + 1;
    }

    const result = db.query(
      `INSERT INTO comments (story_id, parent_id, user_id, text, points, created_at, depth)
       VALUES (?, ?, ?, ?, 1, ?, ?) RETURNING id`,
      [storyId, parentId, user.id, text, Date.now(), depth]
    );

    const commentId = result[0][0];
    db.query("INSERT INTO votes_comments (user_id, comment_id, created_at) VALUES (?, ?, ?)", [user.id, commentId, Date.now()]);

    db.query("UPDATE users SET karma = karma + 1 WHERE id = ?", [user.id]);

    return new Response("", {
      status: 302,
      headers: { "Location": `/item?id=${storyId}` }
    });
  }

  if (path === "/reply") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = url.searchParams.get("id");
    const gotoParam = url.searchParams.get("goto") || "";

    if (req.method === "POST") {
      const formData = await req.formData();
      const parentId = parseInt(formData.get("parent_id") as string);
      const storyId = parseInt(formData.get("story_id") as string);
      const text = formData.get("text") as string;

      if (!text) {
        return new Response("", { status: 302, headers: { "Location": `/${gotoParam}` } });
      }

      const parent = db.query("SELECT depth FROM comments WHERE id = ?", [parentId])[0];
      const depth = parent ? parent[0] + 1 : 0;

      const result = db.query(
        `INSERT INTO comments (story_id, parent_id, user_id, text, points, created_at, depth)
         VALUES (?, ?, ?, ?, 1, ?, ?) RETURNING id`,
        [storyId, parentId, user.id, text, Date.now(), depth]
      );

      const commentId = result[0][0];
      db.query("INSERT INTO votes_comments (user_id, comment_id, created_at) VALUES (?, ?, ?)", [user.id, commentId, Date.now()]);
      db.query("UPDATE users SET karma = karma + 1 WHERE id = ?", [user.id]);

      return new Response("", {
        status: 302,
        headers: { "Location": `/${gotoParam}` }
      });
    }

    const comment = db.query(
      `SELECT c.*, u.username, s.id as story_id
       FROM comments c
       JOIN users u ON c.user_id = u.id
       JOIN stories s ON c.story_id = s.id
       WHERE c.id = ?`,
      [parseInt(id!)]
    )[0];

    if (!comment) {
      return new Response("Not found", { status: 404 });
    }

    const html = `
      <div style="margin-bottom:20px; color:#828282;">
        ${comment[4].substring(0, 200)}${comment[4].length > 200 ? '...' : ''}
      </div>
      <form method="POST">
        <input type="hidden" name="parent_id" value="${comment[0]}">
        <input type="hidden" name="story_id" value="${comment[10]}">
        <textarea name="text" rows="6" cols="60"></textarea><br>
        <input type="submit" value="reply">
      </form>
    `;

    return new Response(layout("Reply | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/vote") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = parseInt(url.searchParams.get("id")!);
    const type = url.searchParams.get("type");
    const gotoParam = url.searchParams.get("goto") || "";

    if (type === "story") {
      const existing = db.query("SELECT 1 FROM votes_stories WHERE user_id = ? AND story_id = ?", [user.id, id]);
      if (existing.length === 0) {
        db.query("INSERT INTO votes_stories (user_id, story_id, created_at) VALUES (?, ?, ?)", [user.id, id, Date.now()]);
        db.query("UPDATE stories SET points = points + 1 WHERE id = ?", [id]);

        const story = db.query("SELECT user_id FROM stories WHERE id = ?", [id])[0];
        if (story) {
          db.query("UPDATE users SET karma = karma + 1 WHERE id = ?", [story[0]]);
        }
      }
    } else if (type === "comment") {
      const existing = db.query("SELECT 1 FROM votes_comments WHERE user_id = ? AND comment_id = ?", [user.id, id]);
      if (existing.length === 0) {
        db.query("INSERT INTO votes_comments (user_id, comment_id, created_at) VALUES (?, ?, ?)", [user.id, id, Date.now()]);
        db.query("UPDATE comments SET points = points + 1 WHERE id = ?", [id]);

        const comment = db.query("SELECT user_id FROM comments WHERE id = ?", [id])[0];
        if (comment) {
          db.query("UPDATE users SET karma = karma + 1 WHERE id = ?", [comment[0]]);
        }
      }
    }

    return new Response("", {
      status: 302,
      headers: { "Location": `/${gotoParam || ""}` }
    });
  }

  if (path === "/hide") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = parseInt(url.searchParams.get("id")!);
    const gotoParam = url.searchParams.get("goto") || "";

    const existing = db.query("SELECT 1 FROM hidden_stories WHERE user_id = ? AND story_id = ?", [user.id, id]);
    if (existing.length === 0) {
      db.query("INSERT INTO hidden_stories (user_id, story_id) VALUES (?, ?)", [user.id, id]);
    }

    return new Response("", {
      status: 302,
      headers: { "Location": `/${gotoParam}` }
    });
  }

  if (path === "/fav") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = parseInt(url.searchParams.get("id")!);
    const type = url.searchParams.get("type");

    if (type === "story") {
      const existing = db.query("SELECT 1 FROM favorites_stories WHERE user_id = ? AND story_id = ?", [user.id, id]);
      if (existing.length === 0) {
        db.query("INSERT INTO favorites_stories (user_id, story_id, created_at) VALUES (?, ?, ?)", [user.id, id, Date.now()]);
      } else {
        db.query("DELETE FROM favorites_stories WHERE user_id = ? AND story_id = ?", [user.id, id]);
      }
    } else if (type === "comment") {
      const existing = db.query("SELECT 1 FROM favorites_comments WHERE user_id = ? AND comment_id = ?", [user.id, id]);
      if (existing.length === 0) {
        db.query("INSERT INTO favorites_comments (user_id, comment_id, created_at) VALUES (?, ?, ?)", [user.id, id, Date.now()]);
      } else {
        db.query("DELETE FROM favorites_comments WHERE user_id = ? AND comment_id = ?", [user.id, id]);
      }
    }

    return new Response("", {
      status: 302,
      headers: { "Location": document.referrer || "/" }
    });
  }

  if (path === "/user") {
    const username = url.searchParams.get("id");
    if (!username) {
      return new Response("Not found", { status: 404 });
    }

    const targetUser = db.query("SELECT * FROM users WHERE username = ?", [username])[0];
    if (!targetUser) {
      return new Response("Not found", { status: 404 });
    }

    const userObj = {
      id: targetUser[0],
      username: targetUser[1],
      created_at: targetUser[3],
      karma: targetUser[4],
      about: targetUser[5]
    };

    let html = `<table>
      <tr><td>user:</td><td>${userObj.username}</td></tr>
      <tr><td>created:</td><td>${timeAgo(userObj.created_at)}</td></tr>
      <tr><td>karma:</td><td>${userObj.karma}</td></tr>
      ${userObj.about ? `<tr><td>about:</td><td>${userObj.about}</td></tr>` : ''}
    </table><br>`;

    html += `<div>
      <a href="/submitted?id=${userObj.username}">submissions</a> |
      <a href="/threads?id=${userObj.username}">comments</a> |
      <a href="/favorites?id=${userObj.username}">favorites</a>
    </div>`;

    return new Response(layout(`Profile: ${userObj.username} | Hacker News`, html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/submitted") {
    const username = url.searchParams.get("id");
    if (!username) {
      return new Response("Not found", { status: 404 });
    }

    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM stories s
       JOIN users u ON s.user_id = u.id
       WHERE u.username = ?
       ORDER BY s.created_at DESC
       LIMIT 30`,
      [username]
    );

    let html = '<table class="itemlist" cellspacing="0">';
    stories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, i + 1, user, false);
    });
    html += '</table>';

    return new Response(layout(`${username}'s submissions | Hacker News`, html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/threads") {
    const username = url.searchParams.get("id");
    if (!username) {
      return new Response("Not found", { status: 404 });
    }

    const comments = db.query(
      `SELECT c.*, u.username, s.title, s.id as story_id
       FROM comments c
       JOIN users u ON c.user_id = u.id
       JOIN stories s ON c.story_id = s.id
       WHERE u.username = ?
       ORDER BY c.created_at DESC
       LIMIT 30`,
      [username]
    );

    let html = '<table cellspacing="0">';
    for (const comment of comments) {
      const commentObj = {
        id: comment[0],
        text: comment[4],
        created_at: comment[6],
        username: comment[9],
        title: comment[10],
        story_id: comment[11]
      };

      html += `
        <tr><td>
          <div class="comment">
            <div class="comhead">
              <a href="/user?id=${commentObj.username}">${commentObj.username}</a>
              <a href="/item?id=${commentObj.id}">${timeAgo(commentObj.created_at)}</a>
              | <a href="/item?id=${commentObj.story_id}">on: ${commentObj.title}</a>
            </div>
            <div class="commtext">${commentObj.text.replace(/\n/g, '<p>')}</div>
          </div>
        </td></tr>
      `;
    }
    html += '</table>';

    return new Response(layout(`${username}'s comments | Hacker News`, html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/favorites") {
    const username = url.searchParams.get("id");
    if (!username) {
      return new Response("Not found", { status: 404 });
    }

    const targetUser = db.query("SELECT id FROM users WHERE username = ?", [username])[0];
    if (!targetUser) {
      return new Response("Not found", { status: 404 });
    }

    const stories = db.query(
      `SELECT s.*, u.username,
              (SELECT COUNT(*) FROM comments WHERE story_id = s.id) as comment_count
       FROM favorites_stories fs
       JOIN stories s ON fs.story_id = s.id
       JOIN users u ON s.user_id = u.id
       WHERE fs.user_id = ?
       ORDER BY fs.created_at DESC
       LIMIT 30`,
      [targetUser[0]]
    );

    let html = '<h3>Favorite Stories</h3>';
    html += '<table class="itemlist" cellspacing="0">';
    stories.forEach((story, i) => {
      const storyObj = {
        id: story[0],
        user_id: story[1],
        title: story[2],
        url: story[3],
        text: story[4],
        points: story[5],
        created_at: story[6],
        type: story[7],
        username: story[8],
        comment_count: story[9]
      };
      html += storyRow(storyObj, i + 1, user, false);
    });
    html += '</table><br>';

    const comments = db.query(
      `SELECT c.*, u.username, s.title, s.id as story_id
       FROM favorites_comments fc
       JOIN comments c ON fc.comment_id = c.id
       JOIN users u ON c.user_id = u.id
       JOIN stories s ON c.story_id = s.id
       WHERE fc.user_id = ?
       ORDER BY fc.created_at DESC
       LIMIT 30`,
      [targetUser[0]]
    );

    html += '<h3>Favorite Comments</h3>';
    html += '<table cellspacing="0">';
    for (const comment of comments) {
      const commentObj = {
        id: comment[0],
        text: comment[4],
        created_at: comment[6],
        username: comment[9],
        title: comment[10],
        story_id: comment[11]
      };

      html += `
        <tr><td>
          <div class="comment">
            <div class="comhead">
              <a href="/user?id=${commentObj.username}">${commentObj.username}</a>
              <a href="/item?id=${commentObj.id}">${timeAgo(commentObj.created_at)}</a>
              | <a href="/item?id=${commentObj.story_id}">on: ${commentObj.title}</a>
            </div>
            <div class="commtext">${commentObj.text.replace(/\n/g, '<p>')}</div>
          </div>
        </td></tr>
      `;
    }
    html += '</table>';

    return new Response(layout(`${username}'s favorites | Hacker News`, html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/login") {
    if (req.method === "POST") {
      const formData = await req.formData();
      const username = formData.get("username") as string;
      const password = formData.get("password") as string;

      const passwordHash = await hashPassword(password);
      const userResult = db.query("SELECT * FROM users WHERE username = ? AND password_hash = ?", [username, passwordHash])[0];

      if (!userResult) {
        return new Response(layout("Login | Hacker News", "<p>Bad login</p>" + loginForm(), null), {
          headers: { "Content-Type": "text/html" }
        });
      }

      const sessionId = createSession(userResult[0]);

      return new Response("", {
        status: 302,
        headers: {
          "Location": "/",
          "Set-Cookie": setCookie("session", sessionId)
        }
      });
    }

    return new Response(layout("Login | Hacker News", loginForm(), null), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/logout") {
    const cookie = req.headers.get("cookie");
    if (cookie) {
      const sessionMatch = cookie.match(/session=([^;]+)/);
      if (sessionMatch) {
        db.query("DELETE FROM sessions WHERE id = ?", [sessionMatch[1]]);
      }
    }

    return new Response("", {
      status: 302,
      headers: {
        "Location": "/",
        "Set-Cookie": "session=; Path=/; Max-Age=0"
      }
    });
  }

  if (path === "/register") {
    if (req.method === "POST") {
      const formData = await req.formData();
      const username = formData.get("username") as string;
      const password = formData.get("password") as string;

      if (!username || !password) {
        return new Response(layout("Create Account | Hacker News", "<p>Username and password required</p>" + registerForm(), null), {
          headers: { "Content-Type": "text/html" }
        });
      }

      const existing = db.query("SELECT 1 FROM users WHERE username = ?", [username]);
      if (existing.length > 0) {
        return new Response(layout("Create Account | Hacker News", "<p>Username already exists</p>" + registerForm(), null), {
          headers: { "Content-Type": "text/html" }
        });
      }

      const passwordHash = await hashPassword(password);
      const result = db.query(
        "INSERT INTO users (username, password_hash, created_at, karma) VALUES (?, ?, ?, 1) RETURNING id",
        [username, passwordHash, Date.now()]
      );

      const userId = result[0][0];
      const sessionId = createSession(userId);

      return new Response("", {
        status: 302,
        headers: {
          "Location": "/",
          "Set-Cookie": setCookie("session", sessionId)
        }
      });
    }

    return new Response(layout("Create Account | Hacker News", registerForm(), null), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/edit") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = url.searchParams.get("id");

    if (req.method === "POST") {
      const formData = await req.formData();
      const text = formData.get("text") as string;

      if (!text) {
        return new Response("", { status: 302, headers: { "Location": "/" } });
      }

      const comment = db.query("SELECT * FROM comments WHERE id = ? AND user_id = ?", [parseInt(id!), user.id])[0];
      if (!comment) {
        return new Response("Not authorized", { status: 403 });
      }

      const ageMs = Date.now() - comment[6];
      if (ageMs > 2 * 60 * 60 * 1000) {
        return new Response("Edit window expired", { status: 403 });
      }

      db.query("UPDATE comments SET text = ?, edited_at = ? WHERE id = ?", [text, Date.now(), parseInt(id!)]);

      return new Response("", {
        status: 302,
        headers: { "Location": `/item?id=${comment[1]}` }
      });
    }

    const comment = db.query("SELECT * FROM comments WHERE id = ? AND user_id = ?", [parseInt(id!), user.id])[0];
    if (!comment) {
      return new Response("Not found", { status: 404 });
    }

    const html = `<form method="POST">
      <textarea name="text" rows="6" cols="60">${comment[4]}</textarea><br>
      <input type="submit" value="update">
    </form>`;

    return new Response(layout("Edit Comment | Hacker News", html, user), {
      headers: { "Content-Type": "text/html" }
    });
  }

  if (path === "/delete") {
    if (!user) {
      return new Response("", { status: 302, headers: { "Location": "/login" } });
    }

    const id = parseInt(url.searchParams.get("id")!);
    const type = url.searchParams.get("type");

    if (type === "comment") {
      const comment = db.query("SELECT * FROM comments WHERE id = ? AND user_id = ?", [id, user.id])[0];
      if (!comment) {
        return new Response("Not authorized", { status: 403 });
      }

      db.query("DELETE FROM comments WHERE id = ?", [id]);
      db.query("DELETE FROM votes_comments WHERE comment_id = ?", [id]);
      db.query("DELETE FROM favorites_comments WHERE comment_id = ?", [id]);

      return new Response("", {
        status: 302,
        headers: { "Location": `/item?id=${comment[1]}` }
      });
    }

    return new Response("", { status: 302, headers: { "Location": "/" } });
  }

  if (path === "/context") {
    const id = url.searchParams.get("id");
    if (!id) {
      return new Response("Not found", { status: 404 });
    }

    return new Response("", {
      status: 302,
      headers: { "Location": `/item?id=${id}` }
    });
  }

  return new Response("Not found", { status: 404 });
}

function loginForm(): string {
  return `<form method="POST" action="/login">
    <table>
      <tr><td>username:</td><td><input type="text" name="username" size="20"></td></tr>
      <tr><td>password:</td><td><input type="password" name="password" size="20"></td></tr>
      <tr><td></td><td><input type="submit" value="login"></td></tr>
    </table>
  </form>
  <br>
  <a href="/register">Create Account</a>`;
}

function registerForm(): string {
  return `<form method="POST" action="/register">
    <table>
      <tr><td>username:</td><td><input type="text" name="username" size="20"></td></tr>
      <tr><td>password:</td><td><input type="password" name="password" size="20"></td></tr>
      <tr><td></td><td><input type="submit" value="create account"></td></tr>
    </table>
  </form>`;
}

console.log("Starting Hacker News clone on http://localhost:3000");
await serve(handleRequest, { port: 3000 });
