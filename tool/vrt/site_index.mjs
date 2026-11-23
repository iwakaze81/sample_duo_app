#!/usr/bin/env node
// site/vrt/<dir>/results.json を集めて site/vrt/index.html を作る。
//   node site_index.mjs <vrt-root-dir> <repo> <site-root-url>
import fs from 'node:fs';
import path from 'node:path';
import { renderIndex } from './report_html.mjs';

const [root, repo = '', siteRoot = '../'] = process.argv.slice(2);
const reports = fs.existsSync(root)
  ? fs.readdirSync(root)
      .filter((d) => /^(main|pr-\d+)$/.test(d) && fs.existsSync(path.join(root, d, 'results.json')))
      .map((d) => {
        const r = JSON.parse(fs.readFileSync(path.join(root, d, 'results.json'), 'utf8'));
        return {
          dir: d,
          title: r.title,
          mode: r.mode,
          summary: r.summary,
          items: r.items.length,
          generatedAt: r.generatedAt,
          sortKey: d === 'main' ? Infinity : Number(d.slice(3)),
        };
      })
      .sort((a, b) => b.sortKey - a.sortKey)
  : [];
fs.mkdirSync(root, { recursive: true });
fs.writeFileSync(path.join(root, 'index.html'), renderIndex(reports, { repo, siteRoot }));
console.log(`[vrt] index: ${reports.map((r) => r.dir).join(', ') || '(none)'}`);
