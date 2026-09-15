const playwright=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
const {execFileSync}=require('node:child_process');
const engine=process.env.IVUE_BROWSER || 'chromium';
(async()=>{
 const browser=await playwright[engine].launch({headless:true,args:engine==='chromium'?['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']:[]});
 try {
  async function measure(file) {
   const records=JSON.parse(fs.readFileSync(file));
   for(const record of records) {
    const page=await browser.newPage({viewport:{width:record.width,height:record.height+150}});
    await page.goto(pathToFileURL(path.resolve(`artifacts/gif-${record.name}.html`)).href);
    await page.locator('.ivue-tools').waitFor();
    const projected=await page.locator('.rglWebGL').evaluate((el,rec)=>{
     // Match the GIF geometry pane, with labels and annotations disabled.
     el.style.width=rec.width+'px';el.style.height=rec.height+'px';
     const r=el.rglinstance;el.width=rec.width;el.height=rec.height;r.resize(el);r.drawScene();
     r.setViewport(r.scene.rootSubscene);
     r.setmvMatrix(r.scene.rootSubscene);r.setprMatrix(r.scene.rootSubscene);r.setprmvMatrix();
     const m=r.prmvMatrix.getAsArray();
     function project(x) {
      const y=[0,0,0,0];for(let i=0;i<4;i++)for(let j=0;j<4;j++)y[i]+=m[j*4+i]*(j===3?1:x[j]);
      return [y[0]/y[3]*rec.width/2,y[1]/y[3]*rec.height/2];
     }
     const a=project(rec.X[0]),b=project(rec.X[1]);
     return Math.hypot(a[0]-b[0],a[1]-b[1]);
    },record);
    assert.ok(Math.abs(projected/record['raster.distance']-1)<.03,JSON.stringify({record,projected}));
    console.log(`${engine} ${record.name}: browser ${projected.toFixed(2)}px, GIF ${record['raster.distance'].toFixed(2)}px`);
    if(record.name==='case-1') {
     await page.getByText('View controls',{exact:true}).click();
     await page.getByRole('button',{name:'Zoom in',exact:true}).click();
     await page.getByRole('button',{name:'Rotate right',exact:true}).click();
     await page.getByRole('button',{name:'Show view settings',exact:true}).click();
     fs.writeFileSync('artifacts/gif-camera.R',await page.getByRole('textbox').inputValue());
    }
    await page.close();
   }
  }
  await measure('artifacts/gif-projections.json');
  execFileSync('Rscript',['tools/render_gif_presentation.R','artifacts/gif-camera.R'],{stdio:'inherit'});
  await measure('artifacts/gif-recovered.json');
  console.log(`PASS (${engine}): browser and raster segment lengths agree within 3% at two zooms, two aspect ratios, two extents and a recovered camera.`);
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
