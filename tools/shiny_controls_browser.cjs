const playwright=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert=require('node:assert/strict');
const {spawn}=require('node:child_process');
const engine=process.env.IVUE_BROWSER || 'chromium';
(async()=>{
 const app=spawn('Rscript',['tools/shiny_controls.R'],{stdio:'inherit'});
 const browser=await playwright[engine].launch({headless:true,args:engine==='chromium'?['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']:[]});
 try {
  const page=await browser.newPage(); const errors=[];page.on('pageerror',e=>errors.push(e.message));
  for(let i=0;i<60;i++) {
   try {await page.goto('http://127.0.0.1:4873');break;} catch(e) {if(i===59)throw e; await new Promise(r=>setTimeout(r,500));}
  }
  const scene=page.locator('#scene'), reference=page.locator('#reference');
  await scene.getByText('View controls',{exact:true}).click();
  const snapshot=el=>{const r=el.rglinstance,p=r.getObj(r.scene.rootSubscene).par3d;return p.userMatrix.getAsArray();};
  const other=await reference.evaluate(snapshot);
  await scene.getByRole('button',{name:'Rotate left',exact:true}).focus();
  await page.keyboard.press('Enter');
  assert.deepEqual(await reference.evaluate(snapshot),other);
  // Programmatic reactive update while focus remains on the camera button.
  await page.evaluate(()=>Shiny.setInputValue('revision',2));
  await page.waitForFunction(()=>document.getElementById('scene').getAttribute('aria-label')==='Reactive triangle, revision 2');
  await page.waitForFunction(()=>document.activeElement.textContent==='Rotate left');
  assert.equal(await scene.locator('.ivue-tools').count(),1);
  assert.equal(await scene.locator('.ivue-legend').count(),1);
  assert.equal(await page.locator('#scene-ivue-description').innerText(),'Reactive triangle, revision 2');
  await scene.getByRole('button',{name:'Reset view',exact:true}).click();
  await scene.getByRole('button',{name:'Show view settings',exact:true}).click();
  assert.ok((await scene.getByRole('textbox').inputValue()).includes('view <- list('));
  await page.getByLabel('Unrelated input',{exact:true}).focus();
  await page.evaluate(()=>Shiny.setInputValue('revision',3));
  await page.waitForFunction(()=>document.getElementById('scene').getAttribute('aria-label')==='Reactive triangle, revision 3');
  assert.equal(await page.evaluate(()=>document.activeElement.id),'outside');
  const slider=page.getByRole('slider',{name:'Reactive animation, revision 3 Frame',exact:true});
  await slider.focus();await page.keyboard.press('End');
  await page.waitForFunction(()=>document.querySelector('#animation input[type=range]').getAttribute('aria-valuetext')==='Full size');
  await page.evaluate(()=>Shiny.setInputValue('revision',4));
  await page.waitForFunction(()=>document.activeElement.getAttribute('aria-label')==='Reactive animation, revision 4 Frame');
  await page.keyboard.press('End');
  assert.equal(await page.getByRole('slider',{name:'Reactive animation, revision 4 Frame',exact:true}).inputValue(),'1');
  assert.equal(await page.locator('#animation .rglPlayer').count(),1);
  assert.ok(await page.getByText('Positions change; the same observations remain.',{exact:true}).isVisible());
  const oldPlayer=await page.locator('#animation .rglPlayer').elementHandle();
  await page.locator('#animation').getByRole('button',{name:'Play',exact:true}).click();
  assert.equal(await oldPlayer.evaluate(el=>el.rgltimer.enabled),true);
  await page.evaluate(()=>Shiny.setInputValue('revision',5));
  await page.waitForFunction(()=>document.querySelector('#animation .rglWebGL').getAttribute('aria-label')==='Reactive animation, revision 5');
  assert.equal(await oldPlayer.evaluate(el=>el.rgltimer.enabled),false);
  await oldPlayer.dispose();
  assert.deepEqual(await reference.evaluate(snapshot),other);
  assert.deepEqual(errors,[]);
  await page.screenshot({path:`artifacts/shiny-controls-${engine}.png`,fullPage:true});
  console.log(`PASS (${engine}): Shiny rerender focus, external focus, one scoped legend/panel, updated description, animation player/caption and independent reference.`);
 } finally {await browser.close();app.kill('SIGTERM');}
})().catch(e=>{console.error(e);process.exitCode=1;});
