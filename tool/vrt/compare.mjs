#!/usr/bin/env node
// スクリーンショットを比較して HTML レポートを作る。
//
//   node compare.mjs --actual <dir> [--expected <dir>] --out <dir> --title <text>
//                    [--subtitle-html <html>] [--threshold 0.1] [--summary-md <file>]
//
// --expected を省略すると比較せずにスクリーンショット一覧 (gallery) を作る。
// 差分があっても終了コードは 0 (CI を落とすかどうかはワークフロー側で決める)。
import fs from 'node:fs';
import path from 'node:path';
import { parseArgs } from 'node:util';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { renderReport, STATUS } from './report_html.mjs';

const { values: args } = parseArgs({
  options: {
    actual: { type: 'string' },
    expected: { type: 'string' },
    out: { type: 'string' },
    title: { type: 'string', default: 'VRT レポート' },
    'subtitle-html': { type: 'string' },
    threshold: { type: 'string', default: '0.1' },
    'summary-md': { type: 'string' },
    'report-url': { type: 'string' },
  },
});
if (!args.actual || !args.out) {
  console.error('usage: compare.mjs --actual <dir> [--expected <dir>] --out <dir>');
  process.exit(2);
}

// PR 由来のファイルも扱うので、想定した名前の PNG 以外は無視する
const SAFE_NAME = /^[a-z0-9][a-z0-9_-]{0,80}\.png$/;
const listPngs = (dir) =>
  dir && fs.existsSync(dir)
    ? fs.readdirSync(dir).filter((f) => SAFE_NAME.test(f) && fs.statSync(path.join(dir, f)).isFile())
    : [];

const mode = args.expected ? 'compare' : 'gallery';
const actualNames = new Set(listPngs(args.actual));
const expectedNames = new Set(listPngs(args.expected));
const names = [...new Set([...actualNames, ...expectedNames])].sort();

const out = args.out;
fs.rmSync(out, { recursive: true, force: true });
for (const d of ['expected', 'actual', 'diff']) fs.mkdirSync(path.join(out, 'images', d), { recursive: true });

const readPng = (file) => PNG.sync.read(fs.readFileSync(file));
const threshold = Number(args.threshold);
const items = [];

for (const name of names) {
  const inActual = actualNames.has(name);
  const inExpected = expectedNames.has(name);
  if (inActual) fs.copyFileSync(path.join(args.actual, name), path.join(out, 'images/actual', name));
  if (inExpected) fs.copyFileSync(path.join(args.expected, name), path.join(out, 'images/expected', name));

  if (mode === 'gallery' || !inExpected) {
    items.push({ name, status: 'added' });
    continue;
  }
  if (!inActual) {
    items.push({ name, status: 'removed' });
    continue;
  }

  const a = readPng(path.join(args.expected, name));
  const b = readPng(path.join(args.actual, name));
  if (a.width !== b.width || a.height !== b.height) {
    items.push({ name, status: 'changed', sizeMismatch: true, diffRatio: null, diffPixels: null });
    continue;
  }
  const diff = new PNG({ width: a.width, height: a.height });
  const diffPixels = pixelmatch(a.data, b.data, diff.data, a.width, a.height, {
    threshold,
    alpha: 0.2,
    diffColor: [255, 0, 80],
  });
  if (diffPixels === 0) {
    items.push({ name, status: 'unchanged' });
    continue;
  }
  fs.writeFileSync(path.join(out, 'images/diff', name), PNG.sync.write(diff));
  items.push({
    name,
    status: 'changed',
    diff: true,
    diffPixels,
    diffRatio: diffPixels / (a.width * a.height),
  });
}

// 変更 → 追加 → 削除 → 変更なし の順に並べる
const order = ['changed', 'added', 'removed', 'unchanged'];
items.sort((x, y) => order.indexOf(x.status) - order.indexOf(y.status) || x.name.localeCompare(y.name));

const summary = Object.fromEntries(order.map((s) => [s, items.filter((i) => i.status === s).length]));
const results = {
  mode,
  title: args.title,
  subtitle: args['subtitle-html'] ?? '',
  generatedAt: new Date().toISOString().replace('T', ' ').replace(/\.\d+Z$/, ' UTC'),
  summary,
  items,
};
fs.writeFileSync(path.join(out, 'results.json'), JSON.stringify(results, null, 2));
fs.writeFileSync(path.join(out, 'index.html'), renderReport(results));

const changedCount = summary.changed + summary.added + summary.removed;
console.log(`[vrt] ${mode}: ${items.length} screens, ` +
  order.map((s) => `${s}=${summary[s]}`).join(' '));

if (args['summary-md']) {
  const lines = ['## 🖼️ VRT', ''];
  if (mode === 'gallery') {
    lines.push(`比較対象 (main) が無いため、スクリーンショット ${items.length} 件を記録しました。`);
  } else if (changedCount === 0) {
    lines.push(`✅ 見た目の差分はありません (${items.length} 画面)。`);
  } else {
    lines.push(`⚠️ 見た目に差分があります。意図した変更か確認してください。`, '',
      '| 画面 | 状態 | 差分 |', '| --- | --- | --- |');
    for (const it of items.filter((i) => i.status !== 'unchanged')) {
      const ratio = it.diffRatio != null ? `${(it.diffRatio * 100).toFixed(2)}%`
        : it.sizeMismatch ? 'サイズ変更' : '-';
      lines.push(`| \`${it.name.replace(/\.png$/, '')}\` | ${STATUS[it.status].label} | ${ratio} |`);
    }
  }
  if (args['report-url']) lines.push('', `📄 レポート: ${args['report-url']}`);
  fs.appendFileSync(args['summary-md'], lines.join('\n') + '\n');
}
