const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const { ready, rotate } = require('./browser_pixels.cjs');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  try {
    const files = fs.readdirSync('artifacts/benchmark').filter(x => x.endsWith('.html')).map(x => 'artifacts/benchmark/' + x);
    files.push(...fs.readdirSync('artifacts/downstream-pipeline').filter(x => x.endsWith('.html')).map(x => 'artifacts/downstream-pipeline/' + x));
    files.push('ivue.Rcheck/ivue/doc/ivue-introduction.html');
    if (files.length !== 8) throw new Error(`Expected eight release fixtures, got ${files.length}`);
    for (const width of [1280, 390]) for (const file of files) {
      const page = await browser.newPage({ viewport: { width, height: 900 } });
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('console', e => { if (e.type() === 'error') errors.push(e.text()); });
      const started = Date.now();
      await page.goto(pathToFileURL(path.resolve(file)).href);
      await ready(page.locator('canvas').first());
      const loadMs = Date.now() - started;
      const count = await page.locator('canvas').count();
      if (count !== (file.includes('introduction') ? 4 : 1)) throw new Error(`Unexpected canvas count ${count}: ${file}`);
      const scenes = [];
      for (let i = 0; i < count; i++) scenes.push(await rotate(page, page.locator('canvas').nth(i)));
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
      const result = { file, width, loadMs, scenes, overflow, errors };
      results.push(result);
      await page.screenshot({ path: `artifacts/release-${path.basename(file, '.html')}-${width}.png`, fullPage: true });
      await page.close();
      console.log(JSON.stringify(result));
      if (overflow || errors.length) throw new Error(`Browser errors in ${file}`);
    }
  } finally {
    await browser.close();
    fs.writeFileSync('artifacts/release-browser-results.json', JSON.stringify(results, null, 2));
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
