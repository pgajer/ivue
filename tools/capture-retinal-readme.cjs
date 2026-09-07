// Capture synchronized WebGL frames after render-retinal-readme.R.
// Set PLAYWRIGHT_MODULE or CHROME_PATH when they are outside default paths.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

async function canvasPixels(canvas) {
  return canvas.evaluate(node => {
    const gl = node.getContext('webgl') || node.getContext('experimental-webgl') ||
      node.getContext('webgl2');
    if (!gl) return { colored: 0, width: node.width, height: node.height };
    const data = new Uint8Array(node.width * node.height * 4);
    gl.readPixels(0, 0, node.width, node.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
    let colored = 0;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] && Math.min(data[i], data[i + 1], data[i + 2]) < 235) colored++;
    }
    return { colored, width: node.width, height: node.height };
  });
}

(async () => {
  const out = path.resolve('artifacts', 'retinal-readme');
  const html = path.join(out, 'retinal-development.html');
  if (!fs.existsSync(html)) throw new Error(`Missing rendered page: ${html}`);

  const systemChrome = process.platform === 'darwin' ?
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : null;
  const executablePath = process.env.CHROME_PATH ||
    (systemChrome && fs.existsSync(systemChrome) ? systemChrome : undefined);

  const browser = await chromium.launch({
    headless: true,
    executablePath,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1120, height: 720 } });
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => {
      if (message.type() === 'error') errors.push(message.text());
    });
    await page.route(/^https?:/, route => route.abort());
    await page.goto(pathToFileURL(html).href);
    await page.waitForFunction(() => document.body.dataset.ready === 'true');
    await page.waitForFunction(() => document.querySelectorAll('#hero canvas').length === 2 &&
      [...document.querySelectorAll('#hero canvas')].every(canvas => canvas.width > 0));

    const hero = page.locator('#hero');
    const canvases = page.locator('#hero canvas');
    const frameCount = await page.evaluate(() => window.retinalHero.frameCount);
    const heroBox = await hero.boundingBox();
    if (!heroBox) throw new Error('Retinal hero has no visible bounding box.');

    async function screenshot(outputPath) {
      await page.screenshot({ path: outputPath, clip: heroBox });
    }

    async function frame(index) {
      await page.evaluate(value => window.retinalHero.setFrame(value), index);
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() =>
        requestAnimationFrame(resolve))));
      await page.waitForTimeout(120);
      await page.evaluate(() => {
        const matrices = window.retinalHero.scenes.map(scene =>
          Array.from(scene.getObj(scene.scene.rootSubscene).par3d.userMatrix.getAsArray()));
        if (matrices.some(matrix => JSON.stringify(matrix) !== JSON.stringify(matrices[0]))) {
          throw new Error('Retinal scene camera matrices differ.');
        }
      });
    }

    await frame(0);
    const pixelCounts = [];
    for (let i = 0; i < 2; i++) pixelCounts.push(await canvasPixels(canvases.nth(i)));
    if (pixelCounts.some(result => result.colored < 1000)) {
      throw new Error(`One or more retinal scenes are blank: ${JSON.stringify(pixelCounts)}`);
    }

    fs.mkdirSync(path.join('man', 'figures'), { recursive: true });
    await screenshot(path.join('man', 'figures', 'readme-retinal-development.png'));

    for (const index of [Math.floor(frameCount / 4), Math.floor(frameCount / 2),
      Math.floor(3 * frameCount / 4)]) {
      await frame(index);
      await screenshot(path.join(out, `quarter-${index}.png`));
    }

    if (process.argv.includes('--animation')) {
      const frames = path.join(out, 'frames');
      fs.mkdirSync(frames, { recursive: true });
      for (let i = 0; i < frameCount; i++) {
        await frame(i);
        await screenshot(path.join(frames,
          `frame-${String(i).padStart(3, '0')}.png`));
        if (i % 12 === 0) console.log(`Captured ${i + 1}/${frameCount} frames`);
      }
    }

    if (errors.length) throw new Error(errors.join('\n'));
    console.log(`Verified two nonblank synchronized scenes; ${frameCount} camera frames.`);
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
