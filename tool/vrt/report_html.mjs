// レポート HTML の生成 (compare.mjs と site_index.mjs から使う)。
// 画像名などはすべてエスケープする (PR 由来のファイル名を埋め込むため)。

export const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c]);

export const STATUS = {
  changed: { label: '変更', tone: 'warn' },
  added: { label: '追加', tone: 'info' },
  removed: { label: '削除', tone: 'danger' },
  unchanged: { label: '変更なし', tone: 'ok' },
};

const BASE_CSS = `
:root {
  --bg: #f7f7fb; --surface: #ffffff; --surface-2: #f0f0f6; --fg: #1b1b23; --muted: #62627a;
  --border: #e1e1ea; --accent: #5b5bd6;
  --ok: #2f8f6b; --ok-bg: #e3f4ec; --warn: #a86a00; --warn-bg: #fdf0d8;
  --info: #3d5bd9; --info-bg: #e5eafd; --danger: #c23b3b; --danger-bg: #fbe5e5;
  --checker: #e9e9f0;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #121218; --surface: #1b1b23; --surface-2: #23232d; --fg: #ececf3; --muted: #a0a0b4;
    --border: #2e2e3a; --accent: #9d9dff;
    --ok: #6fd3a8; --ok-bg: #173328; --warn: #f3c36b; --warn-bg: #3a2c12;
    --info: #9fb2ff; --info-bg: #1d2547; --danger: #ff8f8f; --danger-bg: #3d1a1a;
    --checker: #2a2a34;
  }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg);
  font: 14px/1.6 -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Noto Sans JP", sans-serif; }
a { color: var(--accent); }
header { padding: 24px 16px 8px; max-width: 1280px; margin: 0 auto; }
h1 { font-size: 22px; margin: 0 0 4px; }
.meta { color: var(--muted); font-size: 12px; }
main { max-width: 1280px; margin: 0 auto; padding: 8px 16px 48px; }
.badge { display: inline-block; padding: 1px 8px; border-radius: 999px; font-size: 12px; font-weight: 600; }
.badge.ok { color: var(--ok); background: var(--ok-bg); }
.badge.warn { color: var(--warn); background: var(--warn-bg); }
.badge.info { color: var(--info); background: var(--info-bg); }
.badge.danger { color: var(--danger); background: var(--danger-bg); }
`;

export function renderReport(results) {
  const { title, subtitle, generatedAt, summary, items, mode } = results;
  const tabs = mode === 'gallery'
    ? []
    : ['changed', 'added', 'removed', 'unchanged'].filter((s) => summary[s] > 0);
  const firstTab = tabs[0] ?? 'all';

  const pane = (label, src) => src
    ? `<figure><figcaption>${esc(label)}</figcaption><a href="${esc(src)}" target="_blank" rel="noopener"><img loading="lazy" src="${esc(src)}" alt="${esc(label)}"></a></figure>`
    : `<figure class="empty"><figcaption>${esc(label)}</figcaption><div>なし</div></figure>`;

  const cards = items.map((it) => {
    const st = STATUS[it.status];
    const exp = it.status !== 'added' ? `images/expected/${it.name}` : null;
    const act = it.status !== 'removed' ? `images/actual/${it.name}` : null;
    const diff = it.diff ? `images/diff/${it.name}` : null;
    const ratio = it.status === 'changed' && it.diffRatio != null
      ? `<span class="ratio">${(it.diffRatio * 100).toFixed(2)}% (${it.diffPixels.toLocaleString()} px)</span>`
      : '';
    const note = it.sizeMismatch ? '<span class="ratio">画像サイズが異なります</span>' : '';
    const panes = mode === 'gallery'
      ? pane('スクリーンショット', act)
      : pane('期待 (main)', exp) + pane('実際 (この変更)', act) + (it.status === 'changed' ? pane('差分', diff) : '');
    return `<section class="card" data-status="${esc(it.status)}" id="${esc(it.name)}">
  <h2><a href="#${esc(it.name)}">${esc(it.name.replace(/\.png$/, ''))}</a>
    ${mode === 'gallery' ? '' : `<span class="badge ${st.tone}">${st.label}</span>`} ${ratio}${note}</h2>
  <div class="panes ${mode === 'gallery' ? 'single' : ''}">${panes}</div>
</section>`;
  }).join('\n');

  const chips = mode === 'gallery' ? '' : `<nav class="tabs" role="tablist">
  ${tabs.map((s) => `<button role="tab" data-tab="${s}">${STATUS[s].label} <b>${summary[s]}</b></button>`).join('')}
  <button role="tab" data-tab="all">すべて <b>${items.length}</b></button>
</nav>`;

  const headline = mode === 'gallery'
    ? `${items.length} 画面`
    : summary.changed + summary.added + summary.removed === 0
      ? '<span class="badge ok">差分なし</span>'
      : ['changed', 'added', 'removed'].filter((s) => summary[s])
          .map((s) => `<span class="badge ${STATUS[s].tone}">${STATUS[s].label} ${summary[s]}</span>`).join(' ');

  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<style>${BASE_CSS}
.tabs { display: flex; flex-wrap: wrap; gap: 8px; margin: 8px 0 20px; }
.tabs button { font: inherit; padding: 6px 14px; border-radius: 999px; border: 1px solid var(--border);
  background: var(--surface); color: var(--fg); cursor: pointer; }
.tabs button[aria-selected="true"] { border-color: var(--accent); color: var(--accent); }
.card { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 14px 16px 16px; margin-bottom: 16px; }
.card[hidden] { display: none; }
.card h2 { font-size: 15px; margin: 0 0 12px; display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
.card h2 a { color: inherit; text-decoration: none; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
.ratio { color: var(--muted); font-size: 12px; font-weight: 400; }
.panes { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; }
.panes.single { grid-template-columns: minmax(0, 520px); }
figure { margin: 0; min-width: 0; }
figcaption { font-size: 12px; color: var(--muted); margin-bottom: 6px; }
figure img { display: block; width: 100%; height: auto; border-radius: 8px; border: 1px solid var(--border);
  background: repeating-conic-gradient(var(--checker) 0 25%, transparent 0 50%) 0 0 / 16px 16px; }
figure.empty div { display: grid; place-items: center; min-height: 120px; border: 1px dashed var(--border);
  border-radius: 8px; color: var(--muted); }
.back { font-size: 12px; }
</style>
</head>
<body>
<header>
  <div class="back"><a href="../">← レポート一覧</a></div>
  <h1>${esc(title)}</h1>
  ${subtitle ? `<div>${subtitle}</div>` : ''}
  <div class="meta">${esc(generatedAt)} 生成 · ${headline}</div>
</header>
<main>
${chips}
${cards || '<p>スクリーンショットがありません。</p>'}
</main>
<script>
(() => {
  const buttons = [...document.querySelectorAll('.tabs button')];
  if (!buttons.length) return;
  const show = (tab) => {
    for (const b of buttons) b.setAttribute('aria-selected', String(b.dataset.tab === tab));
    for (const c of document.querySelectorAll('.card'))
      c.hidden = tab !== 'all' && c.dataset.status !== tab;
  };
  for (const b of buttons) b.addEventListener('click', () => show(b.dataset.tab));
  const hash = decodeURIComponent(location.hash.slice(1));
  show(hash && document.getElementById(hash) ? 'all' : ${JSON.stringify(firstTab)});
})();
</script>
</body>
</html>
`;
}

export function renderIndex(reports, { repo, siteRoot }) {
  const rows = reports.map((r) => {
    const s = r.summary;
    const badges = r.mode === 'gallery'
      ? `<span class="badge info">${r.items} 画面</span>`
      : s.changed + s.added + s.removed === 0
        ? '<span class="badge ok">差分なし</span>'
        : ['changed', 'added', 'removed'].filter((k) => s[k])
            .map((k) => `<span class="badge ${STATUS[k].tone}">${STATUS[k].label} ${s[k]}</span>`).join(' ');
    return `<li><a href="${esc(r.dir)}/">${esc(r.title)}</a><span class="badges">${badges}</span><span class="meta">${esc(r.generatedAt)}</span></li>`;
  }).join('\n');

  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>VRT Reports</title>
<style>${BASE_CSS}
ul { list-style: none; padding: 0; margin: 16px 0; }
li { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; background: var(--surface);
  border: 1px solid var(--border); border-radius: 12px; padding: 12px 16px; margin-bottom: 10px; }
li > a { font-weight: 600; text-decoration: none; }
.badges { display: inline-flex; gap: 6px; flex-wrap: wrap; }
li .meta { margin-left: auto; }
</style>
</head>
<body>
<header>
  <div class="back"><a href="${esc(siteRoot)}">← アプリ (Web 版)</a></div>
  <h1>VRT レポート</h1>
  <div class="meta">${esc(repo)} · main のスナップショットと、開いている PR ごとの差分</div>
</header>
<main>
<ul>
${rows || '<li>レポートはまだありません。</li>'}
</ul>
</main>
</body>
</html>
`;
}
