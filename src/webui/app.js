// Anvil Console OS v3.5 — Authentic Xbox Series X Dashboard Frontend
const state = {
  tab: 0, // 0: Home, 1: My Games & Apps, 2: Store, 3: Settings
  homeZone: "shelf", // "top" | "shelf" | "quick"
  topNavIdx: 0,
  quickIdx: 0,
  games: [],
  drives: [],
  battery: { percent: 100, charging: false },
  system: {},
  selectedIndex: 0,
  settingsCat: 0,
  settingsRightIdx: 0,
  settingsFocusSide: true,
  guideOpen: false,
  guideIdx: 0,
  cartridgeModalOpen: false,
  cartridgeModalIdx: 0,
  powerModalOpen: false,
  powerModalIdx: 0,
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
  const clean = rawPath.replace(/^file:\/\//, "");
  return `/art?p=${encodeURIComponent(clean)}`;
}

function updateClock() {
  const now = new Date();
  const str = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  const el = document.getElementById("clock-label");
  if (el) el.textContent = str;
  const gEl = document.getElementById("guide-clock");
  if (gEl) gEl.textContent = str;
}
setInterval(updateClock, 10000);
updateClock();

async function loadState() {
  try {
    const res = await fetch("/api/state");
    const data = await res.json();
    state.games = data.games || [];
    state.drives = data.drives || [];
    state.battery = data.battery || { percent: 100, charging: false };
    state.system = data.system || {};
    state.gameRunning = !!data.game_running;

    // Update counts
    const count = state.games.length;
    const topCart = document.getElementById("top-cart-count");
    if (topCart) topCart.textContent = `${count} Cartridges`;
    const quickSub = document.getElementById("quick-lib-sub");
    if (quickSub) quickSub.textContent = `See all ${count} cartridges`;
    const libSideCount = document.getElementById("lib-side-count");
    if (libSideCount) libSideCount.textContent = `${count}`;

    // Update live battery bar
    const batFill = document.getElementById("battery-fill");
    const batText = document.getElementById("battery-text");
    if (batFill) batFill.style.width = `${Math.max(8, Math.min(100, state.battery.percent))}%`;
    if (batText) batText.textContent = `${state.battery.percent}%${state.battery.charging ? " ⚡" : ""}`;

    renderHomeShelf();
    renderLibraryGrid();
    updateSelectedGameHero();
    renderSettingsPane();
    renderGuideMenu();
    renderCartridgeModalOptions();
    syncHomeFocusVisuals();
  } catch (err) {
    console.error("Failed to load state:", err);
  }
}

function renderHomeShelf() {
  const track = document.getElementById("home-carousel");
  if (!track) return;
  track.innerHTML = "";

  state.games.forEach((g, idx) => {
    const tile = document.createElement("div");
    tile.className = "xbox-tile" + (idx === state.selectedIndex && state.homeZone === "shelf" ? " focused" : "");
    tile.dataset.idx = idx;
    tile.onclick = () => {
      state.homeZone = "shelf";
      if (state.selectedIndex === idx) {
        launchSelectedGame();
      } else {
        selectGame(idx);
      }
      syncHomeFocusVisuals();
    };

    const coverSrc = artUrl(g.grid || g.cover || g.poster || g.hero);
    if (coverSrc) {
      const img = document.createElement("img");
      img.className = "tile-art";
      img.loading = "lazy";
      img.src = coverSrc;
      tile.appendChild(img);
    }

    const badge = document.createElement("div");
    badge.className = "disc-badge";
    badge.textContent = "CARTRIDGE";
    tile.appendChild(badge);

    const footer = document.createElement("div");
    footer.className = "xbox-tile-footer";
    footer.innerHTML = `
      <div class="tile-play-text">
        <span class="a-btn-mini">A</span>
        <span>Play</span>
      </div>
      <span style="font-size:10px; color:#a1aab8; font-weight:700;">SD</span>
    `;
    tile.appendChild(footer);

    track.appendChild(tile);
  });
}

function renderLibraryGrid() {
  const grid = document.getElementById("library-grid");
  if (!grid) return;
  grid.innerHTML = "";

  state.games.forEach((g, idx) => {
    const card = document.createElement("div");
    card.className = "lib-card" + (idx === state.selectedIndex ? " focused" : "");
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
      img.loading = "lazy";
      img.src = coverSrc;
      card.appendChild(img);
    }

    const badge = document.createElement("div");
    badge.className = "disc-badge";
    badge.textContent = "SD";
    card.appendChild(badge);

    const titleBar = document.createElement("div");
    titleBar.className = "lib-card-title-bar";
    titleBar.textContent = g.name || "Game";
    card.appendChild(titleBar);

    grid.appendChild(card);
  });
}

function syncHomeFocusVisuals() {
  // Top nav circles
  document.querySelectorAll("#xbox-top-nav .top-nav-circle").forEach((el, idx) => {
    el.classList.toggle("focused", state.tab === 0 && state.homeZone === "top" && idx === state.topNavIdx);
  });

  // Main shelf tiles
  document.querySelectorAll("#home-carousel .xbox-tile").forEach((el, idx) => {
    const isFocused = state.homeZone === "shelf" && idx === state.selectedIndex;
    el.classList.toggle("focused", isFocused);
  });

  // Bottom quick cards
  document.querySelectorAll("#xbox-quick-row .xbox-quick-card").forEach((el, idx) => {
    el.classList.toggle("focused", state.homeZone === "quick" && idx === state.quickIdx);
  });
}

function selectGame(idx) {
  if (!state.games.length) return;
  state.selectedIndex = Math.max(0, Math.min(state.games.length - 1, idx));

  document.querySelectorAll("#home-carousel .xbox-tile").forEach((el, i) => {
    const isFocused = state.homeZone === "shelf" && i === state.selectedIndex;
    el.classList.toggle("focused", isFocused);
    if (i === state.selectedIndex && state.tab === 0) {
      el.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" });
    }
  });

  document.querySelectorAll("#library-grid .lib-card").forEach((el, i) => {
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

  const backdropImg = document.getElementById("backdrop-img");
  if (backdropImg && heroSrc) {
    backdropImg.src = heroSrc;
  }

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
    protonBadge.textContent = (g.proton || g.runner || "PROTON EXPERIMENTAL").toUpperCase();
  }

  const driveBadge = document.getElementById("home-drive-badge");
  if (driveBadge) {
    driveBadge.textContent = (g.path || "").includes("/mnt/sdcard")
      ? "MICROSD CARTRIDGE"
      : "EXTERNAL CARTRIDGE";
  }

  const counter = document.getElementById("home-index-counter");
  if (counter) {
    counter.textContent = `${state.selectedIndex + 1} OF ${state.games.length}`;
  }

  const libSelectedTitle = document.getElementById("lib-selected-title");
  if (libSelectedTitle) {
    libSelectedTitle.textContent = `${g.name}  •  (${state.selectedIndex + 1}/${state.games.length})`;
  }

  const storeImg = document.getElementById("store-hero-img");
  const storeTitle = document.getElementById("store-hero-title");
  if (storeImg && heroSrc) storeImg.src = heroSrc;
  if (storeTitle) storeTitle.textContent = g.name || "ASTROBOTANICA";
}

function activateTopNav(idx) {
  state.topNavIdx = idx;
  if (idx === 0) switchTab(0);
  else if (idx === 1) switchTab(1);
  else if (idx === 2) switchTab(2);
  else if (idx === 3) openCartridgeModal();
  else if (idx === 4) switchTab(3);
}

function triggerQuickCard(idx) {
  if (idx === 0) switchTab(1);
  else if (idx === 1) openCartridgeModal();
  else if (idx === 2) {
    switchTab(3);
    selectSettingCat(1);
  } else if (idx === 3) {
    switchTab(3);
    selectSettingCat(0);
  }
}

function switchTab(newTab) {
  const count = 4;
  state.tab = ((newTab % count) + count) % count;

  document.body.classList.toggle("subpage", state.tab !== 0);

  const navMap = { 0: 0, 1: 1, 2: 2, 3: 4 };
  document.querySelectorAll("#xbox-top-nav .top-nav-circle").forEach((el, idx) => {
    el.classList.toggle("active", idx === navMap[state.tab]);
  });

  const pages = ["page-home", "page-library", "page-store", "page-settings"];
  pages.forEach((id, idx) => {
    const el = document.getElementById(id);
    if (el) el.classList.toggle("active", idx === state.tab);
  });

  if (state.tab === 0) {
    state.homeZone = "shelf";
    syncHomeFocusVisuals();
    selectGame(state.selectedIndex);
  } else if (state.tab === 1) {
    selectGame(state.selectedIndex);
  } else if (state.tab === 3) {
    state.settingsFocusSide = true;
    renderSettingsPane();
  }
}

function selectSettingCat(catIdx) {
  state.settingsCat = Math.max(0, Math.min(4, catIdx));
  state.settingsRightIdx = 0;
  document.querySelectorAll("#settings-cat-list .xbox-settings-cat").forEach((el, i) => {
    el.classList.toggle("active", i === state.settingsCat);
    el.classList.toggle("focused", state.settingsFocusSide && i === state.settingsCat);
  });
  renderSettingsPane();
}

function renderSettingsPane() {
  const pane = document.getElementById("settings-detail-pane");
  if (!pane) return;

  document.querySelectorAll("#settings-cat-list .xbox-settings-cat").forEach((el, i) => {
    el.classList.toggle("active", i === state.settingsCat);
    el.classList.toggle("focused", state.settingsFocusSide && i === state.settingsCat);
  });

  if (state.settingsCat === 0) {
    const drivesHtml = state.drives
      .map(
        (d, idx) => `
      <div class="xbox-slate-card ${!state.settingsFocusSide && state.settingsRightIdx === idx + 1 ? "focused" : ""}" onclick="openCartridgeModal()">
        <div class="slate-row">
          <div>
            <div class="slate-title">${d.name} <span style="font-size:12px; color:var(--text-secondary); font-weight:600;">(${d.path})</span></div>
            <div class="slate-sub">
              ${d.mounted ? `${d.used_gb} GB used of ${d.total_gb} GB (${d.free_gb} GB free)` : "Slot Ready — Insert USB Drive to Mount"}
              ${d.game_count > 0 ? `  •  <strong style="color:#22c55e;">${d.game_count} Cartridge Games Ready</strong>` : ""}
            </div>
          </div>
          <span class="xbox-tag ${d.id === "sdcard" ? "green" : ""}">${d.role}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill" style="width:${d.percent || 3}%;"></div>
        </div>
      </div>
    `
      )
      .join("");

    pane.innerHTML = `
      <div class="xbox-slate-card ${!state.settingsFocusSide && state.settingsRightIdx === 0 ? "focused" : ""}" onclick="openCartridgeModal()">
        <div class="slate-row">
          <div>
            <span class="xbox-tag green" style="margin-bottom:6px; display:inline-block;">CARTRIDGE PROVISIONING</span>
            <div class="slate-title">Make a Drive, SD Card, or Folder into an Anvil Cartridge</div>
            <div class="slate-sub">Formats <code>Games/</code> + <code>cartridge.meta</code> and registers the mount without touching internal storage.</div>
          </div>
          <button class="xbox-btn"><span class="a-btn-mini" style="background:#0b0e13; color:#fff;">A</span><span>Configure Drive</span></button>
        </div>
      </div>
      ${drivesHtml}
    `;
  } else if (state.settingsCat === 1) {
    const buttons = ["A", "B", "X", "Y", "LB", "RB", "LT", "RT", "UP", "DOWN", "LEFT", "RIGHT", "SELECT", "START", "GUIDE"];
    const matrixHtml = buttons
      .map((b) => `<div class="pad-key ${state.lastButton === b ? "pressed" : ""}" id="pad-key-${b}">${b}</div>`)
      .join("");

    pane.innerHTML = `
      <div class="xbox-slate-card ${!state.settingsFocusSide ? "focused" : ""}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Zero-Drift Deadzone & Gyro Filter</div>
            <div class="slate-sub">Analog stick deadzone locked at <strong>4000</strong>  •  IMU motion sensors isolated from joystick axes.</div>
          </div>
          <span class="xbox-tag green">CALIBRATED</span>
        </div>
      </div>
      <div class="xbox-slate-card">
        <div class="slate-row">
          <div>
            <div class="slate-title">STEAM / Guide Button Lock</div>
            <div class="slate-sub">In-game overlay is locked while on the Home screen and only activates while a game is running.</div>
          </div>
          <span class="xbox-tag">PROTECTED</span>
        </div>
      </div>
      <div class="xbox-slate-card">
        <div class="slate-row">
          <span style="font-size:12px; font-weight:800; color:var(--text-secondary);">LIVE CONTROLLER INPUT TEST</span>
          <span style="font-size:12px; font-weight:800; color:#22c55e;" id="last-btn-label">LAST INPUT: ${state.lastButton}</span>
        </div>
        <div class="pad-matrix">${matrixHtml}</div>
      </div>
    `;
  } else if (state.settingsCat === 2) {
    pane.innerHTML = `
      <div class="xbox-slate-card ${!state.settingsFocusSide ? "focused" : ""}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Display Resolution & Refresh Rate</div>
            <div class="slate-sub">1280 × 800 (16:10 Native Landscape)  •  60 Hz Locked with Variable Refresh Rate (VRR)</div>
          </div>
          <span class="xbox-tag green">1280×800 60HZ</span>
        </div>
      </div>
      <div class="xbox-slate-card">
        <div class="slate-row">
          <div>
            <div class="slate-title">Fullscreen Game Scaling Fix</div>
            <div class="slate-sub">Forces fullscreen 1280×800 output for Unity & Unreal games (Bluey: The Videogame verified).</div>
          </div>
          <span class="xbox-tag">ENABLED</span>
        </div>
      </div>
    `;
  } else if (state.settingsCat === 3) {
    pane.innerHTML = `
      <div class="xbox-slate-card ${!state.settingsFocusSide ? "focused" : ""}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Default Compatibility Layer</div>
            <div class="slate-sub">GE-Proton11-9 & Proton Experimental with Goldberg Steam API and VC++ Runtime</div>
          </div>
          <span class="xbox-tag green">PROTON READY</span>
        </div>
      </div>
      <div class="xbox-slate-card">
        <div class="slate-row">
          <div>
            <div class="slate-title">Strict Zero-Copy Cartridge Execution</div>
            <div class="slate-sub">Runs executables directly from <code>/mnt/sdcard/Games</code> with working directories preserved.</div>
          </div>
          <span class="xbox-tag">ACTIVE</span>
        </div>
      </div>
    `;
  } else {
    pane.innerHTML = `
      <div class="xbox-slate-card ${!state.settingsFocusSide ? "focused" : ""}">
        <div class="slate-row">
          <div>
            <div class="slate-title">${state.system.model || "Valve Steam Deck (Jupiter)"}</div>
            <div class="slate-sub">AMD Custom APU 0405  •  16 GB LPDDR5  •  Anvil Console OS v3.5 (Xbox Series X Shell)</div>
          </div>
          <span class="xbox-tag green">ONLINE</span>
        </div>
      </div>
    `;
  }
}

function getGuideItems() {
  const items = [];
  if (state.gameRunning) {
    items.push({ label: `▶ Resume ${state.activeGameName || "Game"}`, badge: "IN-GAME", action: () => resumeGameSession() });
    items.push({ label: "✕ Quit Game to Dashboard", badge: "STOP", action: () => quitGameSession() });
  }
  items.push(
    { label: "Home", badge: "DASHBOARD", action: () => { closeGuideBlade(); switchTab(0); } },
    { label: `My games & apps (${state.games.length})`, badge: "LIBRARY", action: () => { closeGuideBlade(); switchTab(1); } },
    { label: "Make a Drive / SD Card into Cartridge", badge: "BUILDER", action: () => { closeGuideBlade(); openCartridgeModal(); } },
    { label: "Controller & Zero-Drift Status", badge: "4000DZ", action: () => { closeGuideBlade(); switchTab(3); selectSettingCat(1); } },
    { label: "Settings", badge: "SYSTEM", action: () => { closeGuideBlade(); switchTab(3); selectSettingCat(0); } },
    { label: "Sleep Console", badge: "SUSPEND", action: () => { closeGuideBlade(); triggerPower("sleep"); } },
    { label: "Switch to Desktop Mode", badge: "EXIT", action: () => { closeGuideBlade(); triggerPower("desktop"); } },
    { label: "Restart Console", badge: "REBOOT", action: () => { closeGuideBlade(); triggerPower("restart"); } },
    { label: "Shut Down Console", badge: "OFF", action: () => { closeGuideBlade(); triggerPower("shutdown"); } }
  );
  return items;
}

function renderGuideMenu() {
  const list = document.getElementById("guide-menu-list");
  if (!list) return;
  const items = getGuideItems();
  state.guideIdx = Math.max(0, Math.min(items.length - 1, state.guideIdx));
  list.innerHTML = items
    .map(
      (item, idx) => `
    <div class="guide-item ${idx === state.guideIdx ? "selected" : ""}" id="guide-item-${idx}">
      <span>${item.label}</span>
      <span class="xbox-tag ${idx === 0 && state.gameRunning ? "green" : ""}">${item.badge}</span>
    </div>
  `
    )
    .join("");
  items.forEach((item, idx) => {
    const el = document.getElementById(`guide-item-${idx}`);
    if (el) el.onclick = item.action;
  });
}

function toggleGuideBlade() {
  state.guideOpen = !state.guideOpen;
  state.guideIdx = 0;
  renderGuideMenu();
  const blade = document.getElementById("xbox-guide");
  const bg = document.getElementById("guide-backdrop");
  if (blade) blade.classList.toggle("open", state.guideOpen);
  if (bg) bg.classList.toggle("open", state.guideOpen);
}

function closeGuideBlade() {
  state.guideOpen = false;
  const blade = document.getElementById("xbox-guide");
  const bg = document.getElementById("guide-backdrop");
  if (blade) blade.classList.remove("open");
  if (bg) bg.classList.remove("open");
}

function renderCartridgeModalOptions() {
  const container = document.getElementById("modal-drive-options");
  if (!container) return;
  container.innerHTML = state.cartridgeTargets
    .map(
      (t, idx) => `
    <div class="modal-opt ${idx === state.cartridgeModalIdx ? "selected" : ""}" onclick="initializeCartridgeTarget(${idx})">
      <div>
        <div style="font-size:15px; font-weight:700;">${t.label}</div>
        <div style="font-size:12px; color:var(--text-secondary); margin-top:2px;">Initializes <code>${t.path}/Games</code> and <code>${t.path}/cartridge.meta</code></div>
      </div>
      <span class="xbox-tag ${idx === 0 ? "green" : ""}">${t.badge}</span>
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
        banner.style.color = "#22c55e";
      }
      renderSettingsPane();
      renderHomeShelf();
      renderLibraryGrid();
    } else if (banner) {
      banner.textContent = `Error: ${data.error || "Failed to initialize cartridge"}`;
      banner.style.color = "#f87171";
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
  closeGuideBlade();
  await fetch("/api/resume", { method: "POST" });
}

async function quitGameSession() {
  closeGuideBlade();
  await fetch("/api/kill", { method: "POST" });
}

window.onAnvilGameState = function (running, gameName) {
  state.gameRunning = !!running;
  state.activeGameName = gameName || "";
  if (!running) {
    closeGuideBlade();
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

  // Live controller input test in Settings
  if (state.tab === 3 && state.settingsCat === 1) {
    document.querySelectorAll(".pad-key").forEach((el) => el.classList.remove("pressed"));
    const keyEl = document.getElementById(`pad-key-${state.lastButton}`);
    if (keyEl) keyEl.classList.add("pressed");
    const lbl = document.getElementById("last-btn-label");
    if (lbl) lbl.textContent = `LAST INPUT: ${state.lastButton}`;
  }

  // 1. In-Game Guide Blade handling (ONLY when a game is running)
  if (state.gameRunning) {
    if (action === "guide") {
      toggleGuideBlade();
      return;
    }
    if (state.guideOpen) {
      const items = getGuideItems();
      if (action === "up") {
        state.guideIdx = (state.guideIdx + items.length - 1) % items.length;
        renderGuideMenu();
      } else if (action === "down") {
        state.guideIdx = (state.guideIdx + 1) % items.length;
        renderGuideMenu();
      } else if (action === "south") {
        items[state.guideIdx]?.action();
      } else if (action === "east") {
        resumeGameSession();
      }
    }
    return;
  }

  // 2. Xbox Guide Blade handling (when on Dashboard)
  if (state.guideOpen) {
    const items = getGuideItems();
    if (action === "up") {
      state.guideIdx = (state.guideIdx + items.length - 1) % items.length;
      renderGuideMenu();
    } else if (action === "down") {
      state.guideIdx = (state.guideIdx + 1) % items.length;
      renderGuideMenu();
    } else if (action === "south") {
      items[state.guideIdx]?.action();
    } else if (action === "east" || action === "select") {
      closeGuideBlade();
    }
    return;
  }

  // 3. Power Modal handling
  if (state.powerModalOpen) {
    const actions = ["sleep", "desktop", "restart", "shutdown", "cancel"];
    if (action === "up") {
      state.powerModalIdx = (state.powerModalIdx + actions.length - 1) % actions.length;
    } else if (action === "down") {
      state.powerModalIdx = (state.powerModalIdx + 1) % actions.length;
    } else if (action === "south") {
      const chosen = actions[state.powerModalIdx];
      if (chosen === "cancel") togglePowerModal();
      else triggerPower(chosen);
      return;
    } else if (action === "east" || action === "start") {
      togglePowerModal();
      return;
    }
    document.querySelectorAll("#power-modal .modal-opt").forEach((el, idx) => {
      el.classList.toggle("selected", idx === state.powerModalIdx);
    });
    return;
  }

  // 4. Cartridge Builder Modal handling
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

  // 5. Global Dashboard Shortcuts
  if (action === "select") {
    toggleGuideBlade();
    return;
  }
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
  if (action === "west") {
    openCartridgeModal();
    return;
  }
  if (action === "north") {
    switchTab(1);
    return;
  }
  if (action === "east" && state.tab !== 0) {
    switchTab(0);
    return;
  }

  // 6. Page-Specific Controller Navigation
  if (state.tab === 0) {
    if (state.homeZone === "shelf") {
      if (action === "left") selectGame(state.selectedIndex - 1);
      else if (action === "right") selectGame(state.selectedIndex + 1);
      else if (action === "up") {
        state.homeZone = "top";
        syncHomeFocusVisuals();
      } else if (action === "down") {
        state.homeZone = "quick";
        syncHomeFocusVisuals();
      } else if (action === "south") {
        launchSelectedGame();
      }
    } else if (state.homeZone === "top") {
      if (action === "left") {
        state.topNavIdx = Math.max(0, state.topNavIdx - 1);
        syncHomeFocusVisuals();
      } else if (action === "right") {
        state.topNavIdx = Math.min(4, state.topNavIdx + 1);
        syncHomeFocusVisuals();
      } else if (action === "down" || action === "east") {
        state.homeZone = "shelf";
        syncHomeFocusVisuals();
      } else if (action === "south") {
        activateTopNav(state.topNavIdx);
      }
    } else if (state.homeZone === "quick") {
      if (action === "left") {
        state.quickIdx = Math.max(0, state.quickIdx - 1);
        syncHomeFocusVisuals();
      } else if (action === "right") {
        state.quickIdx = Math.min(3, state.quickIdx + 1);
        syncHomeFocusVisuals();
      } else if (action === "up" || action === "east") {
        state.homeZone = "shelf";
        syncHomeFocusVisuals();
      } else if (action === "south") {
        triggerQuickCard(state.quickIdx);
      }
    }
  } else if (state.tab === 1) {
    if (action === "left") selectGame(state.selectedIndex - 1);
    else if (action === "right") selectGame(state.selectedIndex + 1);
    else if (action === "up") selectGame(state.selectedIndex - 5);
    else if (action === "down") selectGame(state.selectedIndex + 5);
    else if (action === "south") launchSelectedGame();
  } else if (state.tab === 3) {
    if (state.settingsFocusSide) {
      if (action === "up") selectSettingCat(state.settingsCat - 1);
      else if (action === "down") selectSettingCat(state.settingsCat + 1);
      else if (action === "right" || action === "south") {
        state.settingsFocusSide = false;
        state.settingsRightIdx = 0;
        renderSettingsPane();
      }
    } else {
      const maxRight = state.settingsCat === 0 ? state.drives.length : 0;
      if (action === "left" || action === "east") {
        state.settingsFocusSide = true;
        renderSettingsPane();
      } else if (action === "up") {
        state.settingsRightIdx = Math.max(0, state.settingsRightIdx - 1);
        renderSettingsPane();
      } else if (action === "down") {
        state.settingsRightIdx = Math.min(maxRight, state.settingsRightIdx + 1);
        renderSettingsPane();
      } else if (action === "south" && state.settingsCat === 0) {
        openCartridgeModal();
      }
    }
  } else {
    if (action === "south") launchSelectedGame();
  }
};

window.addEventListener("keydown", (e) => {
  const map = {
    ArrowLeft: "left",
    ArrowRight: "right",
    ArrowUp: "up",
    ArrowDown: "down",
    Enter: "south",
    Escape: "east",
    Backspace: "east",
    Tab: "select",
    "[": "lb",
    "]": "rb",
    x: "west",
    X: "west",
    y: "north",
    Y: "north"
  };
  if (map[e.key]) {
    e.preventDefault();
    window.onAnvilInput(map[e.key], "keyboard", "Keyboard");
  }
});

window.addEventListener("DOMContentLoaded", loadState);
