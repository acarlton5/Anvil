// Anvil Console OS v3.0 — Flagship Tauri/WebKit2 Frontend
const state = {
  tab: 0,
  games: [],
  drives: [],
  system: {},
  selectedIndex: 0,
  settingsCat: 0,
  cartridgeModalOpen: false,
  cartridgeModalIdx: 0,
  powerModalOpen: false,
  powerModalIdx: 0,
  ingameOverlayOpen: false,
  ingameOverlayIdx: 0,
  gameRunning: false,
  activeGameName: "",
  lastButton: "NONE",
  controllerName: "Steam Deck Built-in Controller",
  cartridgeTargets: [
    {
      label: "MicroSD Card Slot (/mnt/sdcard)",
      path: "/mnt/sdcard",
      name: "MicroSD Cartridge",
      badge: "ACTIVE · 48 GAMES"
    },
    {
      label: "External USB Storage (/mnt/usb)",
      path: "/mnt/usb",
      name: "USB Game Cartridge",
      badge: "HOT-SWAP USB"
    },
    {
      label: "Local Cartridge Folder (/home/morphine/Cartridges)",
      path: "/home/morphine/Cartridges",
      name: "Custom Folder Cartridge",
      badge: "CUSTOM DIRECTORY"
    }
  ]
};

function artUrl(rawPath) {
  if (!rawPath) return "";
  let clean = rawPath.replace(/^file:\/\//, "");
  return `/art?p=${encodeURIComponent(clean)}`;
}

function updateClock() {
  const el = document.getElementById("clock-label");
  if (!el) return;
  const now = new Date();
  el.textContent = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}
setInterval(updateClock, 10000);
updateClock();

async function loadState() {
  try {
    const res = await fetch("/api/state");
    const data = await res.json();
    state.games = data.games || [];
    state.drives = data.drives || [];
    state.system = data.system || {};
    state.gameRunning = !!data.game_running;

    const pillCount = document.getElementById("cartridge-pill-count");
    if (pillCount) pillCount.textContent = `${state.games.length} Cartridges`;

    const profCount = document.getElementById("prof-cart-count");
    if (profCount) profCount.textContent = `${state.games.length}`;

    const libTotal = document.getElementById("lib-total-pill");
    if (libTotal) libTotal.textContent = `ALL (${state.games.length})`;

    renderHomeCarousel();
    renderLibraryGrid();
    updateSelectedGameHero();
    renderSettingsPane();
    renderCartridgeModalOptions();
  } catch (err) {
    console.error("Failed to fetch state:", err);
  }
}

function renderHomeCarousel() {
  const track = document.getElementById("home-carousel");
  if (!track) return;
  track.innerHTML = "";

  state.games.forEach((g, idx) => {
    const card = document.createElement("div");
    card.className = "game-card" + (idx === state.selectedIndex ? " focused" : "");
    card.dataset.idx = idx;
    card.onclick = () => {
      if (state.selectedIndex === idx) {
        launchSelectedGame();
      } else {
        selectGame(idx);
      }
    };

    const coverSrc = artUrl(g.grid || g.cover || g.poster || g.hero);
    if (coverSrc) {
      const img = document.createElement("img");
      img.className = "card-art";
      img.loading = "lazy";
      img.src = coverSrc;
      img.onerror = () => {
        img.style.display = "none";
      };
      card.appendChild(img);
    }

    const shade = document.createElement("div");
    shade.className = "card-shade";
    card.appendChild(shade);

    const pill = document.createElement("div");
    pill.className = "card-badge-top";
    pill.textContent = "CARTRIDGE";
    card.appendChild(pill);

    const playTag = document.createElement("div");
    playTag.className = "card-play-overlay";
    playTag.textContent = "A · PLAY";
    card.appendChild(playTag);

    track.appendChild(card);
  });
}

function renderLibraryGrid() {
  const grid = document.getElementById("library-grid");
  if (!grid) return;
  grid.innerHTML = "";

  state.games.forEach((g, idx) => {
    const card = document.createElement("div");
    card.className = "game-card" + (idx === state.selectedIndex ? " focused" : "");
    card.dataset.idx = idx;
    card.onclick = () => {
      if (state.selectedIndex === idx) {
        launchSelectedGame();
      } else {
        selectGame(idx);
      }
    };

    const coverSrc = artUrl(g.grid || g.cover || g.poster || g.hero);
    if (coverSrc) {
      const img = document.createElement("img");
      img.className = "card-art";
      img.loading = "lazy";
      img.src = coverSrc;
      img.onerror = () => {
        img.style.display = "none";
      };
      card.appendChild(img);
    }

    const shade = document.createElement("div");
    shade.className = "card-shade";
    card.appendChild(shade);

    const pill = document.createElement("div");
    pill.className = "card-badge-top";
    pill.textContent = "SD CARD";
    card.appendChild(pill);

    const playTag = document.createElement("div");
    playTag.className = "card-play-overlay";
    playTag.textContent = "A · LAUNCH";
    card.appendChild(playTag);

    grid.appendChild(card);
  });
}

function selectGame(idx) {
  if (!state.games.length) return;
  state.selectedIndex = Math.max(0, Math.min(state.games.length - 1, idx));

  // Update focused classes in Home & Library without full DOM rebuild
  document.querySelectorAll("#home-carousel .game-card").forEach((el, i) => {
    el.classList.toggle("focused", i === state.selectedIndex);
    if (i === state.selectedIndex && state.tab === 0) {
      el.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" });
    }
  });

  document.querySelectorAll("#library-grid .game-card").forEach((el, i) => {
    el.classList.toggle("focused", i === state.selectedIndex);
    if (i === state.selectedIndex && state.tab === 1) {
      el.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  });

  updateSelectedGameHero();
}

function updateSelectedGameHero() {
  const g = state.games[state.selectedIndex];
  if (!g) return;

  const heroSrc = artUrl(g.hero || g.grid || g.cover);
  const logoSrc = artUrl(g.logo);
  const coverSrc = artUrl(g.grid || g.cover || g.poster || g.hero);

  // Ambient Backdrop
  const backdropImg = document.getElementById("backdrop-img");
  if (backdropImg && heroSrc) {
    backdropImg.src = heroSrc;
  }

  // Home Hero Logo vs Title
  const homeLogo = document.getElementById("home-logo");
  const homeTitle = document.getElementById("home-title");
  if (logoSrc) {
    homeLogo.src = logoSrc;
    homeLogo.style.display = "block";
    homeTitle.style.display = "none";
    homeLogo.onerror = () => {
      homeLogo.style.display = "none";
      homeTitle.style.display = "block";
    };
  } else {
    homeLogo.style.display = "none";
    homeTitle.style.display = "block";
  }
  homeTitle.textContent = g.name || "Untitled Cartridge";

  const protonBadge = document.getElementById("home-proton-badge");
  if (protonBadge) {
    protonBadge.textContent = `CARTRIDGE · ${(g.proton || g.runner || "PROTON").toUpperCase()}`;
  }

  const driveBadge = document.getElementById("home-drive-badge");
  if (driveBadge) {
    driveBadge.textContent = (g.path || "").includes("/mnt/sdcard")
      ? "MICROSD CARTRIDGE (/mnt/sdcard)"
      : "EXTERNAL CARTRIDGE";
  }

  const counter = document.getElementById("home-index-counter");
  if (counter) {
    counter.textContent = `${state.selectedIndex + 1} / ${state.games.length}`;
  }

  // Library Preview Card
  const libArt = document.getElementById("lib-preview-art");
  if (libArt) libArt.src = coverSrc || heroSrc;

  const libLogo = document.getElementById("lib-preview-logo");
  const libTitle = document.getElementById("lib-preview-title");
  if (libLogo && logoSrc) {
    libLogo.src = logoSrc;
    libLogo.style.display = "block";
  } else if (libLogo) {
    libLogo.style.display = "none";
  }
  if (libTitle) libTitle.textContent = g.name || "Game";

  const libRunner = document.getElementById("lib-preview-runner");
  if (libRunner) libRunner.textContent = (g.proton || g.runner || "Proton Experimental").toUpperCase();

  const libPath = document.getElementById("lib-preview-path");
  if (libPath) libPath.textContent = g.path || "/mnt/sdcard/Games";

  // Store Hero spotlight
  const storeImg = document.getElementById("store-hero-img");
  const storeTitle = document.getElementById("store-hero-title");
  if (storeImg && heroSrc) storeImg.src = heroSrc;
  if (storeTitle) storeTitle.textContent = g.name || "ASTROBOTANICA";
}

function switchTab(newTab) {
  const count = 7;
  state.tab = ((newTab % count) + count) % count;

  document.querySelectorAll(".nav-tab").forEach((el, idx) => {
    el.classList.toggle("active", idx === state.tab);
  });

  const pages = [
    "page-home",
    "page-library",
    "page-store",
    "page-community",
    "page-profile",
    "page-downloads",
    "page-settings"
  ];
  pages.forEach((id, idx) => {
    const el = document.getElementById(id);
    if (el) el.classList.toggle("active", idx === state.tab);
  });

  if (state.tab === 0 || state.tab === 1) {
    selectGame(state.selectedIndex);
  } else if (state.tab === 6) {
    renderSettingsPane();
  }
}

function selectSettingCat(catIdx) {
  state.settingsCat = Math.max(0, Math.min(4, catIdx));
  document.querySelectorAll("#settings-cat-list .settings-cat").forEach((el, i) => {
    el.classList.toggle("active", i === state.settingsCat);
  });
  renderSettingsPane();
}

function renderSettingsPane() {
  const pane = document.getElementById("settings-detail-pane");
  if (!pane) return;

  if (state.settingsCat === 0) {
    const drivesHtml = state.drives
      .map(
        (d) => `
      <div class="drive-card ${d.id === "sdcard" ? "active-drive" : ""}">
        <div class="drive-header">
          <div>
            <div class="drive-title">${d.name} <span style="font-size:12px; color:var(--text-secondary); font-weight:600;">(${d.path})</span></div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:2px;">
              ${d.mounted ? `${d.used_gb} GB used of ${d.total_gb} GB (${d.free_gb} GB free)` : "Slot Ready — Insert Drive to Mount"}
              ${d.game_count > 0 ? ` · <strong style="color:var(--ember-light);">${d.game_count} Verified Cartridge Games</strong>` : ""}
            </div>
          </div>
          <span class="badge ${d.id === "sdcard" ? "badge-ember" : "badge-glass"}">${d.role}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill" style="width:${d.percent || 4}%;"></div>
        </div>
      </div>
    `
      )
      .join("");

    pane.innerHTML = `
      <div>
        <h2 class="settings-panel-title">Storage & Cartridge Provisioning</h2>
        <p class="settings-panel-sub">Convert any SD Card, USB drive, or directory into a plug-and-play Anvil Game Cartridge.</p>
      </div>

      <div class="drive-card active-drive" style="background:linear-gradient(135deg, rgba(255,90,31,0.18) 0%, rgba(18,25,38,0.92) 100%); display:flex; flex-direction:row; align-items:center; justify-content:space-between; gap:18px;">
        <div>
          <span class="badge badge-ember">CARTRIDGE BUILDER TOOL</span>
          <h3 style="font-size:18px; font-weight:800; margin-top:6px;">Make a Drive, SD Card, or Folder into an Anvil Cartridge</h3>
          <p style="font-size:12px; color:var(--text-secondary); margin-top:4px;">Creates <code>Games/</code> + <code>cartridge.meta</code> and registers the mount in Anvil OS without copying files to internal storage.</p>
        </div>
        <button class="btn-primary" style="flex-shrink:0;" onclick="openCartridgeModal()">
          <span class="glyph-circle">A</span>
          <span>CONFIGURE DRIVE</span>
        </button>
      </div>

      ${drivesHtml}
    `;
  } else if (state.settingsCat === 1) {
    const buttons = ["A", "B", "X", "Y", "LB", "RB", "LT", "RT", "UP", "DOWN", "LEFT", "RIGHT", "SELECT", "START", "GUIDE"];
    const matrixHtml = buttons
      .map(
        (b) => `
      <div class="pad-key ${state.lastButton === b ? "pressed" : ""}" id="pad-key-${b}">${b}</div>
    `
      )
      .join("");

    pane.innerHTML = `
      <div>
        <h2 class="settings-panel-title">Controller & Zero-Drift Calibration</h2>
        <p class="settings-panel-sub">Hardware input filtering for ${state.controllerName}</p>
      </div>

      <div class="drive-card active-drive">
        <div class="drive-header">
          <div>
            <div class="drive-title">Zero-Drift Deadzone & Gyro Filter</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">
              Analog stick deadzone locked at <strong>4000</strong> · Accelerometer/IMU sensors isolated to prevent ghost motion.
            </div>
          </div>
          <span class="badge badge-verified">CALIBRATED</span>
        </div>
      </div>

      <div class="drive-card">
        <div class="drive-header">
          <div>
            <div class="drive-title">STEAM / Guide Button Behavior</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">
              In-Game Overlay is locked while on the Anvil Home Launcher and only activates when a game session is running.
            </div>
          </div>
          <span class="badge badge-ember">PROTECTED</span>
        </div>
      </div>

      <div class="drive-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
          <span style="font-size:12px; font-weight:800; color:var(--text-secondary); letter-spacing:0.08em;">LIVE CONTROLLER DIAGNOSTIC MATRIX</span>
          <span style="font-size:12px; font-weight:800; color:var(--ember-light);" id="last-btn-label">LAST INPUT: ${state.lastButton}</span>
        </div>
        <div class="pad-matrix">${matrixHtml}</div>
      </div>
    `;
  } else if (state.settingsCat === 2) {
    pane.innerHTML = `
      <div>
        <h2 class="settings-panel-title">Display & Wayland Compositor</h2>
        <p class="settings-panel-sub">Hardware-accelerated WebKit2GTK + Hyprland Wayland output configuration.</p>
      </div>
      <div class="drive-card active-drive">
        <div class="drive-header">
          <div>
            <div class="drive-title">Internal Panel Resolution & Orientation</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">1280 × 800 (16:10 Native Landscape · Transform 3) · Fullscreen Scaling Enabled</div>
          </div>
          <span class="badge badge-ember">1280×800 NATIVE</span>
        </div>
      </div>
      <div class="drive-card">
        <div class="drive-header">
          <div>
            <div class="drive-title">Refresh Rate & VRR</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">Locked 60 Hz frame pacing with Variable Refresh Rate (VRR) enabled for fullscreen games.</div>
          </div>
          <span class="badge badge-verified">60 HZ VRR</span>
        </div>
      </div>
      <div class="drive-card">
        <div class="drive-header">
          <div>
            <div class="drive-title">Game Window Aspect Scaling (Bluey / Unity / Unreal Fix)</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">Forces fullscreen 1280×800 output on launch so games never render in a tiny corner window.</div>
          </div>
          <span class="badge badge-glass">ACTIVE</span>
        </div>
      </div>
    `;
  } else if (state.settingsCat === 3) {
    pane.innerHTML = `
      <div>
        <h2 class="settings-panel-title">Proton & Cartridge Runtime</h2>
        <p class="settings-panel-sub">Direct-from-cartridge execution environment and Wine/Proton compatibility layer.</p>
      </div>
      <div class="drive-card active-drive">
        <div class="drive-header">
          <div>
            <div class="drive-title">Default Compatibility Runner</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">GE-Proton11-9 + Proton Experimental with pre-configured Goldberg Steam API & Visual C++ Runtime</div>
          </div>
          <span class="badge badge-ember">GE-PROTON11-9</span>
        </div>
      </div>
      <div class="drive-card">
        <div class="drive-header">
          <div>
            <div class="drive-title">Zero-Copy Cartridge Execution</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">Preserves executable working directories directly on <code>/mnt/sdcard/Games</code> (fixes Aquapark Tycoon & Unity data paths).</div>
          </div>
          <span class="badge badge-verified">STRICT CARTRIDGE MODE</span>
        </div>
      </div>
    `;
  } else {
    pane.innerHTML = `
      <div>
        <h2 class="settings-panel-title">System & Hardware Specifications</h2>
        <p class="settings-panel-sub">Anvil Console OS v3.0 — Tauri / WebKit2GTK Hardware-Accelerated Shell</p>
      </div>
      <div class="drive-card active-drive">
        <div class="drive-header">
          <div>
            <div class="drive-title">${state.system.model || "Valve Steam Deck (Jupiter)"}</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">AMD Custom APU 0405 (Zen 2 4c/8t + RDNA 2 8 CUs) · 16 GB LPDDR5</div>
          </div>
          <span class="badge badge-ember">JUPITER</span>
        </div>
      </div>
      <div class="drive-card">
        <div class="drive-header">
          <div>
            <div class="drive-title">UI Rendering Architecture</div>
            <div style="font-size:12px; color:var(--text-secondary); margin-top:4px;">WebKit2GTK 4.1 Wayland Compositor · CSS Backdrop Blur · 600×900 Official Box Art Pipeline</div>
          </div>
          <span class="badge badge-verified">WEBKIT2 / TAURI</span>
        </div>
      </div>
    `;
  }
}

function renderCartridgeModalOptions() {
  const container = document.getElementById("modal-drive-options");
  if (!container) return;
  container.innerHTML = state.cartridgeTargets
    .map(
      (t, idx) => `
    <div class="modal-opt ${idx === state.cartridgeModalIdx ? "selected" : ""}" onclick="initializeCartridgeTarget(${idx})">
      <div>
        <div style="font-size:16px; font-weight:800;">${t.label}</div>
        <div style="font-size:12px; color:var(--text-secondary); margin-top:2px;">Initializes <code>${t.path}/Games</code> and <code>${t.path}/cartridge.meta</code></div>
      </div>
      <span class="badge ${idx === 0 ? "badge-ember" : "badge-glass"}">${t.badge}</span>
    </div>
  `
    )
    .join("");
}

function openCartridgeModal() {
  state.cartridgeModalOpen = true;
  state.cartridgeModalIdx = 0;
  renderCartridgeModalOptions();
  const modal = document.getElementById("cartridge-modal");
  if (modal) modal.classList.add("open");
}

function closeCartridgeModal() {
  state.cartridgeModalOpen = false;
  const modal = document.getElementById("cartridge-modal");
  if (modal) modal.classList.remove("open");
}

async function initializeCartridgeTarget(idx) {
  state.cartridgeModalIdx = idx;
  renderCartridgeModalOptions();
  const target = state.cartridgeTargets[idx];
  if (!target) return;

  const banner = document.getElementById("modal-status-banner");
  if (banner) {
    banner.textContent = `Initializing ${target.path} as '${target.name}'...`;
    banner.style.color = "#fbbf24";
  }

  try {
    const res = await fetch("/api/cartridge/init", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ path: target.path, label: target.name })
    });
    const data = await res.json();
    if (data.ok) {
      state.drives = data.drives || state.drives;
      state.games = data.games || state.games;
      if (banner) {
        banner.textContent = `✓ ${data.message}`;
        banner.style.color = "#4ade80";
      }
      renderSettingsPane();
      renderHomeCarousel();
      renderLibraryGrid();
    } else {
      if (banner) {
        banner.textContent = `Error: ${data.error || "Failed to initialize cartridge"}`;
        banner.style.color = "#f87171";
      }
    }
  } catch (err) {
    if (banner) {
      banner.textContent = `Error: ${err.message}`;
      banner.style.color = "#f87171";
    }
  }
}

function togglePowerModal() {
  state.powerModalOpen = !state.powerModalOpen;
  state.powerModalIdx = 0;
  const modal = document.getElementById("power-modal");
  if (modal) modal.classList.toggle("open", state.powerModalOpen);
  updatePowerModalSelection();
}

function updatePowerModalSelection() {
  document.querySelectorAll("#power-modal .modal-opt").forEach((el, idx) => {
    el.classList.toggle("selected", idx === state.powerModalIdx);
  });
}

async function triggerPower(action) {
  await fetch("/api/power", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action })
  });
  state.powerModalOpen = false;
  const modal = document.getElementById("power-modal");
  if (modal) modal.classList.remove("open");
}

async function launchSelectedGame() {
  const g = state.games[state.selectedIndex];
  if (!g || state.gameRunning) return;

  const titleEl = document.getElementById("home-title");
  if (titleEl) {
    titleEl.style.display = "block";
    titleEl.textContent = `Launching ${g.name}...`;
  }

  await fetch("/api/launch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: g.name,
      launch_command: g.launch_command,
      forgeworks_app_id: g.forgeworks_app_id || ""
    })
  });
}

async function resumeGameSession() {
  state.ingameOverlayOpen = false;
  const modal = document.getElementById("ingame-overlay-modal");
  if (modal) modal.classList.remove("open");
  await fetch("/api/resume", { method: "POST" });
}

async function quitGameSession() {
  state.ingameOverlayOpen = false;
  const modal = document.getElementById("ingame-overlay-modal");
  if (modal) modal.classList.remove("open");
  await fetch("/api/kill", { method: "POST" });
}

function updateIngameOverlaySelection() {
  document.querySelectorAll("#ingame-overlay-modal .modal-opt").forEach((el, idx) => {
    el.classList.toggle("selected", idx === state.ingameOverlayIdx);
  });
}

window.onAnvilGameState = function (running, gameName) {
  state.gameRunning = !!running;
  state.activeGameName = gameName || "";
  const igTitle = document.getElementById("ingame-title");
  if (igTitle && gameName) {
    igTitle.textContent = gameName;
  }
  if (!running) {
    state.ingameOverlayOpen = false;
    const modal = document.getElementById("ingame-overlay-modal");
    if (modal) modal.classList.remove("open");
    updateSelectedGameHero();
  }
};

window.onAnvilInput = function (action, family, controllerName) {
  if (controllerName) state.controllerName = controllerName;

  const btnMap = {
    south: "A",
    east: "B",
    west: "X",
    north: "Y",
    lb: "LB",
    rb: "RB",
    lt: "LT",
    rt: "RT",
    up: "UP",
    down: "DOWN",
    left: "LEFT",
    right: "RIGHT",
    select: "SELECT",
    start: "START",
    guide: "GUIDE"
  };
  state.lastButton = btnMap[action] || action.toUpperCase();

  // If on Controller Diagnostic tab, highlight button immediately
  if (state.tab === 6 && state.settingsCat === 1) {
    document.querySelectorAll(".pad-key").forEach((el) => el.classList.remove("pressed"));
    const keyEl = document.getElementById(`pad-key-${state.lastButton}`);
    if (keyEl) keyEl.classList.add("pressed");
    const lbl = document.getElementById("last-btn-label");
    if (lbl) lbl.textContent = `LAST INPUT: ${state.lastButton}`;
  }

  // 1. In-Game Overlay Modal handling (ONLY when a game is running)
  if (state.gameRunning) {
    if (action === "guide") {
      state.ingameOverlayOpen = !state.ingameOverlayOpen;
      state.ingameOverlayIdx = 0;
      const modal = document.getElementById("ingame-overlay-modal");
      if (modal) modal.classList.toggle("open", state.ingameOverlayOpen);
      updateIngameOverlaySelection();
      return;
    }
    if (state.ingameOverlayOpen) {
      if (action === "up" || action === "down") {
        state.ingameOverlayIdx = state.ingameOverlayIdx === 0 ? 1 : 0;
        updateIngameOverlaySelection();
      } else if (action === "south") {
        if (state.ingameOverlayIdx === 0) resumeGameSession();
        else quitGameSession();
      } else if (action === "east") {
        resumeGameSession();
      }
    }
    return;
  }

  // 2. Power Modal handling
  if (state.powerModalOpen) {
    const actions = ["sleep", "desktop", "restart", "shutdown", "cancel"];
    if (action === "up") {
      state.powerModalIdx = (state.powerModalIdx + actions.length - 1) % actions.length;
      updatePowerModalSelection();
    } else if (action === "down") {
      state.powerModalIdx = (state.powerModalIdx + 1) % actions.length;
      updatePowerModalSelection();
    } else if (action === "south") {
      const chosen = actions[state.powerModalIdx];
      if (chosen === "cancel") togglePowerModal();
      else triggerPower(chosen);
    } else if (action === "east" || action === "start") {
      togglePowerModal();
    }
    return;
  }

  // 3. Cartridge Initialization Modal handling
  if (state.cartridgeModalOpen) {
    const total = state.cartridgeTargets.length;
    if (action === "up") {
      state.cartridgeModalIdx = (state.cartridgeModalIdx + total - 1) % total;
      renderCartridgeModalOptions();
    } else if (action === "down") {
      state.cartridgeModalIdx = (state.cartridgeModalIdx + 1) % total;
      renderCartridgeModalOptions();
    } else if (action === "south") {
      initializeCartridgeTarget(state.cartridgeModalIdx);
    } else if (action === "east") {
      closeCartridgeModal();
    }
    return;
  }

  // 4. Global Shortcuts
  if (action === "start") {
    togglePowerModal();
    return;
  }
  if (action === "lb") {
    switchTab(state.tab - 1);
    return;
  }
  if (action === "rb") {
    switchTab(state.tab + 1);
    return;
  }
  if (action === "east" && state.tab !== 0) {
    switchTab(0);
    return;
  }
  if (action === "west") {
    if (state.tab === 6) {
      openCartridgeModal();
    } else if (state.tab === 0) {
      switchTab(1);
    } else {
      switchTab(6);
      selectSettingCat(0);
      openCartridgeModal();
    }
    return;
  }

  // 5. Tab-Specific D-Pad & Action Navigation
  if (state.tab === 0) {
    if (action === "left") selectGame(state.selectedIndex - 1);
    else if (action === "right") selectGame(state.selectedIndex + 1);
    else if (action === "south") launchSelectedGame();
  } else if (state.tab === 1) {
    if (action === "left") selectGame(state.selectedIndex - 1);
    else if (action === "right") selectGame(state.selectedIndex + 1);
    else if (action === "up") selectGame(state.selectedIndex - 4);
    else if (action === "down") selectGame(state.selectedIndex + 4);
    else if (action === "south") launchSelectedGame();
  } else if (state.tab === 6) {
    if (action === "up") selectSettingCat(state.settingsCat - 1);
    else if (action === "down") selectSettingCat(state.settingsCat + 1);
    else if (action === "south" && state.settingsCat === 0) openCartridgeModal();
  } else {
    if (action === "south") launchSelectedGame();
  }
};

// Keyboard fallback for testing/Desktop
window.addEventListener("keydown", (e) => {
  const map = {
    ArrowLeft: "left",
    ArrowRight: "right",
    ArrowUp: "up",
    ArrowDown: "down",
    Enter: "south",
    Escape: "east",
    Backspace: "east",
    "[": "lb",
    "]": "rb",
    x: "west",
    X: "west"
  };
  if (map[e.key]) {
    e.preventDefault();
    window.onAnvilInput(map[e.key], "keyboard", "Keyboard");
  }
});

window.addEventListener("DOMContentLoaded", loadState);
