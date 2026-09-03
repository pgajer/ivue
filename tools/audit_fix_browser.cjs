const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const dir = path.resolve('artifacts/audit-fixes/opacity');
  const browser = await chromium.launch({ headless: true,
    executablePath: process.env.CHROME_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  const failures = [];
  try {
    for (const width of [1280, 390]) {
      const byName = {};
      for (const file of fs.readdirSync(dir).filter(x => x.endsWith('.html')).sort()) {
        const page = await browser.newPage({ viewport: { width, height: 844 } });
        const errors = [];
        page.on('pageerror', e => errors.push(e.message));
        page.on('console', e => { if (e.type() === 'error') errors.push(e.text()); });
        await page.goto(pathToFileURL(path.join(dir, file)).href);
        await page.waitForFunction(() => document.querySelector('.rglWebGL')?.rglinstance?.gl);
        await page.waitForTimeout(300);
        const pixels = await page.locator('canvas').evaluate(c => {
          const gl = c.getContext('webgl') || c.getContext('experimental-webgl') || c.getContext('webgl2');
          const bytes = new Uint8Array(c.width * c.height * 4);
          gl.readPixels(0, 0, c.width, c.height, gl.RGBA, gl.UNSIGNED_BYTE, bytes);
          let red = 0, contrast = 0;
          for (let i = 0; i < bytes.length; i += 4) {
            const excess = bytes[i] - Math.max(bytes[i + 1], bytes[i + 2]);
            if (excess > 50) red++;
            contrast += Math.max(0, excess);
          }
          return { red, contrast, canvasWidth: c.width, canvasHeight: c.height };
        });
        const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
        const name = path.basename(file, '.html');
        const result = { name, width, ...pixels, overflow, errors };
        byName[name] = result;
        results.push(result);
        await page.screenshot({ path: path.join(dir, `${name}-${width}.png`), fullPage: true });
        await page.close();
        if (errors.length || overflow || !pixels.canvasWidth || !pixels.canvasHeight)
          failures.push(`${name}/${width}: rendering or layout failure`);
      }
      for (const family of ['plain', 'sphere', 'continuous', 'groups', 'graph', 'edges', 'path', 'labels']) {
        if (byName[`${family}-0`].red !== 0 || byName[`${family}-1`].red === 0)
          failures.push(`${family}/${width}: transparent/opaque comparison failed`);
      }
      const opaque = byName['plain-1'].contrast;
      for (const [name, expected] of [['half', 0.5], ['highlight', 1 / 3], ['missing', 2 / 3]]) {
        const ratio = byName[name].contrast / opaque;
        if (Math.abs(ratio - expected) > 0.03)
          failures.push(`${name}/${width}: contrast ratio ${ratio}, expected ${expected}`);
      }
    }
  } finally {
    const report = { browser: browser.version(), results, failures };
    fs.writeFileSync(path.join(dir, 'results.json'), JSON.stringify(report, null, 2));
    await browser.close();
  }
  console.log(JSON.stringify({ cases: results.length, failures }, null, 2));
  if (results.length !== 38 || failures.length) process.exitCode = 1;
})().catch(e => { console.error(e); process.exitCode = 1; });
