// Exercise the retained-frame timeline and real playback in exported widgets.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

async function pixels(canvas) {
  return canvas.evaluate(node => {
    const gl = node.getContext('webgl') || node.getContext('experimental-webgl') ||
      node.getContext('webgl2');
    if (!gl) throw new Error('No WebGL context');
    const data = new Uint8Array(node.width * node.height * 4);
    gl.readPixels(0, 0, node.width, node.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
    let colored = 0, hash = 2166136261;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] && Math.min(data[i], data[i + 1], data[i + 2]) < 230) colored++;
      for (let j = 0; j < 4; j++) hash = Math.imul(hash ^ data[i + j], 16777619);
    }
    return { colored, hash };
  });
}

(async () => {
  const browser = await chromium.launch({ headless: true,
    executablePath: process.env.CHROME_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  try {
    for (const width of [1280, 390]) {
      const page = await browser.newPage({ viewport: { width, height: 900 } });
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
      await page.route(/^https?:/, route => route.abort());
      await page.goto(pathToFileURL(path.resolve('artifacts/animation.html')).href);
      await page.waitForFunction(() => document.querySelectorAll('input[type=range]').length === 2);
      for (let i = 0; i < 2; i++) {
        const slider = page.locator('input[type=range]').nth(i);
        const canvas = page.locator('canvas').nth(i);
        let before;
        for (let attempt = 0; attempt < 30; attempt++) {
          before = await pixels(canvas);
          if (before.colored > 100) break;
          await page.waitForTimeout(100);
        }
        await slider.evaluate(s => {
          s.value = s.max;
          s.dispatchEvent(new Event('input', { bubbles: true }));
          s.dispatchEvent(new Event('change', { bubbles: true }));
        });
        await page.waitForTimeout(150);
        const last = await pixels(canvas);
        await page.locator('input[value=Reset]').nth(i).click();
        await page.locator('input[value=Play]').nth(i).click();
        await page.waitForFunction(index =>
          Number(document.querySelectorAll('input[type=range]')[index].value) > 0, i);
        // Only the running player's button is labelled Pause.
        await page.locator('input[value=Pause]').click();
        const pausedFrame = await slider.inputValue();
        const paused = await pixels(canvas);
        await page.waitForTimeout(650);
        const stopped = await pixels(canvas);
        const stayedPaused = await slider.inputValue() === pausedFrame;
        const result = { width, player: i, before, last, paused, stopped, stayedPaused };
        results.push(result);
        if (before.colored <= 100 || last.colored <= 100 || before.hash === last.hash ||
            paused.hash === before.hash || paused.hash !== stopped.hash || !stayedPaused) {
          throw new Error(`Animation interaction failed: ${JSON.stringify(result)}`);
        }
      }
      await page.screenshot({ path: `artifacts/animation-${width}.png`, fullPage: true });
      if (errors.length) throw new Error(errors.join('\n'));
      await page.close();
    }
  } finally {
    await browser.close();
    fs.writeFileSync('artifacts/animation-browser-results.json', JSON.stringify(results, null, 2));
  }
  console.log('Verified 2D/3D animation sliders, Play and Pause at desktop/mobile sizes.');
})().catch(error => { console.error(error); process.exitCode = 1; });
