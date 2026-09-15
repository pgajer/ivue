// One focus tracker per document, shared by static scenes and renderUI players.
// Retaining only the most recent target avoids listeners on detached widgets.
if (!window.ivueTrackFocus) {
  document.addEventListener('focusin', function(e) {
    var widget = e.target.closest('.rglWebGL, .rglPlayer');
    var output = widget && widget.closest('.shiny-bound-output');
    var kind = widget && (widget.classList.contains('rglPlayer') ? '.rglPlayer' : '.rglWebGL');
    var key = e.target.getAttribute('data-ivue-control');
    if (kind === '.rglPlayer') key = e.target.type === 'range' ? 'frame' : e.target.id.split('-').pop();
    window.ivueActiveControl = widget ? {widget:widget, output:output, kind:kind,
      index:output ? Array.from(output.querySelectorAll(kind)).indexOf(widget) : -1, key:key} : null;
  });
  window.ivueTrackFocus = true;
}
window.ivueFocusTarget = function(el) {
  var p=window.ivueActiveControl;
  if (!p || !p.key) return null;
  if (document.activeElement !== document.body && !el.contains(document.activeElement)) return null;
  if (p.widget === el) return p.key;
  var output=el.closest('.shiny-bound-output');
  if (!p.widget.isConnected && output && p.output === output && el.matches(p.kind) &&
      Array.from(output.querySelectorAll(p.kind)).indexOf(el) === p.index) return p.key;
  return null;
};
window.ivueRestorePlayerFocus = function(el) {
  var key=window.ivueFocusTarget(el);
  if (!key || (window.ivueActiveControl && window.ivueActiveControl.widget === el)) return;
  var node=Array.from(el.querySelectorAll('input')).find(function(input) {
    return key === 'frame' ? input.type === 'range' : input.id.endsWith('-'+key);
  });
  if (node) node.focus();
};
/* Controls are scoped to one rgl widget, including on Shiny re-render. */
window.ivueView = function(el, data) {
  var restore = window.ivueFocusTarget(el), expanded = el.ivueExpanded;
  if (restore && restore !== 'summary') expanded = true;
  Array.from(el.children).forEach(function(child) {
    if (child.classList.contains('ivue-legend') || child.classList.contains('ivue-tools')) child.remove();
  });
  var rgl = el.rglinstance, canvas = el.querySelector('canvas');
  el.style.position = 'relative';
  el.setAttribute('role', 'group');
  el.removeAttribute('aria-labelledby');
  el.setAttribute('aria-label', data.description);
  if (canvas) {
    canvas.removeAttribute('aria-labelledby');
    canvas.setAttribute('role', 'img');
    canvas.setAttribute('aria-label', data.description);
    canvas.textContent = data.description + ' WebGL is required for the interactive view.';
  }
  if (data.shinyDescription) {
    var description = document.getElementById(el.id + '-ivue-description');
    if (!description) {
      description = document.createElement('p'); description.id = el.id + '-ivue-description';
      description.className = 'ivue-description'; el.after(description);
    }
    description.textContent = data.description;
  }
  if (!data.controls || !rgl) return;
  var root = rgl.scene.rootSubscene;
  function par() { return rgl.getObj(root).par3d; }
  function camera() {
    var p = par();
    return {matrix:p.userMatrix.getAsArray().slice(), zoom:p.zoom, fov:p.FOV, observer:p.observer.slice()};
  }
  var initial = camera();
  var panel = document.createElement('details'); panel.className = 'ivue-tools';
  var summary = document.createElement('summary'); summary.textContent = 'View controls'; summary.setAttribute('data-ivue-control','summary'); panel.appendChild(summary);
  panel.open = !!expanded;
  panel.addEventListener('toggle', function() { el.ivueExpanded = panel.open; });
  var hint = document.createElement('p'); hint.textContent = 'Drag to rotate; scroll to zoom. Buttons provide keyboard alternatives. Reset restores the initial camera.'; panel.appendChild(hint);
  panel.setAttribute('aria-label', data.description + ' View controls');
  function button(label, action) {
    var b = document.createElement('button'); b.type='button'; b.textContent=label; b.setAttribute('data-ivue-control',label);
    b.addEventListener('click', function(e) { e.stopPropagation(); action(); }); panel.appendChild(b); return b;
  }
  function draw() { rgl.drawScene(); }
  button('Rotate left', function() { par().userMatrix.rotate(10,0,1,0); draw(); });
  button('Rotate right', function() { par().userMatrix.rotate(-10,0,1,0); draw(); });
  button('Rotate up', function() { par().userMatrix.rotate(10,1,0,0); draw(); });
  button('Rotate down', function() { par().userMatrix.rotate(-10,1,0,0); draw(); });
  button('Zoom in', function() { par().zoom = Math.max(1e-6, par().zoom/1.2); draw(); });
  button('Zoom out', function() { par().zoom = Math.min(1e6, par().zoom*1.2); draw(); });
  button('Reset view', function() {
    var p=par(); p.userMatrix.load(initial.matrix); p.zoom=initial.zoom; p.FOV=initial.fov; p.observer=initial.observer.slice(); draw();
  });
  var text = document.createElement('textarea'); text.readOnly=true; text.hidden=true; text.setAttribute('data-ivue-control','settings');
  text.setAttribute('aria-label', 'Current view settings as R code');
  function recipe() {
    var c=camera(), bounds=par().bbox.slice();
    // rgl stores bounds as floats; retain exact R coordinate endpoints too.
    for (var i=0; i<6; i++) bounds[i] = i%2 ? Math.max(bounds[i],data.observationBounds[i]) : Math.min(bounds[i],data.observationBounds[i]);
    if (!c.matrix.concat(bounds,c.observer,[c.zoom,c.fov]).every(Number.isFinite) || c.zoom<=0 || c.fov<0 || c.fov>=180)
      throw new Error('The current camera has invalid settings. Reset the view and try again.');
    return '# Same dimensions are needed for equal screen scale. Browser changes do not update R.\n' +
      'view <- list(\n  camera = list(userMatrix = matrix(c(' + c.matrix.join(', ') +
      '), nrow = 4), zoom = ' + c.zoom + ', fov = ' + c.fov + ', observer = c(' + c.observer.join(', ') + ')),\n' +
      '  limits = matrix(c(' + bounds.join(', ') + '), nrow = 3, byrow = TRUE),\n' +
      '  aspect = "' + data.aspect + '")\n' +
      '# source("ivue-view.R"); plot3D.plain(X, camera=view$camera, limits=view$limits, aspect=view$aspect)\n';
  }
  var status=document.createElement('span'); status.setAttribute('role','status');
  function show() { text.value=recipe(); text.hidden=false; text.focus(); text.select(); }
  button('Show view settings', function() { try { show(); } catch(e) { status.textContent=e.message; } });
  button('Download view settings', function() {
    try {
      var url=URL.createObjectURL(new Blob([recipe()], {type:'text/plain;charset=utf-8'}));
      var a=document.createElement('a'); a.href=url; a.download='ivue-view.R'; a.click();
      setTimeout(function() { URL.revokeObjectURL(url); },1000);
      status.textContent='Downloaded ivue-view.R.';
    } catch(e) { status.textContent=e.message; }
  });
  panel.appendChild(text); panel.appendChild(status); el.appendChild(panel);
  if (restore) {
    var target=Array.from(panel.querySelectorAll('[data-ivue-control]')).find(function(node) {
      return node.getAttribute('data-ivue-control') === restore;
    });
    if (target) {
      if (restore === 'settings') { text.value=recipe(); text.hidden=false; }
      target.focus();
    }
  }
  // Canvas drag handlers must not consume control interactions.
  ['pointerdown','mousedown','touchstart','wheel'].forEach(function(event) {
    panel.addEventListener(event,function(e) { e.stopPropagation(); });
  });
};
