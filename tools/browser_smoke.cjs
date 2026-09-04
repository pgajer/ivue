const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

async function pixels(page) {
  return page.locator('canvas').first().evaluate(canvas => {
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl') || canvas.getContext('webgl2');
    if (!gl) return { colored: 0, width: canvas.width, height: canvas.height };
    const data = new Uint8Array(canvas.width * canvas.height * 4);
    gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
    let colored = 0, hash = 2166136261;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] && Math.min(data[i], data[i + 1], data[i + 2]) < 230) colored++;
      hash = Math.imul(hash ^ data[i], 16777619);
      hash = Math.imul(hash ^ data[i + 1], 16777619);
      hash = Math.imul(hash ^ data[i + 2], 16777619);
    }
    return { colored, hash, width: canvas.width, height: canvas.height };
  });
}

(async () => {
  const browser = await chromium.launch({ headless: true,
    executablePath: process.env.CHROME_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  try {
    for (const viewport of [{ width: 1280, height: 900 }, { width: 390, height: 844 }]) {
      for (const name of ['saddle', 'plain', 'groups', 'graph', 'saddle-selfcontained', 'multiple', 'axes', 'axes.front', 'mesh']) {
        const file = path.resolve('artifacts', name + '.html');
        if (!fs.existsSync(file)) throw new Error(`Missing browser fixture: ${file}`);
        const page = await browser.newPage({ viewport });
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
        await page.goto(pathToFileURL(file).href);
        await page.locator('canvas').first().waitFor();
        await page.waitForFunction(() => {
          const canvas = document.querySelector('canvas');
          return canvas && canvas.width > 0 && canvas.height > 0;
        });
        let before;
        for (let i = 0; i < 30; i++) {
          before = await pixels(page);
          if (before.colored > 100) break;
          await page.waitForTimeout(100);
        }
        if (name.startsWith('axes') || name === 'mesh') {
          await page.screenshot({ path: `artifacts/${name}-initial-${viewport.width}.png`, fullPage: true });
        }
        const box = await page.locator('canvas').first().boundingBox();
        await page.mouse.move(box.x + box.width * 0.7, box.y + box.height * 0.7);
        await page.mouse.down();
        await page.mouse.move(box.x + box.width * 0.9, box.y + box.height * 0.5, { steps: 12 });
        await page.mouse.up();
        await page.waitForTimeout(250);
        const rotated = await pixels(page);
        await page.mouse.wheel(0, -120);
        await page.waitForTimeout(250);
        const zoomed = await pixels(page);
        await page.setViewportSize({ width: viewport.width === 390 ? 1024 : 420, height: viewport.height });
        await page.waitForTimeout(200);
        const resized = await pixels(page);
        await page.setViewportSize(viewport);
        await page.waitForTimeout(200);
        const legendsScoped = await page.locator('.ivue-legend').evaluateAll(legends =>
          legends.every(legend => legend.parentElement.classList.contains('rglWebGL')));
        const legendCount = await page.locator('.ivue-legend').count();
        const legendsPresent = legendCount === (name === 'plain' ? 0 : name === 'multiple' ? 2 : 1);
        const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
        await page.screenshot({ path: `artifacts/${name}-${viewport.width}.png`, fullPage: true });
        const result = { name, viewport, before, rotated, zoomed, resized, legendsScoped, legendsPresent, overflow, errors };
        results.push(result);
        console.log(JSON.stringify(result));
        await page.close();
      }
    }
  } finally {
    await browser.close();
    fs.writeFileSync('artifacts/browser-results.json', JSON.stringify(results, null, 2));
  }
  if (results.some(r => r.before.colored <= 100 || r.rotated.hash === r.before.hash ||
      r.zoomed.hash === r.rotated.hash || r.resized.colored <= 100 ||
      !r.legendsScoped || !r.legendsPresent || r.errors.length || r.overflow)) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
