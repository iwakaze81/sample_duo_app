#!/usr/bin/env node
// Pages の /vrt/index.html (レポート一覧) を作る。
// /vrt/<main|pr-N>/reg.json (reg-cli の結果) を集めて一覧にする。
//
//   node site_index.mjs <vrt-root-dir> <repo> <site-root-url>
import fs from 'node:fs';
import path from 'node:path';

const [root, repo = '', siteRoot = '../'] = process.argv.slice(2);

const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);

const reports = fs.existsSync(root)
  ? fs.readdirSync(root)
      .filter((d) => /^(main|pr-\d+)$/.test(d) && fs.existsSync(path.join(root, d, 'reg.json')))
      .map((d) => {
        const file = path.join(root, d, 'reg.json');
        const r = JSON.parse(fs.readFileSync(file, 'utf8'));
        const count = (k) => (Array.isArray(r[k]) ? r[k].length : 0);
        return {
          dir: d,
          title: d === 'main' ? 'main のスナップショット' : `PR #${d.slice(3)}`,
          isMain: d === 'main',
          changed: count('failedItems'),
          added: count('newItems'),
          removed: count('deletedItems'),
          total: count('actualItems'),
          updatedAt: fs.statSync(file).mtime.toISOString().replace('T', ' ').replace(/\.\d+Z$/, ' UTC'),
          sortKey: d === 'main' ? Infinity : Number(d.slice(3)),
        };
      })
      .sort((a, b) => b.sortKey - a.sortKey)
  : [];

const badge = (tone, text) => `<span class="badge ${tone}">${esc(text)}</span>`;
const rows = reports.map((r) => {
  const badges = r.isMain
    ? badge('info', `${r.total} 画面`)
    : r.changed + r.added + r.removed === 0
      ? badge('ok', '差分なし')
      : [
          r.changed && badge('warn', `変更 ${r.changed}`),
          r.added && badge('info', `追加 ${r.added}`),
          r.removed && badge('danger', `削除 ${r.removed}`),
        ].filter(Boolean).join(' ');
  const pr = r.isMain ? '' : ` · <a href="https://github.com/${esc(repo)}/pull/${r.dir.slice(3)}">GitHub</a>`;
  return `<li><a class="title" href="${esc(r.dir)}/">${esc(r.title)}</a><span class="badges">${badges}</span><span class="meta">${esc(r.updatedAt)}${pr}</span></li>`;
}).join('\n');

const html = `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>VRT Reports</title>
<style>
:root { --bg:#f7f7fb; --surface:#fff; --fg:#1b1b23; --muted:#62627a; --border:#e1e1ea; --accent:#5b5bd6;
  --ok:#2f8f6b; --ok-bg:#e3f4ec; --warn:#a86a00; --warn-bg:#fdf0d8; --info:#3d5bd9; --info-bg:#e5eafd;
  --danger:#c23b3b; --danger-bg:#fbe5e5; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --bg:#121218; --surface:#1b1b23; --fg:#ececf3; --muted:#a0a0b4; --border:#2e2e3a; --accent:#9d9dff;
  --ok:#6fd3a8; --ok-bg:#173328; --warn:#f3c36b; --warn-bg:#3a2c12; --info:#9fb2ff; --info-bg:#1d2547;
  --danger:#ff8f8f; --danger-bg:#3d1a1a; } }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--fg);
  font:14px/1.6 -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Noto Sans JP", sans-serif; }
a { color: var(--accent); }
header, main { max-width: 960px; margin: 0 auto; padding: 0 16px; }
header { padding-top: 24px; }
h1 { font-size: 22px; margin: 4px 0; }
.meta { color: var(--muted); font-size: 12px; }
ul { list-style: none; padding: 0; margin: 16px 0 48px; }
li { display:flex; flex-wrap:wrap; align-items:center; gap:8px 12px; background:var(--surface);
  border:1px solid var(--border); border-radius:12px; padding:12px 16px; margin-bottom:10px; }
.title { font-weight: 600; text-decoration: none; }
.badges { display:inline-flex; gap:6px; flex-wrap:wrap; }
li .meta { margin-left: auto; }
.badge { padding:1px 8px; border-radius:999px; font-size:12px; font-weight:600; }
.badge.ok { color:var(--ok); background:var(--ok-bg); } .badge.warn { color:var(--warn); background:var(--warn-bg); }
.badge.info { color:var(--info); background:var(--info-bg); } .badge.danger { color:var(--danger); background:var(--danger-bg); }
</style>
</head>
<body>
<header>
  <div class="meta"><a href="${esc(siteRoot)}">← アプリ (Web 版)</a></div>
  <h1>VRT レポート</h1>
  <div class="meta">${esc(repo)} · reg-cli のレポート (main のスナップショットと、開いている PR ごとの差分)</div>
</header>
<main>
<ul>
${rows || '<li>レポートはまだありません。</li>'}
</ul>
</main>
</body>
</html>
`;

fs.mkdirSync(root, { recursive: true });
fs.writeFileSync(path.join(root, 'index.html'), html);
console.log(`[vrt] index: ${reports.map((r) => r.dir).join(', ') || '(none)'}`);
