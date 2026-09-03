const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');

(async () => {
  const browser = await chromium.launch({ headless: true,
    executablePath: process.env.CHROME_PATH || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  try {
    for (const width of [1280, 390]) {
      const page = await browser.newPage({ viewport: { width, height: 1000 } });
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      await page.goto(`http://127.0.0.1:${process.env.IVUE_SMOKE_PORT || 4873}`);
      await page.waitForFunction(() => document.querySelector('#status')?.textContent.startsWith('{'));
      for (const family of ['plain', 'numeric', 'groups', 'plain']) {
        for (const primitive of ['point', 'sphere']) {
          for (const overlay of [true, false]) {
            await page.evaluate(({ family, primitive, overlay }) => {
              Shiny.setInputValue('family', family, { priority: 'event' });
              Shiny.setInputValue('primitive', primitive, { priority: 'event' });
              Shiny.setInputValue('overlay', overlay, { priority: 'event' });
            }, { family, primitive, overlay });
            await page.waitForFunction(({ family, primitive, overlay }) => {
              try {
                const state = JSON.parse(document.querySelector('#status').textContent);
                return state.family === family && state.primitive === primitive && state.overlay === overlay &&
                  !document.documentElement.classList.contains('shiny-busy');
              } catch { return false; }
            }, { family, primitive, overlay });
            await page.waitForTimeout(300);
            const state = JSON.parse(await page.locator('#status').textContent());
            const legendCount = await page.locator('#scene > .ivue-legend').count();
            const expectedLegends = family === 'plain' ? 0 : 1;
            if (legendCount !== expectedLegends) throw new Error('Shiny legend missing, stale, or duplicated');
            const pixels = await page.locator('#scene canvas').evaluate(canvas => {
              const gl = canvas.getContext('webgl') || canvas.getContext('webgl2');
              const data = new Uint8Array(canvas.width * canvas.height * 4);
              gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
              let count = 0, hash = 2166136261;
              for (let i = 0; i < data.length; i += 4) {
                if (data[i + 3] && Math.min(data[i], data[i + 1], data[i + 2]) < 230) count++;
                hash = Math.imul(hash ^ data[i], 16777619);
              }
              return { count, hash };
            });
            const result = { width, ...state, legendCount, ...pixels, errors: [...errors] };
            results.push(result);
            console.log(JSON.stringify(result));
            if (state.rows !== 250 || !state.identities || pixels.count < 100 ||
                (family === 'numeric' && state.colors < 3) ||
                (family === 'groups' && state.colors !== 2) || errors.length) {
              throw new Error('Shiny rendering integration failed');
            }
          }
          if (results.at(-1).hash === results.at(-2).hash) throw new Error('Overlay did not alter rendered pixels');
        }
      }
      await page.screenshot({ path: `artifacts/shiny-${width}.png`, fullPage: true });
      await page.close();
    }
  } finally {
    await browser.close();
    fs.writeFileSync('artifacts/shiny-results.json', JSON.stringify(results, null, 2));
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
