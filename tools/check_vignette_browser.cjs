// Inspect installed guides with networking disabled, including local assets.
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const {ready, rotate} = require('./browser_pixels.cjs');
const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const root = process.argv[2];
if (!root) throw new Error('Usage: node tools/check_vignette_browser.cjs INSTALLED_DOC_DIRECTORY');
const out = process.env.IVUE_BROWSER_OUTPUT || 'artifacts/vignette-browser';
fs.mkdirSync(out, {recursive: true});
(async () => {
  const browser = await chromium.launch({headless: true, executablePath: process.env.CHROME_PATH,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']});
  const results = [];
  try {
    for (const width of [1280, 390]) {
      for (const name of ['ivue-introduction', 'animation', 'example-data', 'function-guide', 'retinal-development']) {
        const page = await browser.newPage({viewport: {width, height: 900}});
        const errors = [], requests = [];
        page.on('pageerror', e => errors.push(e.message));
        page.on('requestfailed', r => errors.push(`${r.url()}: ${r.failure().errorText}`));
        await page.route(/^https?:/, r => { requests.push(r.request().url()); return r.abort(); });
        await page.goto(pathToFileURL(path.resolve(root, name + '.html')).href);
        const canvases = page.locator('canvas');
        const count = await canvases.count();
        if (name !== 'retinal-development' && count === 0) throw new Error(`${name}: no WebGL canvases`);
        for (let i = 0; i < count; i++) {
          await canvases.nth(i).scrollIntoViewIfNeeded();
          await ready(canvases.nth(i));
        }
        if (count) await rotate(page, canvases.first());
        const overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth);
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({path: path.join(out, `${name}-${width}.png`)});
        if (name === 'ivue-introduction' && width === 1280) {
          await page.locator('#comparing-scientific-views').scrollIntoViewIfNeeded();
          await page.screenshot({path: path.join(out, 'scientific-comparison.png')});
        }
        results.push({name, width, canvases: count, overflow, errors, externalRequests: requests});
        await page.close();
        if (overflow || errors.length || requests.length) throw new Error(JSON.stringify(results[results.length - 1]));
      }
    }
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(out, 'results.json'), JSON.stringify(results, null, 2));
  }
  console.log('PASS: five offline guides at desktop/mobile widths; widgets render and rotate, no page errors, missing assets or overflow.');
})().catch(e => {console.error(e); process.exitCode = 1;});
