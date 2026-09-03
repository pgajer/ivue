const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const { ready, rotate } = require('./browser_pixels.cjs');
const fs = require('node:fs');

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const results = [];
  try {
    for (const width of [1440, 390]) {
      const page = await browser.newPage({ viewport: { width, height: 1000 } });
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      await page.goto(`http://127.0.0.1:${process.env.IVUE_PROJECT_PORT || 4874}`);
      await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.$socket.readyState === 1);
      const input = async (id, value) => {
        await page.evaluate(({ id, value }) => {
          Shiny.setInputValue(id, value, { priority: 'event' });
        }, { id, value });
        await page.waitForTimeout(750);
      };
      await input('project_select', 'ivue_saddle');
      await page.locator('#graph_layout_renderer').waitFor({ state: 'attached' });
      await page.waitForTimeout(2000); // Allow project-driven input updates to settle.
      await input('graph_layout_renderer', 'rglwidget');
      try { await page.locator('.gf-rgl-legend').waitFor(); }
      catch (error) { console.error(await page.locator('body').innerText()); throw error; }
      for (const [primitive, color] of [['point', 'vertex_degree'], ['sphere', 'vertex_degree'],
                                       ['sphere', 'solid_color'], ['point', 'solid_color'], ['point', 'vertex_degree']]) {
        await input('graph_layout_vertex', primitive);
        await input('graph_layout_color_by', color);
        const canvas = page.locator('.rglWebGL canvas').first();
        await ready(canvas);
        try {
          await page.waitForFunction(expected => document.querySelectorAll('.gf-rgl-legend').length === expected,
            color === 'solid_color' ? 0 : 1);
        } catch (error) {
          console.error({ width, primitive, color, body: await page.locator('body').innerText() });
          await page.screenshot({ path: 'artifacts/project-failure.png', fullPage: true });
          throw error;
        }
        const interaction = await rotate(page, canvas);
        const legendCount = await page.locator('.gf-rgl-legend').count();
        const duplicateLegends = await page.locator('.ivue-legend').count();
        const swatches = await page.locator('.gf-rgl-legend-swatch').evaluateAll(xs =>
          xs.map(x => getComputedStyle(x).backgroundColor));
        const serverErrors = await page.locator('.shiny-output-error').allTextContents();
        if (legendCount !== (color === 'solid_color' ? 0 : 1) || duplicateLegends ||
            (color !== 'solid_color' && new Set(swatches).size < 3) || serverErrors.length || errors.length)
          throw new Error(JSON.stringify({ primitive, color, legendCount, serverErrors, errors }));
        results.push({ width, primitive, color, legendCount, duplicateLegends, swatches,
          interaction, serverErrors, errors: [...errors] });
        await page.screenshot({ path: `artifacts/project-${primitive}-${color}-${width}.png`, fullPage: true });
      }
      await page.close();
    }
  } finally {
    await browser.close();
    fs.writeFileSync('artifacts/project-browser-results.json', JSON.stringify(results, null, 2));
  }
  console.log(`Passed ${results.length} real-project render states`);
})().catch(e => { console.error(e); process.exitCode = 1; });
