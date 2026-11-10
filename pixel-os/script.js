document.addEventListener('DOMContentLoaded', () => {
  const windowsContainer = document.getElementById('windows-container');
  const taskbarApps = document.getElementById('taskbar-apps');
  const startBtn = document.getElementById('start-btn');
  const startMenu = document.getElementById('start-menu');
  const contextMenu = document.getElementById('context-menu');
  const clock = document.getElementById('clock');
  const desktop = document.getElementById('desktop');
  const shutdownScreen = document.getElementById('shutdown-screen');

  const STORAGE = {
    notes: 'pixelos_notes',
    theme: 'pixelos_theme',
    bg: 'pixelos_bg',
    wins: 'pixelos_windows'
  };

  // ---------- ESTADO ----------
  let highestZ = 10;
  const openWindows = {};
  let selectedIcon = null;

  const gallerySprites = ['👾','🚀','🌌','⭐','🛸','🎮','🕹️','👽','🤖','💾'];

  // ---------- APPS CONFIG ----------
  const appsConfig = {
    'mi-pc': {
      title: 'Mi PC', width: '420px', height: '280px',
      render: () => `
        <div style="display:flex; gap:8px; margin-bottom:6px;">
          <button class="retro-button">Archivo</button>
          <button class="retro-button">Edición</button>
          <button class="retro-button">Ver</button>
        </div>
        <ul class="file-list">
          <li>📁 Mis documentos</li>
          <li>📁 Imágenes</li>
          <li>📁 Música</li>
          <li>💾 Disco local (C:)</li>
          <li>🖥️ Panel de control</li>
        </ul>`
    },
    'notas': {
      title: 'Bloc de Notas', width: '400px', height: '320px',
      render: () => `
        <div class="notepad-bar">
          <button class="retro-button" id="note-new">Nuevo</button>
          <button class="retro-button" id="note-save">Guardar</button>
          <button class="retro-button" id="note-del">Eliminar</button>
        </div>
        <textarea class="notepad" id="notepad-area" placeholder="Escribe aquí..."></textarea>`,
      after: (el) => {
        const area = el.querySelector('#notepad-area');
        const notes = JSON.parse(localStorage.getItem(STORAGE.notes) || '[]');
        area.value = notes.join('\n\n---\n\n') || '';

        el.querySelector('#note-save').onclick = () => {
          const list = area.value.split('\n\n---\n\n').filter(Boolean);
          localStorage.setItem(STORAGE.notes, JSON.stringify(list));
          alert('Notas guardadas ✔');
        };
        el.querySelector('#note-new').onclick = () => { area.value = ''; };
        el.querySelector('#note-del').onclick = () => {
          if (confirm('¿Eliminar todas las notas?')) {
            area.value = '';
            localStorage.removeItem(STORAGE.notes);
          }
        };
      }
    },
    'galeria': {
      title: 'Galería Pixel', width: '460px', height: '360px',
      render: () => `
        <div class="gallery-grid" id="gallery-grid">
          ${gallerySprites.map((s,i) => `<div class="gallery-item" data-idx="${i}">${s}</div>`).join('')}
        </div>`,
      after: (el) => {
        el.querySelectorAll('.gallery-item').forEach(item => {
          item.onclick = () => {
            const idx = item.dataset.idx;
            el.innerHTML = `
              <div class="gallery-viewer">
                <div class="big-sprite">${gallerySprites[idx]}</div>
                <button class="retro-button" id="back-gallery">← Volver</button>
              </div>`;
            el.querySelector('#back-gallery').onclick = () => {
              el.innerHTML = `<div class="gallery-grid" id="gallery-grid">
                ${gallerySprites.map((s,i) => `<div class="gallery-item" data-idx="${i}">${s}</div>`).join('')}
              </div>`;
              el.querySelectorAll('.gallery-item').forEach(it => {
                it.onclick = () => { el.querySelector(`.gallery-item[data-idx="${it.dataset.idx}"]`).click(); };
              });
              // Re-bind correctamente
              bindGallery(el);
            };
          };
        });
        function bindGallery(container) {
          container.querySelectorAll('.gallery-item').forEach(item => {
            item.onclick = () => {
              const idx = item.dataset.idx;
              container.innerHTML = `
                <div class="gallery-viewer">
                  <div class="big-sprite">${gallerySprites[idx]}</div>
                  <button class="retro-button" id="back-gallery">← Volver</button>
                </div>`;
              container.querySelector('#back-gallery').onclick = () => {
                container.innerHTML = `<div class="gallery-grid">
                  ${gallerySprites.map((s,i) => `<div class="gallery-item" data-idx="${i}">${s}</div>`).join('')}
                </div>`;
                bindGallery(container);
              };
            };
          });
        }
      }
    },
    'control': {
      title: 'Panel de Control', width: '380px', height: '340px',
      render: () => `
        <div class="control-group">
          <h4>🎨 Color de fondo</h4>
          <div class="bg-swatches">
            <div class="bg-swatch" style="background:#008080" data-color="#008080"></div>
            <div class="bg-swatch" style="background:#2b2b3a" data-color="#2b2b3a"></div>
            <div class="bg-swatch" style="background:#3a1f4a" data-color="#3a1f4a"></div>
            <div class="bg-swatch" style="background:#1a3d2b" data-color="#1a3d2b"></div>
            <div class="bg-swatch" style="background:#5a2b2b" data-color="#5a2b2b"></div>
          </div>
        </div>
        <div class="control-group">
          <h4>🖼️ Imagen de fondo</h4>
          <button class="retro-button" id="bg-default">Verde clásico</button>
          <button class="retro-button" id="bg-pixel">Bosque pixelado</button>
        </div>
        <div class="control-group">
          <h4>🔊 Sonido</h4>
          <label><input type="checkbox" id="sound-toggle" checked> Efectos activados</label>
        </div>
        <div class="control-group">
          <h4>⚙️ Sistema</h4>
          <button class="retro-button" id="reset-all">Restaurar configuración</button>
        </div>`,
      after: (el) => {
        el.querySelectorAll('.bg-swatch').forEach(sw => {
          sw.onclick = () => {
            const c = sw.dataset.color;
            document.body.style.setProperty('--bg-color', c);
            document.body.style.setProperty('--bg-image', 'none');
            localStorage.setItem(STORAGE.bg, JSON.stringify({ type:'color', value:c }));
          };
        });
        el.querySelector('#bg-default').onclick = () => {
          document.body.style.setProperty('--bg-color', '#008080');
          document.body.style.setProperty('--bg-image', 'none');
          localStorage.setItem(STORAGE.bg, JSON.stringify({ type:'color', value:'#008080' }));
        };
        el.querySelector('#bg-pixel').onclick = () => {
          const grad = 'linear-gradient(180deg,#0a0a2a 0%,#1a3d6b 50%,#2a6b3d 100%)';
          document.body.style.setProperty('--bg-image', grad);
          localStorage.setItem(STORAGE.bg, JSON.stringify({ type:'gradient', value:grad }));
        };
        el.querySelector('#reset-all').onclick = () => {
          if (confirm('¿Restaurar todo?')) {
            localStorage.clear();
            location.reload();
          }
        };
      }
    },
    'papelera': {
      title: 'Papelera', width: '320px', height: '220px',
      render: () => `<p style="text-align:center; margin-top:40px;">🗑️ La papelera está vacía.</p>`
    }
  };

  // ---------- RELOJ ----------
  function updateClock() {
    const n = new Date();
    clock.textContent = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}`;
  }
  setInterval(updateClock, 1000); updateClock();

  // ---------- WINDOWS ----------
  function openApp(appId) {
    if (openWindows[appId]) { restoreWindow(appId); return; }
    const cfg = appsConfig[appId];
    if (!cfg) return;

    const tpl = document.getElementById('window-template');
    const clone = tpl.content.cloneNode(true);
    const win = clone.querySelector('.window');
    win.id = `win-${appId}`;
    win.querySelector('.window-title').textContent = cfg.title;

    const content = win.querySelector('.window-content');
    content.innerHTML = cfg.render ? cfg.render() : '';
    if (cfg.after) cfg.after(content);

    const offset = Object.keys(openWindows).length * 22;
    win.style.top = `${60 + offset}px`;
    win.style.left = `${60 + offset}px`;
    win.style.width = cfg.width;
    win.style.height = cfg.height;
    win.style.zIndex = ++highestZ;

    windowsContainer.appendChild(win);
    openWindows[appId] = { el: win, minimized: false };

    const tb = document.createElement('button');
    tb.className = 'taskbar-item active';
    tb.textContent = cfg.title;
    tb.dataset.appId = appId;
    tb.onclick = () => toggleMinimize(appId);
    taskbarApps.appendChild(tb);

    setupWindow(win, appId);
    focusWindow(win);
  }

  function setupWindow(win, appId) {
    win.querySelector('.close').onclick = () => closeApp(appId);
    win.querySelector('.minimize').onclick = () => minimizeApp(appId);
    win.querySelector('.maximize').onclick = () => {
      win.classList.toggle('maximized');
      focusWindow(win);
    };
    win.addEventListener('mousedown', () => focusWindow(win));

    const titleBar = win.querySelector('.title-bar');
    let drag = false, ox, oy;
    titleBar.addEventListener('mousedown', e => {
      if (e.target.closest('.window-controls')) return;
      drag = true;
      ox = e.clientX - win.offsetLeft;
      oy = e.clientY - win.offsetTop;
      focusWindow(win);
    });
    document.addEventListener('mousemove', e => {
      if (!drag) return;
      win.style.left = Math.max(0, e.clientX - ox) + 'px';
      win.style.top = Math.max(0, e.clientY - oy) + 'px';
    });
    document.addEventListener('mouseup', () => drag = false);
  }

  function focusWindow(win) {
    win.style.zIndex = ++highestZ;
    document.querySelectorAll('.window .title-bar').forEach(t => t.classList.add('inactive'));
    win.querySelector('.title-bar').classList.remove('inactive');
    const appId = win.id.replace('win-','');
    document.querySelectorAll('.taskbar-item').forEach(b => b.classList.remove('active'));
    const tb = document.querySelector(`.taskbar-item[data-app-id="${appId}"]`);
    if (tb) tb.classList.add('active');
  }

  function closeApp(appId) {
    const w = openWindows[appId]; if (!w) return;
    w.el.remove();
    delete openWindows[appId];
    const tb = document.querySelector(`.taskbar-item[data-app-id="${appId}"]`);
    if (tb) tb.remove();
  }

  function minimizeApp(appId) {
    const w = openWindows[appId]; if (!w) return;
    w.el.style.display = 'none';
    w.minimized = true;
    const tb = document.querySelector(`.taskbar-item[data-app-id="${appId}"]`);
    if (tb) tb.classList.remove('active');
  }

  function restoreWindow(appId) {
    const w = openWindows[appId]; if (!w) return;
    if (w.minimized) { w.el.style.display = 'flex'; w.minimized = false; }
    focusWindow(w.el);
  }

  function toggleMinimize(appId) {
    const w = openWindows[appId]; if (!w) return;
    if (w.minimized) restoreWindow(appId); else minimizeApp(appId);
  }

  // ---------- ICONOS DEL ESCRITORIO ----------
  document.querySelectorAll('.desktop-icon').forEach(icon => {
    icon.addEventListener('click', e => {
      e.stopPropagation();
      document.querySelectorAll('.desktop-icon').forEach(i => i.classList.remove('selected'));
      icon.classList.add('selected');
      selectedIcon = icon;
    });
    icon.addEventListener('dblclick', () => openApp(icon.dataset.app));
    icon.addEventListener('keydown', e => {
      if (e.key === 'Enter') openApp(icon.dataset.app);
    });
  });

  // ---------- MENÚ INICIO ----------
  startBtn.addEventListener('click', e => {
    e.stopPropagation();
    startMenu.classList.toggle('hidden');
    contextMenu.classList.add('hidden');
  });
  document.querySelectorAll('#start-menu .menu-item[data-app]').forEach(item => {
    item.onclick = () => { openApp(item.dataset.app); startMenu.classList.add('hidden'); };
  });

  // ---------- MENÚ CONTEXTUAL ----------
  desktop.addEventListener('contextmenu', e => {
    e.preventDefault();
    contextMenu.style.left = e.clientX + 'px';
    contextMenu.style.top = e.clientY + 'px';
    contextMenu.classList.remove('hidden');
  });
  document.addEventListener('click', e => {
    if (!startMenu.contains(e.target) && e.target !== startBtn) startMenu.classList.add('hidden');
    if (!contextMenu.contains(e.target)) contextMenu.classList.add('hidden');
  });
  document.querySelectorAll('#context-menu .menu-item').forEach(item => {
    item.onclick = () => {
      const a = item.dataset.action;
      if (a === 'refresh') location.reload();
      if (a === 'new-note') openApp('notas');
      if (a === 'change-bg') openApp('control');
      if (a === 'properties') alert('PIXEL OS v1.0\nUn escritorio retro hecho con HTML, CSS y JS.');
      contextMenu.classList.add('hidden');
    };
  });

  // ---------- APAGADO ----------
  document.getElementById('shutdown-btn').onclick = () => {
    startMenu.classList.add('hidden');
    shutdownScreen.classList.remove('hidden');
  };
  document.getElementById('reboot-btn').onclick = () => location.reload();

  // ---------- ESCAPE ----------
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      startMenu.classList.add('hidden');
      contextMenu.classList.add('hidden');
    }
  });

  // ---------- RESTAURAR TEMA Y FONDO ----------
  const savedBg = JSON.parse(localStorage.getItem(STORAGE.bg) || 'null');
  if (savedBg) {
    if (savedBg.type === 'color') {
      document.body.style.setProperty('--bg-color', savedBg.value);
      document.body.style.setProperty('--bg-image', 'none');
    } else {
      document.body.style.setProperty('--bg-image', savedBg.value);
    }
  }
});