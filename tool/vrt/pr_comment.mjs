#!/usr/bin/env node
// VRT の結果 (results.json) から PR コメント用の Markdown を作る。
//
//   node pr_comment.mjs --results <results.json> --report-url <Pages のレポート URL>
//                       --sha <head sha> --out <comment.md> [--github-output <file>]
//
// 画像は Pages に公開済みのものを <img> で埋め込む。
// --github-output を渡すと has_changes=true|false を書き出す。
import fs from 'node:fs';
import { parseArgs } from 'node:util';
import { esc, STATUS } from './report_html.mjs';

export const MARKER = '<!-- vrt-report -->';

const { values: args } = parseArgs({
  options: {
    results: { type: 'string' },
    'report-url': { type: 'string' },
    sha: { type: 'string', default: '' },
    out: { type: 'string' },
    'github-output': { type: 'string' },
    'max-images': { type: 'string', default: '8' },
  },
});
if (!args.results || !args['report-url'] || !args.out) {
  console.error('usage: pr_comment.mjs --results <file> --report-url <url> --out <file>');
  process.exit(2);
}

const results = JSON.parse(fs.readFileSync(args.results, 'utf8'));
const { summary, items } = results;
const reportUrl = args['report-url'].replace(/\/?$/, '/');
const sha = args.sha.slice(0, 7);
// GitHub の画像プロキシ (camo) のキャッシュを避けるため、コミットごとにクエリを変える
const img = (kind, name) => `${reportUrl}images/${kind}/${encodeURIComponent(name)}?v=${sha}`;
const changed = items.filter((i) => i.status !== 'unchanged');
const hasChanges = changed.length > 0;
const maxImages = Number(args['max-images']);

const counts = ['changed', 'added', 'removed', 'unchanged']
  .map((s) => `${STATUS[s].label} **${summary[s]}**`)
  .join(' · ');

const lines = [MARKER];

if (!hasChanges) {
  lines.push(
    '## 🖼️ VRT: ✅ 見た目の差分はありません',
    '',
    `\`${sha}\` · ${items.length} 画面を main と比較しました。`,
    '',
    `[📄 レポートを開く](${reportUrl})`,
  );
} else {
  lines.push(
    `## 🖼️ VRT: ⚠️ 見た目の差分が ${changed.length} 画面あります`,
    '',
    `\`${sha}\` · ${counts}`,
    '',
    `### [📄 差分レポートを開く (HTML)](${reportUrl})`,
    '期待 (main)・実際 (この PR)・差分を並べて、拡大して確認できます。意図した変更か確認してください。',
    '',
    '| 画面 | 状態 | 差分 |',
    '| --- | --- | --- |',
  );
  for (const it of changed) {
    const ratio = it.diffRatio != null ? `${(it.diffRatio * 100).toFixed(2)}%`
      : it.sizeMismatch ? '画像サイズが変化' : '—';
    const icon = { changed: '🟡', added: '🔵', removed: '🔴' }[it.status];
    const label = it.name.replace(/\.png$/, '');
    lines.push(`| [\`${label}\`](${reportUrl}#${encodeURIComponent(it.name)}) | ${icon} ${STATUS[it.status].label} | ${ratio} |`);
  }

  lines.push('');
  const cell = (kind, name, alt) =>
    `<td><a href="${esc(img(kind, name))}"><img src="${esc(img(kind, name))}" width="240" alt="${esc(alt)}"></a></td>`;

  for (const it of changed.slice(0, maxImages)) {
    const label = esc(it.name.replace(/\.png$/, ''));
    let header;
    let row;
    if (it.status === 'changed') {
      header = '<th>期待 (main)</th><th>実際 (この PR)</th><th>差分</th>';
      row = cell('expected', it.name, 'expected') + cell('actual', it.name, 'actual')
        + (it.diff ? cell('diff', it.name, 'diff') : '<td>サイズが異なるため差分画像なし</td>');
    } else if (it.status === 'added') {
      header = '<th>追加された画面</th>';
      row = cell('actual', it.name, 'actual');
    } else {
      header = '<th>削除された画面 (main)</th>';
      row = cell('expected', it.name, 'expected');
    }
    lines.push(
      `<details open><summary><b>${label}</b> — ${STATUS[it.status].label}</summary>`,
      '',
      `<table><tr>${header}</tr><tr>${row}</tr></table>`,
      '',
      '</details>',
    );
  }
  if (changed.length > maxImages) {
    lines.push('', `ほか ${changed.length - maxImages} 画面は [レポート](${reportUrl}) で確認してください。`);
  }
  lines.push('', '<sub>差分があってもマージはブロックしません。このコメントは push のたびに更新されます。</sub>');
}

fs.writeFileSync(args.out, lines.join('\n') + '\n');
if (args['github-output']) {
  fs.appendFileSync(args['github-output'], `has_changes=${hasChanges}\n`);
}
console.log(`[vrt] comment: has_changes=${hasChanges}`);
