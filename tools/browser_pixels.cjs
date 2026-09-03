async function pixels(canvas) {
  return canvas.evaluate(c => {
    const gl = c.getContext('webgl') || c.getContext('experimental-webgl') || c.getContext('webgl2');
    if (!gl || !c.width || !c.height) return { colored: 0 };
    const data = new Uint8Array(c.width * c.height * 4);
    gl.readPixels(0, 0, c.width, c.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
    let colored = 0, hash = 2166136261;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] && Math.min(data[i], data[i + 1], data[i + 2]) < 230) colored++;
      hash = Math.imul(hash ^ data[i], 16777619);
      hash = Math.imul(hash ^ data[i + 1], 16777619);
      hash = Math.imul(hash ^ data[i + 2], 16777619);
    }
    return { colored, hash, width: c.width, height: c.height };
  });
}

async function ready(canvas) {
  await canvas.waitFor({ state: 'visible', timeout: 30000 });
  for (let i = 0; i < 100; i++) {
    const result = await pixels(canvas);
    if (result.colored > 100) return result;
    await new Promise(resolve => setTimeout(resolve, 50));
  }
  throw new Error('Canvas is blank');
}

async function rotate(page, canvas) {
  await canvas.scrollIntoViewIfNeeded();
  const before = await ready(canvas);
  const box = await canvas.boundingBox();
  const started = Date.now();
  await page.mouse.move(box.x + box.width * 0.65, box.y + box.height * 0.65);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width * 0.85, box.y + box.height * 0.4, { steps: 8 });
  await page.mouse.up();
  for (let i = 0; i < 100; i++) {
    const after = await pixels(canvas);
    if (after.hash !== before.hash && after.colored > 100)
      return { before, after, responseMs: Date.now() - started };
    await page.waitForTimeout(50);
  }
  throw new Error('Rotation did not change canvas pixels');
}
module.exports = { pixels, ready, rotate };
