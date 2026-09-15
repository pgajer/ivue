// Standalone and narrow-screen regression checks, run in the browser CI job.
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('node:fs'), path=require('node:path');
const {pathToFileURL}=require('node:url');
const {execFileSync}=require('node:child_process');
const assert=require('node:assert/strict');
function snapshot(page,index=0) {
  return page.locator('.rglWebGL').nth(index).evaluate(el=> {
    const p=el.rglinstance.getObj(el.rglinstance.scene.rootSubscene).par3d;
    return {matrix:p.userMatrix.getAsArray(),zoom:p.zoom,fov:p.FOV,bounds:p.bbox,observer:p.observer};
  });
}
function near(a,b) {assert.equal(a.length,b.length); a.forEach((v,i)=>assert.ok(Math.abs(v-b[i])<1e-5,`${v} != ${b[i]}`));}
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try {
  for(const width of [1280,390]) {
   const page=await browser.newPage({viewport:{width,height:950},reducedMotion:'reduce'});
   const errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.goto(pathToFileURL(path.resolve('artifacts/view-controls.html')).href);
   const first=page.locator('.rglWebGL').nth(0),second=page.locator('.rglWebGL').nth(1);
   await first.getByText('View controls',{exact:true}).click();
   assert.equal(await first.getAttribute('role'),'group');
   assert.equal(await first.locator('canvas').getAttribute('aria-label'),'Three reference observations');
   const initial=await snapshot(page), other=await snapshot(page,1);
   near(initial.bounds,other.bounds);near(initial.observer,other.observer);
   // Compare projection per data unit independently of the coordinates supplied.
   const scales=await page.locator('.rglWebGL').evaluateAll(els=>els.map(el=>{
    const r=el.rglinstance;r.setmvMatrix(r.scene.rootSubscene);r.setprMatrix(r.scene.rootSubscene);r.setprmvMatrix();return r.prmvMatrix.getAsArray();
   }));near(scales[0],scales[1]);
   await first.getByRole('button',{name:'Rotate left',exact:true}).focus();
   await page.keyboard.press('Enter');
   await first.getByRole('button',{name:'Zoom in',exact:true}).click();
   const changed=await snapshot(page);assert.notDeepEqual(changed.matrix,initial.matrix);assert.notEqual(changed.zoom,initial.zoom);
   assert.deepEqual(await snapshot(page,1),other);
   await first.getByRole('button',{name:'Show view settings',exact:true}).click();
   const recipe=await first.getByRole('textbox').inputValue();
   assert.ok(recipe.includes('observer = c('));
   fs.writeFileSync('artifacts/exported-view.R',recipe);
   const downloadPromise=page.waitForEvent('download');
   await first.getByRole('button',{name:'Download view settings',exact:true}).click();
   const download=await downloadPromise;await download.saveAs('artifacts/downloaded-view.R');
   assert.equal(fs.readFileSync('artifacts/downloaded-view.R','utf8'),recipe);
   execFileSync('Rscript',['tools/replay_view_recipe.R','artifacts/exported-view.R','artifacts/replayed-view.html'],{stdio:'inherit'});
   const replay=await browser.newPage({viewport:{width,height:950}});
   await replay.goto(pathToFileURL(path.resolve('artifacts/replayed-view.html')).href);
   await replay.getByText('View controls',{exact:true}).waitFor();
   const reproduced=await snapshot(replay);near(reproduced.matrix,changed.matrix);near(reproduced.observer,changed.observer);near(reproduced.bounds,changed.bounds);near([reproduced.zoom,reproduced.fov],[changed.zoom,changed.fov]);
   await replay.close();
   await first.getByRole('button',{name:'Reset view',exact:true}).click();
   assert.deepEqual(await snapshot(page),initial);
   await page.setViewportSize({width:width===390?800:420,height:950});
   near((await snapshot(page)).matrix,initial.matrix);
   await page.close();
   const animation=await browser.newPage({viewport:{width,height:900},reducedMotion:'reduce'});
   await animation.goto(pathToFileURL(path.resolve('artifacts/annotated-animation.html')).href);
   const slider=animation.getByRole('slider',{name:'Triangle expansion Frame',exact:true});
   await slider.waitFor();assert.equal(await slider.inputValue(),'0');
   await slider.focus();await animation.keyboard.press('ArrowRight');assert.equal(await slider.inputValue(),'1');
   await animation.keyboard.press('End');assert.equal(await slider.inputValue(),'2');
   assert.equal(await animation.getByText('Color: final height; positions: current frame.',{exact:true}).count(),1);
   await animation.getByText('Read legend as table',{exact:true}).click();
   assert.equal(await animation.getByRole('table').count(),1);
   const legendText=await animation.getByRole('table').innerText();
   await slider.focus();await animation.keyboard.press('Home');
   assert.equal(await animation.getByRole('table').innerText(),legendText);
   assert.equal(await animation.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
   await animation.screenshot({path:`artifacts/annotated-animation-${width}.png`,fullPage:true});
   await animation.close();
   const legend=await browser.newPage({viewport:{width,height:900}});
   await legend.goto(pathToFileURL(path.resolve('artifacts/readable-legend.html')).href);
   const region=legend.getByRole('region');await region.focus();await legend.keyboard.press('End');
   await region.getByText('Read legend as table',{exact:true}).click();assert.equal(await legend.getByRole('row').count(),12);
   assert.equal(await legend.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
   await legend.close();assert.deepEqual(errors,[]);
  }
  // Offline semantic descriptions survive disabled scripting and WebGL.
  const disabled=await browser.newPage({javaScriptEnabled:false});
  await disabled.goto(pathToFileURL(path.resolve('artifacts/annotated-animation.html')).href);
  assert.ok(await disabled.getByText('Color: final height; positions: current frame.',{exact:true}).isVisible());
  assert.ok(await disabled.getByText('Triangle expansion',{exact:true}).isVisible());
  await disabled.close();
  console.log('PASS: scoped keyboard controls, reset, downloadable/replayed camera, shared projection, labeled timeline, persistent caption/legend, no-script descriptions at desktop/mobile sizes.');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
