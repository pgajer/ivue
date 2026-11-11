(function connect() {
  const elements = [1, 2].map(i => document.getElementById('retinal-sgd-' + i));
  if (elements.some(el => !el || !el.rglinstance)) return setTimeout(connect, 50);
  const scenes = elements.map(el => el.rglinstance);
  const par = i => scenes[i].getObj(scenes[i].scene.rootSubscene).par3d;
  const read = i => ({matrix: par(i).userMatrix.getAsArray().slice(), zoom: par(i).zoom,
    fov: par(i).FOV, observer: par(i).observer.slice()});
  const initial = read(0);
  let active = 0, playing = false, lastTime = null, lastState = JSON.stringify(initial);
  const play = document.getElementById('play');
  play.setAttribute('aria-pressed', 'false');
  function setPlaying(value) {
    playing = value;
    play.innerHTML = value ? '&#10074;&#10074;' : '&#9654;';
    play.setAttribute('aria-pressed', String(value));
    play.title = value ? 'Pause synchronized rotation' : 'Start synchronized rotation';
    play.setAttribute('aria-label', play.title);
  }
  function synchronize(state) {
    for (let i = 0; i < scenes.length; i++) {
      par(i).userMatrix.load(state.matrix);
      par(i).zoom = state.zoom;
      par(i).FOV = state.fov;
      par(i).observer = state.observer.slice();
      scenes[i].drawScene();
    }
    lastState = JSON.stringify(state);
  }
  elements.forEach((el, i) => {
    ['pointerdown', 'wheel', 'touchstart'].forEach(event => el.addEventListener(event, () => {
      active = i; setPlaying(false);
    }, {capture: true, passive: true}));
  });
  function change(action) { action(par(active)); synchronize(read(active)); }
  const actions = {
    'rotate-left': () => change(p => p.userMatrix.rotate(10, 0, 1, 0)),
    'rotate-right': () => change(p => p.userMatrix.rotate(-10, 0, 1, 0)),
    'rotate-up': () => change(p => p.userMatrix.rotate(10, 1, 0, 0)),
    'rotate-down': () => change(p => p.userMatrix.rotate(-10, 1, 0, 0)),
    'zoom-in': () => change(p => { p.zoom = Math.max(0.05, p.zoom / 1.2); }),
    'zoom-out': () => change(p => { p.zoom = Math.min(5, p.zoom * 1.2); }),
    reset: () => { setPlaying(false); synchronize(initial); },
    play: () => setPlaying(!playing)
  };
  Object.entries(actions).forEach(([id, action]) => document.getElementById(id).addEventListener('click', action));
  function frame(time) {
    if (playing && lastTime !== null) {
      par(active).userMatrix.rotate(Math.min(time - lastTime, 50) * 360 / 14400, 0, 1, 0);
    }
    const state = read(active);
    if (JSON.stringify(state) !== lastState) synchronize(state);
    lastTime = time;
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  window.retinalComparisonReady = true;
})();
