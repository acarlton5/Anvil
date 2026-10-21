// Anvil Console OS v5.0 — SteamOS 3.6 + Xbox Series X Flagship Dashboard Frontend
const state = {
  tab: 0, // 0: Home, 1: Library, 2: Store, 3: Cartridges, 4: Settings
  homeZone: "shelf", // "top" | "shelf" | "quick"
  topNavIdx: 0,
  quickIdx: 0,
  storeIdx: 0,
  cartPageIdx: 0,
  games: [],
  drives: [],
  battery: { percent: 100, charging: false },
  system: {},
  network: { connected: true, ssid: "SteamDeck-5GHz", ip: "192.168.1.100", tailscale_ip: "100.101.162.75", hostname: "steamdeck" },
  update: { version: "5.0.0", build: "20261017.8", channel: "Stable (Recommended)", up_to_date: true, last_checked: "Just now", changelog: [] },
  selectedIndex: 0,
  settingsCat: 0, // 0: Updates, 1: Audio & Volume, 2: Display, 3: Network, 4: Storage & Cartridges, 5: Controller, 6: Proton & System
  settingsRightIdx: 0,
  settingsFocusSide: true,
  guideOpen: false,
  guideIdx: 0,
  qamOpen: false,
  qamIdx: 0,
  volumePct: 75,
  volumeMuted: false,
  micPct: 80,
  micMuted: false,
  sinkName: "Steam Deck Speakers (acp5x)",
  uiSounds: true,
  autoUpdates: true,
  vrrEnabled: true,
  wifiEnabled: true,
  rumbleEnabled: true,
  brightnessPct: 85,
  nightMode: false,
  updateModalOpen: false,
  updateChecking: false,
  updateChannelIdx: 0,
  cartridgeModalOpen: false,
  cartridgeModalIdx: 0,
  powerModalOpen: false,
  powerModalIdx: 0,
  gameRunning: false,
  activeGameName: "",
  lastButton: "NONE",
  controllerName: "Microsoft X-Box 360 pad (Player 1)",
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

// Double-buffered Hero Backdrop State + Preloader Cache
let activeBackdropSlot = "a";
let currentBackdropUrl = "";
const preloadedHeroUrls = new Set();

function preloadHeroImage(url) {
  if (!url || preloadedHeroUrls.has(url)) return;
  preloadedHeroUrls.add(url);
  const img = new Image();
  img.decoding = "async";
  img.src = url;
}

function setHeroBackdropSmooth(url) {
  if (!url || url === currentBackdropUrl) return;
  currentBackdropUrl = url;

  const layerA = document.getElementById("backdrop-layer-a");
  const layerB = document.getElementById("backdrop-layer-b");
  if (!layerA || !layerB) return;

  const img = new Image();
  img.decoding = "async";
  img.onload = () => {
    if (currentBackdropUrl !== url) return;
    const nextLayer = activeBackdropSlot === "a" ? layerB : layerA;
    const prevLayer = activeBackdropSlot === "a" ? layerA : layerB;
    nextLayer.style.backgroundImage = `url("${url}")`;
    nextLayer.classList.add("active");
    prevLayer.classList.remove("active");
    activeBackdropSlot = activeBackdropSlot === "a" ? "b" : "a";
  };
  img.src = url;
}

// Web Audio API Synthesizer for Subtle Console UI Navigation Sounds
let audioCtx = null;
function playUiSound(type = "tick") {
  if (!state.uiSounds) return;
  try {
    if (!audioCtx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      audioCtx = new AC();
    }
    if (audioCtx.state === "suspended") audioCtx.resume();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    const now = audioCtx.currentTime;

    if (type === "tick") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(360, now);
      osc.frequency.exponentialRampToValueAtTime(520, now + 0.032);
      gain.gain.setValueAtTime(0.035, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.038);
    } else if (type === "confirm") {
      osc.type = "triangle";
      osc.frequency.setValueAtTime(480, now);
      osc.frequency.exponentialRampToValueAtTime(760, now + 0.075);
      gain.gain.setValueAtTime(0.06, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.085);
    } else if (type === "back") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(270, now + 0.065);
      gain.gain.setValueAtTime(0.045, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.075);
    } else if (type === "tab") {
      osc.type = "sine";
      osc.frequency.setValueAtTime(580, now);
      osc.frequency.exponentialRampToValueAtTime(660, now + 0.045);
      gain.gain.setValueAtTime(0.04, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + 0.055);
    }
  } catch (e) {}
}

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

function syncTopStatusBar() {
  const topVol = document.getElementById("top-vol-text");
  if (topVol) {
    topVol.textContent = state.volumeMuted ? "MUTED" : `${state.volumePct}%`;
  }
  const quickVolSub = document.getElementById("quick-vol-sub");
  if (quickVolSub) {
    const outType = state.sinkName.toLowerCase().includes("headphone") ? "Headphones" : "Speakers";
    quickVolSub.textContent = `${state.volumeMuted ? "Muted" : state.volumePct + "%"} • ${outType} • ${state.brightnessPct}% Bright`;
  }
  const batFill = document.getElementById("battery-fill");
  const batText = document.getElementById("battery-text");
  const qamBat = document.getElementById("qam-battery-label");
  if (batFill) batFill.style.width = `${Math.max(8, Math.min(100, state.battery.percent))}%`;
  if (batText) batText.textContent = `${state.battery.percent}%`;
  if (qamBat) qamBat.textContent = `${state.battery.percent}%${state.battery.charging ? " CHG" : ""}`;
}

async function loadState() {
  try {
    const res = await fetch("/api/state");
    const data = await res.json();
    state.games = data.games || [];
    state.drives = data.drives || [];
    state.battery = data.battery || { percent: 100, charging: false };
    state.system = data.system || {};
    state.network = data.network || state.network;
    state.update = data.update || state.update;
    state.gameRunning = !!data.game_running;
    if (data.volume) {
      state.volumePct = data.volume.percent ?? 75;
      state.volumeMuted = !!data.volume.muted;
      state.micPct = data.volume.mic_percent ?? 80;
      state.micMuted = !!data.volume.mic_muted;
      state.sinkName = data.volume.sink_name || state.sinkName;
    }
    if (data.brightness) {
      state.brightnessPct = data.brightness.percent ?? 85;
    }

    const count = state.games.length;
    const topCart = document.getElementById("top-cart-count");
    if (topCart) topCart.textContent = `${count} Cartridges`;
    const quickSub = document.getElementById("quick-lib-sub");
    if (quickSub) quickSub.textContent = `See all ${count} cartridges`;
    const libSideCount = document.getElementById("lib-side-count");
    if (libSideCount) libSideCount.textContent = `${count}`;

    syncTopStatusBar();
    renderHomeShelf();
    renderLibraryGrid();
    updateSelectedGameHero();
    renderCartridgesPage();
    renderSettingsPane();
    renderGuideMenu();
    renderCartridgeModalOptions();
    syncHomeFocusVisuals();

    // Preload the first 8 games' hero art into WebKit memory immediately
    state.games.slice(0, 8).forEach((g) => {
      preloadHeroImage(artUrl(g.hero || g.grid || g.cover));
    });
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
      img.decoding = "async";
      img.loading = idx < 10 ? "eager" : "lazy";
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
      <span style="font-size:10px; color:#94a3b8; font-weight:700;">SD</span>
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
      img.decoding = "async";
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
  document.querySelectorAll("#xbox-top-nav .nav-pill").forEach((el, idx) => {
    el.classList.toggle("focused", state.tab === 0 && state.homeZone === "top" && idx === state.topNavIdx);
  });

  document.querySelectorAll("#home-carousel .xbox-tile").forEach((el, idx) => {
    el.classList.toggle("focused", state.homeZone === "shelf" && idx === state.selectedIndex);
  });

  document.querySelectorAll("#xbox-quick-row .xbox-quick-card").forEach((el, idx) => {
    el.classList.toggle("focused", state.homeZone === "quick" && idx === state.quickIdx);
  });
}

function syncStoreFocusVisuals() {
  for (let i = 0; i < 5; i++) {
    const el = document.getElementById(`store-card-${i}`);
    if (el) el.classList.toggle("focused", i === state.storeIdx);
  }
}

function selectGameByName(partial) {
  const idx = state.games.findIndex((g) => (g.name || "").toLowerCase().includes(partial.toLowerCase()));
  if (idx >= 0) {
    selectGame(idx);
    switchTab(0);
  }
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

  // Preload neighbor hero images (-2 to +3) for instant 0ms D-Pad scrolling
  for (let offset = -2; offset <= 3; offset++) {
    const neighbor = state.games[state.selectedIndex + offset];
    if (neighbor) {
      preloadHeroImage(artUrl(neighbor.hero || neighbor.grid || neighbor.cover));
    }
  }

  updateSelectedGameHero();
}

function updateSelectedGameHero() {
  const g = state.games[state.selectedIndex];
  if (!g) return;

  const heroSrc = artUrl(g.hero || g.grid || g.cover);
  const logoSrc = artUrl(g.logo);

  if (heroSrc) {
    setHeroBackdropSmooth(heroSrc);
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
    protonBadge.textContent = (g.proton || g.runner || "GE-PROTON11-9").toUpperCase();
  }

  const driveBadge = document.getElementById("home-drive-badge");
  if (driveBadge) {
    driveBadge.textContent = (g.path || "").includes("/mnt/sdcard")
      ? "MICROSD CARTRIDGE"
      : "EXTERNAL CARTRIDGE";
  }

  const counter = document.getElementById("home-index-counter");
  if (counter) {
    counter.textContent = `CARTRIDGE ${state.selectedIndex + 1} OF ${state.games.length}`;
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

function triggerQuickCard(idx) {
  playUiSound("confirm");
  if (idx === 0) switchTab(1);
  else if (idx === 1) switchTab(3);
  else if (idx === 2) {
    switchTab(4);
    selectSettingCat(1);
    state.settingsFocusSide = false;
    renderSettingsPane();
  } else if (idx === 3) {
    openUpdateModal();
  }
}

function switchTab(newTab) {
  closeCartridgeModal();
  closeUpdateModal();
  closeGuideBlade();
  closeQamSidebar();
  if (state.powerModalOpen) togglePowerModal();

  const count = 5;
  state.tab = ((newTab % count) + count) % count;
  state.topNavIdx = state.tab;
  playUiSound("tab");

  document.body.classList.toggle("subpage", state.tab !== 0);

  document.querySelectorAll("#xbox-top-nav .nav-pill").forEach((el, idx) => {
    el.classList.toggle("active", idx === state.tab);
    el.classList.remove("focused");
  });

  const pages = ["page-home", "page-library", "page-store", "page-cartridges", "page-settings"];
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
  } else if (state.tab === 2) {
    state.storeIdx = 0;
    syncStoreFocusVisuals();
  } else if (state.tab === 3) {
    state.cartPageIdx = 0;
    renderCartridgesPage();
  } else if (state.tab === 4) {
    state.settingsFocusSide = true;
    renderSettingsPane();
  }
}

function renderCartridgesPage() {
  const container = document.getElementById("cartridges-page-list");
  if (!container) return;

  const drivesHtml = state.drives
    .map(
      (d, idx) => `
    <div class="xbox-slate-card ${state.cartPageIdx === idx + 1 ? "focused" : ""}" onclick="openCartridgeModal()">
      <div class="slate-row">
        <div>
          <div class="slate-title">${d.name} <span style="font-size:12px; color:var(--text-secondary); font-weight:600;">(${d.path})</span></div>
          <div class="slate-sub">
            ${d.mounted ? `${d.used_gb} GB used of ${d.total_gb} GB (${d.free_gb} GB free)` : "Slot Ready — Insert USB Drive to Mount"}
            ${d.game_count > 0 ? `  •  <strong style="color:#22c55e;">${d.game_count} Cartridge Games Mounted</strong>` : ""}
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

  container.innerHTML = `
    <div class="xbox-slate-card ${state.cartPageIdx === 0 ? "focused" : ""}" onclick="openCartridgeModal()">
      <div class="slate-row">
        <div>
          <span class="xbox-tag ember" style="margin-bottom:6px; display:inline-block;">CARTRIDGE PROVISIONER</span>
          <div class="slate-title">Make a Drive, SD Card, or Folder into an Anvil Cartridge</div>
          <div class="slate-sub">Initializes <code>Games/</code> + <code>cartridge.meta</code> on any removable drive or folder and registers it in Anvil OS without touching internal storage.</div>
        </div>
        <button class="xbox-btn"><span class="a-btn-mini">A</span><span>Initialize Drive</span></button>
      </div>
    </div>
    ${drivesHtml}
  `;
}

/* =================================================
   AUTHENTIC STEAMOS 3.6 + CONSOLE SETTINGS PANEL
   ================================================= */
function selectSettingCat(catIdx) {
  state.settingsCat = Math.max(0, Math.min(6, catIdx));
  state.settingsRightIdx = 0;
  renderSettingsPane();
}

function toggleNightMode() {
  state.nightMode = !state.nightMode;
  document.body.classList.toggle("night-mode", state.nightMode);
  renderSettingsPane();
}

function getSettingsRightItemsCount() {
  if (state.settingsCat === 0) return 4; // Software Update, Update Channel, Auto-Update Toggle, Release Notes
  if (state.settingsCat === 1) return 4; // Master Vol, Output Sink, Mic Gain, UI Sounds Toggle
  if (state.settingsCat === 2) return 4; // Brightness Slider, Night Mode Toggle, VRR Toggle, Fullscreen Scaling
  if (state.settingsCat === 3) return 3; // Wi-Fi Toggle, Connected SSID/IP, Tailscale VPN
  if (state.settingsCat === 4) return 1 + state.drives.length; // Cartridge Builder + Drives
  if (state.settingsCat === 5) return 3; // Xbox 360 Bridge, Haptics Toggle, 16-Button Matrix
  return 3; // Proton Runner, Zero-Copy Mode, Hardware Specs
}

function handleSettingsRightAction(action) {
  const cat = state.settingsCat;
  const idx = state.settingsRightIdx;

  // Category 0: System & Updates
  if (cat === 0) {
    if (idx === 0 && action === "south") {
      openUpdateModal();
    } else if (idx === 1 && (action === "left" || action === "right" || action === "south")) {
      const channels = ["Stable (Recommended)", "Preview / Beta", "Developer Mainline"];
      state.updateChannelIdx = (state.updateChannelIdx + (action === "left" ? channels.length - 1 : 1)) % channels.length;
      state.update.channel = channels[state.updateChannelIdx];
      renderSettingsPane();
    } else if (idx === 2 && (action === "left" || action === "right" || action === "south")) {
      state.autoUpdates = !state.autoUpdates;
      renderSettingsPane();
    } else if (idx === 3 && action === "south") {
      openUpdateModal();
    }
    return;
  }

  // Category 1: Audio & Volume
  if (cat === 1) {
    if (idx === 0) {
      if (action === "left") adjustVolume("down");
      else if (action === "right") adjustVolume("up");
      else if (action === "south") adjustVolume("mute");
    } else if (idx === 1) {
      if (action === "left" || action === "right" || action === "south") {
        adjustVolume("cycle-sink");
      }
    } else if (idx === 2) {
      if (action === "left") adjustVolume("mic-down");
      else if (action === "right") adjustVolume("mic-up");
      else if (action === "south") adjustVolume("mic-mute");
    } else if (idx === 3) {
      if (action === "left" || action === "right" || action === "south") {
        state.uiSounds = !state.uiSounds;
        if (state.uiSounds) playUiSound("confirm");
        renderSettingsPane();
      }
    }
    return;
  }

  // Category 2: Display & Brightness
  if (cat === 2) {
    if (idx === 0) {
      if (action === "left") adjustBrightness("down");
      else if (action === "right" || action === "south") adjustBrightness("up");
    } else if (idx === 1) {
      if (action === "left" || action === "right" || action === "south") {
        toggleNightMode();
      }
    } else if (idx === 2) {
      if (action === "left" || action === "right" || action === "south") {
        state.vrrEnabled = !state.vrrEnabled;
        renderSettingsPane();
      }
    }
    return;
  }

  // Category 3: Internet & Wi-Fi
  if (cat === 3) {
    if (idx === 0 && (action === "left" || action === "right" || action === "south")) {
      state.wifiEnabled = !state.wifiEnabled;
      renderSettingsPane();
    }
    return;
  }

  // Category 4: Storage & Cartridges
  if (cat === 4 && action === "south") {
    openCartridgeModal();
    return;
  }

  // Category 5: Controller & Input
  if (cat === 5 && idx === 1 && (action === "left" || action === "right" || action === "south")) {
    state.rumbleEnabled = !state.rumbleEnabled;
    renderSettingsPane();
  }
}

function renderSettingsPane() {
  const pane = document.getElementById("settings-detail-pane");
  if (!pane) return;

  document.querySelectorAll("#settings-cat-list .steamos-cat-btn").forEach((el, i) => {
    el.classList.toggle("active", i === state.settingsCat);
    el.classList.toggle("focused", state.settingsFocusSide && i === state.settingsCat);
  });

  const f = (idx) => (!state.settingsFocusSide && state.settingsRightIdx === idx ? "focused" : "");

  // 0: SYSTEM & UPDATES
  if (state.settingsCat === 0) {
    const upd = state.update || {};
    const count = upd.pending_count || (upd.packages ? upd.packages.length : 0);
    const isUpgrading = upd.phase === "upgrading";
    const isChecking = upd.phase === "refreshing" || state.updateChecking;
    const tagText = isUpgrading ? `${Math.round(upd.progress || 0)}% UPDATING` : isChecking ? "CHECKING" : count > 0 ? `${count} PENDING` : "UP TO DATE";
    const tagClass = isUpgrading ? "" : isChecking ? "" : count > 0 ? "" : "green";

    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>ANVIL CONSOLE OS 5.0</p>
          <h2>System & Software Updates</h2>
        </div>
        <span class="xbox-tag ${tagClass}">${tagText}</span>
      </div>

      <div class="console-setting-row ${f(0)}" onclick="openUpdateModal()">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>${isUpgrading ? (upd.status_step || "Applying System Updates...") : count > 0 ? `${count} Updates Available` : "System is Up to Date"}</strong>
            <small>Connected to HypeShell Core  •  Last checked: ${upd.last_checked || "Just now"}</small>
          </div>
          <button class="xbox-btn"><span class="a-btn-mini">A</span><span>${isUpgrading ? "View Progress" : count > 0 ? "Review & Update" : "Check for Updates"}</span></button>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}" onclick="handleSettingsRightAction('south')">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>OS Update Channel</strong>
            <small>Select the SteamOS & Anvil release track (use ◀ / ▶ or A to cycle)</small>
          </div>
          <span class="settings-pill-value cyan">◀  ${state.update.channel || "Stable (Recommended)"}  ▶</span>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}" onclick="state.autoUpdates = !state.autoUpdates; renderSettingsPane();">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Automatic Background Updates</strong>
            <small>Automatically download OS patches and Proton runtime updates while idle</small>
          </div>
          <div class="steamos-toggle ${state.autoUpdates ? "on" : ""}"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(3)}" onclick="openUpdateModal()">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Anvil OS 5.0 Patch Notes & Changelog</strong>
            <small>Zero-lag RAM-cached Hero art (/dev/shm/anvil-art), SteamOS 3.6 Settings Panel, and Full-Height Quick Drawers</small>
          </div>
          <span class="settings-pill-value">View Notes ›</span>
        </div>
      </div>
    `;
  }
  // 1: AUDIO & VOLUME
  else if (state.settingsCat === 1) {
    const volPct = state.volumeMuted ? 0 : state.volumePct;
    const micPct = state.micMuted ? 0 : state.micPct;
    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>PIPEWIRE SOUND SERVER</p>
          <h2>Audio & Volume Mixer</h2>
        </div>
        <span class="xbox-tag ${state.volumeMuted ? "" : "green"}">${state.volumeMuted ? "MUTED" : state.volumePct + "% MASTER"}</span>
      </div>

      <div class="console-setting-row ${f(0)}" onclick="adjustVolume('mute')">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Master Output Volume ${state.volumeMuted ? '<span style="color:#f87171;">(MUTED)</span>' : ""}</strong>
            <small>Use D-Pad ◀ / ▶ to adjust volume level, or press A to toggle mute</small>
          </div>
          <span class="settings-pill-value ${state.volumeMuted ? "" : "green"}">${state.volumeMuted ? "MUTED" : `${state.volumePct}%`}</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill" style="width:${volPct}%;"></div>
          <div class="slider-thumb" style="left:${volPct}%;"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}" onclick="adjustVolume('cycle-sink')">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Output Device (PipeWire Sink)</strong>
            <small>Switch between Steam Deck Speakers (acp5x), 3.5mm Headphones, and HDMI/DisplayPort Audio</small>
          </div>
          <span class="settings-pill-value cyan">◀  ${state.sinkName}  ▶</span>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}" onclick="adjustVolume('mic-mute')">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Microphone Input Gain ${state.micMuted ? '<span style="color:#f87171;">(MUTED)</span>' : ""}</strong>
            <small>Use D-Pad ◀ / ▶ to adjust voice chat microphone gain, or press A to mute mic</small>
          </div>
          <span class="settings-pill-value ${state.micMuted ? "" : "cyan"}">${state.micMuted ? "MIC MUTED" : `${state.micPct}%`}</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill cyan" style="width:${micPct}%;"></div>
          <div class="slider-thumb cyan" style="left:${micPct}%;"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(3)}" onclick="state.uiSounds = !state.uiSounds; renderSettingsPane();">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Console UI Navigation Sounds</strong>
            <small>Play tactile acoustic feedback when moving across cartridges, bumpers, and menus</small>
          </div>
          <div class="steamos-toggle ${state.uiSounds ? "on" : ""}"></div>
        </div>
      </div>
    `;
  }
  // 2: DISPLAY & BRIGHTNESS
  else if (state.settingsCat === 2) {
    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>STEAM DECK DISPLAY</p>
          <h2>Picture, Brightness & Motion</h2>
        </div>
        <span class="xbox-tag green">1280×800 60HZ</span>
      </div>

      <div class="console-setting-row ${f(0)}" onclick="adjustBrightness('up')">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Display Backlight Brightness</strong>
            <small>Use D-Pad ◀ / ▶ to adjust Steam Deck panel backlight (amdgpu_bl0)</small>
          </div>
          <span class="settings-pill-value cyan">${state.brightnessPct}%</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill cyan" style="width:${state.brightnessPct}%;"></div>
          <div class="slider-thumb cyan" style="left:${state.brightnessPct}%;"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}" onclick="toggleNightMode()">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Night Mode (Warm Amber Eye-Care Tint)</strong>
            <small>Reduce blue light emission for comfortable late-night handheld play</small>
          </div>
          <div class="steamos-toggle ${state.nightMode ? "on" : ""}"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}" onclick="state.vrrEnabled = !state.vrrEnabled; renderSettingsPane();">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Variable Refresh Rate (VRR) & 60 Hz Lock</strong>
            <small>Eliminate screen tearing and maintain smooth frame pacing across all cartridges</small>
          </div>
          <div class="steamos-toggle ${state.vrrEnabled ? "on" : ""}"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(3)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Workspace 2 Fullscreen Game Windowing</strong>
            <small>Automatically isolates launched Unity, Unreal, and Proton games on Workspace 2 at 1280×800</small>
          </div>
          <span class="settings-pill-value green">ACTIVE</span>
        </div>
      </div>
    `;
  }
  // 3: INTERNET & WI-FI
  else if (state.settingsCat === 3) {
    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>NETWORK INTERFACES</p>
          <h2>Internet, Wi-Fi & Tailscale</h2>
        </div>
        <span class="xbox-tag green">${state.network.connected ? "ONLINE" : "OFFLINE"}</span>
      </div>

      <div class="console-setting-row ${f(0)}" onclick="state.wifiEnabled = !state.wifiEnabled; renderSettingsPane();">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Wi-Fi Radio (802.11ax 5GHz)</strong>
            <small>Enable wireless networking and local LAN discovery</small>
          </div>
          <div class="steamos-toggle ${state.wifiEnabled ? "on" : ""}"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Connected Network: ${state.network.ssid || "Wireless LAN"}</strong>
            <small>Local IPv4: <code>${state.network.ip || "192.168.1.100"}</code>  •  Hostname: <code>${state.network.hostname || "steamdeck"}</code></small>
          </div>
          <span class="settings-pill-value green">CONNECTED</span>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Tailscale Mesh VPN & Remote DevBox Link</strong>
            <small>Tailscale IPv4: <code>${state.network.tailscale_ip || "100.101.162.75"}</code>  •  Encrypted Console Link Active</small>
          </div>
          <span class="settings-pill-value cyan">100.101.162.75</span>
        </div>
      </div>
    `;
  }
  // 4: STORAGE & CARTRIDGES
  else if (state.settingsCat === 4) {
    const drivesHtml = state.drives
      .map(
        (d, idx) => `
      <div class="console-setting-row ${f(idx + 1)}" onclick="openCartridgeModal()">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>${d.name} <span style="font-size:12px; color:#94a3b8; font-weight:600;">(${d.path})</span></strong>
            <small>
              ${d.mounted ? `${d.used_gb} GB used of ${d.total_gb} GB (${d.free_gb} GB free)` : "Slot Ready — Insert USB Drive to Mount"}
              ${d.game_count > 0 ? `  •  <span style="color:#4ade80; font-weight:700;">${d.game_count} Cartridge Games Mounted</span>` : ""}
            </small>
          </div>
          <span class="settings-pill-value ${d.id === "sdcard" ? "green" : ""}">${d.role}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill" style="width:${d.percent || 3}%;"></div>
        </div>
      </div>
    `
      )
      .join("");

    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>ZERO-COPY CARTRIDGE ENGINE</p>
          <h2>Storage & Cartridge Provisioner</h2>
        </div>
        <span class="xbox-tag green">${state.games.length} CARTRIDGES</span>
      </div>

      <div class="console-setting-row ${f(0)}" onclick="openCartridgeModal()">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Make a Drive, SD Card, or Folder into an Anvil Cartridge</strong>
            <small>Initializes <code>Games/</code> + <code>cartridge.meta</code> on any removable media without touching internal SSD</small>
          </div>
          <button class="xbox-btn"><span class="a-btn-mini">A</span><span>Configure Drive</span></button>
        </div>
      </div>
      ${drivesHtml}
    `;
  }
  // 5: CONTROLLER & INPUT
  else if (state.settingsCat === 5) {
    const buttons = ["A", "B", "X", "Y", "LB", "RB", "LT", "RT", "UP", "DOWN", "LEFT", "RIGHT", "SELECT", "START", "GUIDE", "QAM"];
    const matrixHtml = buttons
      .map((b) => `<div class="pad-key ${state.lastButton === b ? "pressed" : ""}" id="pad-key-${b}">${b}</div>`)
      .join("");

    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>XINPUT SLOT 0 EXCLUSIVE</p>
          <h2>Controller, Deadzone & Diagnostics</h2>
        </div>
        <span class="xbox-tag green">PLAYER 1 LOCKED</span>
      </div>

      <div class="console-setting-row ${f(0)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Player 1 Exclusive Xbox 360 Bridge & Zero-Drift Filter</strong>
            <small>Locks <code>Microsoft X-Box 360 pad</code> as Slot 0, hides Lizard Mode HID/Gyro, and enforces <strong>4000</strong> deadzone</small>
          </div>
          <span class="settings-pill-value green">4000 DEADZONE</span>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}" onclick="state.rumbleEnabled = !state.rumbleEnabled; renderSettingsPane();">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Steam Deck Haptics & Game Rumble</strong>
            <small>Allow games and Anvil Console OS to use force-feedback vibration</small>
          </div>
          <div class="steamos-toggle ${state.rumbleEnabled ? "on" : ""}"></div>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}">
        <div class="console-setting-top">
          <span style="font-size:12px; font-weight:800; color:#94a3b8;">LIVE 16-BUTTON CONTROLLER DIAGNOSTIC MATRIX</span>
          <span style="font-size:12px; font-weight:800; color:#4ade80;" id="last-btn-label">LAST INPUT: ${state.lastButton}</span>
        </div>
        <div class="pad-matrix">${matrixHtml}</div>
      </div>
    `;
  }
  // 6: PROTON & HARDWARE
  else {
    pane.innerHTML = `
      <div class="settings-detail-head">
        <div>
          <p>VALVE STEAM DECK (JUPITER)</p>
          <h2>Proton Runtime & System Specs</h2>
        </div>
        <span class="xbox-tag green">GE-PROTON11-9</span>
      </div>

      <div class="console-setting-row ${f(0)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Default Proton Compatibility Layer</strong>
            <small>GE-Proton11-9 & Proton Experimental with Goldberg Steam API, Media Foundation, and VC++ 2022 Runtime</small>
          </div>
          <span class="settings-pill-value green">GE-PROTON11-9</span>
        </div>
      </div>

      <div class="console-setting-row ${f(1)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>Hero & Box Art RAM Cache (/dev/shm/anvil-art)</strong>
            <small>Pre-scales and caches all 48 games' widescreen Hero & Grid art in RAM for 0ms lag-free browsing</small>
          </div>
          <span class="settings-pill-value cyan">RAM CACHED</span>
        </div>
      </div>

      <div class="console-setting-row ${f(2)}">
        <div class="console-setting-top">
          <div class="console-setting-info">
            <strong>${state.system.model || "Valve Steam Deck (Jupiter)"}</strong>
            <small>AMD Custom APU 0405  •  16 GB LPDDR5  •  Kernel ${state.system.kernel || "6.12-hypeos"}  •  Anvil OS 5.0</small>
          </div>
          <span class="settings-pill-value">VERIFIED</span>
        </div>
      </div>
    `;
  }
}

/* =================================================
   SYSTEM UPDATE WINDOW MODAL (#update-modal)
   ================================================= */
function openUpdateModal() {
  state.updateModalOpen = true;
  syncUpdateModalUI(state.update);
  const modal = document.getElementById("update-modal");
  if (modal) modal.classList.add("open");
}

function closeUpdateModal() {
  state.updateModalOpen = false;
  const modal = document.getElementById("update-modal");
  if (modal) modal.classList.remove("open");
}

function syncUpdateModalUI(upd) {
  if (!upd) return;
  const statusText = document.getElementById("update-status-text");
  const subText = document.getElementById("update-sub-text");
  const fill = document.getElementById("update-progress-fill");
  const pctEl = document.getElementById("update-pct-text");
  const bannerMsg = document.getElementById("update-banner-msg");
  const pkgCard = document.getElementById("update-packages-card");
  const pkgList = document.getElementById("update-packages-list");
  const checkBtn = document.getElementById("update-check-btn");
  const applyBtn = document.getElementById("update-apply-btn");
  const btnLabel = document.getElementById("update-btn-label");

  const count = upd.pending_count || (upd.packages ? upd.packages.length : 0);
  const phase = upd.phase || "idle";
  const isUpgrading = phase === "upgrading";
  const isChecking = phase === "refreshing" || state.updateChecking;

  if (isUpgrading) {
    const pct = Math.round(upd.progress || 0);
    if (statusText) statusText.textContent = upd.status_step || "Applying System Updates...";
    if (subText) subText.textContent = upd.current_item ? `Current: ${upd.current_item}` : "Running background package upgrade...";
    if (fill) fill.style.width = `${Math.max(5, pct)}%`;
    if (pctEl) {
      pctEl.textContent = `${pct}%`;
      pctEl.className = "xbox-tag";
    }
    if (bannerMsg) {
      bannerMsg.textContent = "Updating system components in background without terminal interruption...";
      bannerMsg.style.color = "#38bdf8";
    }
    if (checkBtn) checkBtn.style.display = "none";
    if (applyBtn) applyBtn.style.display = "none";
  } else if (isChecking) {
    if (statusText) statusText.textContent = "Checking for System Updates...";
    if (subText) subText.textContent = "Querying pacman, paru AUR, flatpak and hypeshell core...";
    if (fill) fill.style.width = "40%";
    if (pctEl) {
      pctEl.textContent = "CHECKING";
      pctEl.className = "xbox-tag";
    }
    if (bannerMsg) {
      bannerMsg.textContent = "Synchronizing package databases with HypeShell...";
      bannerMsg.style.color = "#fbbf24";
    }
    if (btnLabel) btnLabel.textContent = "Checking...";
    if (applyBtn) applyBtn.style.display = "none";
  } else if (count > 0) {
    if (statusText) statusText.textContent = `${count} System Update${count > 1 ? "s" : ""} Available`;
    if (subText) subText.textContent = `Channel: ${upd.channel || "Stable"}  •  HypeShell Core Verified`;
    if (fill) fill.style.width = "0%";
    if (pctEl) {
      pctEl.textContent = `${count} PENDING`;
      pctEl.className = "xbox-tag";
    }
    if (bannerMsg) {
      bannerMsg.textContent = `✓ ${count} updates ready to install cleanly via HypeShell background service.`;
      bannerMsg.style.color = "#22c55e";
    }
    if (pkgCard && pkgList && upd.packages && upd.packages.length > 0) {
      pkgCard.style.display = "flex";
      pkgList.innerHTML = upd.packages.map(p => `
        <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid rgba(255,255,255,0.06); padding:3px 0;">
          <span style="font-weight:700;">${p.name || p}</span>
          <span style="color:var(--text-secondary); font-size:11px;">${p.newVersion || p.version || "update"}</span>
        </div>
      `).join("");
    }
    if (checkBtn) checkBtn.style.display = "flex";
    if (btnLabel) btnLabel.textContent = "Check Again";
    if (applyBtn) applyBtn.style.display = "flex";
  } else {
    if (statusText) statusText.textContent = "Anvil Console OS 5.0 is Up to Date";
    if (subText) subText.textContent = `Channel: ${upd.channel || "Stable"}  •  Last checked: ${upd.last_checked || "Just now"}`;
    if (fill) fill.style.width = "100%";
    if (pctEl) {
      pctEl.textContent = "UP TO DATE";
      pctEl.className = "xbox-tag green";
    }
    if (bannerMsg) {
      bannerMsg.textContent = "✓ All system packages, runtimes, and components are up to date.";
      bannerMsg.style.color = "#4ade80";
    }
    if (pkgCard) pkgCard.style.display = "none";
    if (checkBtn) checkBtn.style.display = "flex";
    if (btnLabel) btnLabel.textContent = "Check for Updates";
    if (applyBtn) applyBtn.style.display = "none";
  }
}

async function runSystemUpdateCheck() {
  if (state.updateChecking) return;
  state.updateChecking = true;
  playUiSound("confirm");

  syncUpdateModalUI(state.update);

  try {
    const res = await fetch("/api/update/check", { method: "POST" });
    const data = await res.json();
    if (data.update) state.update = data.update;
  } catch (e) {}

  state.updateChecking = false;
  syncUpdateModalUI(state.update);
  if (state.tab === 4 && state.settingsCat === 0) renderSettingsPane();
}

async function applySystemUpdates() {
  playUiSound("confirm");
  try {
    const res = await fetch("/api/update/apply", { method: "POST" });
    const data = await res.json();
    if (data.update) state.update = data.update;
  } catch (e) {}

  syncUpdateModalUI(state.update);
  pollUpdateProgress();
}

let updatePollTimer = null;
function pollUpdateProgress() {
  if (updatePollTimer) clearInterval(updatePollTimer);
  updatePollTimer = setInterval(async () => {
    try {
      const res = await fetch("/api/update");
      const data = await res.json();
      if (data.update) {
        state.update = data.update;
        syncUpdateModalUI(state.update);
        if (state.tab === 4 && state.settingsCat === 0) renderSettingsPane();
        if (data.update.phase === "idle") {
          clearInterval(updatePollTimer);
          updatePollTimer = null;
        }
      }
    } catch (e) {
      clearInterval(updatePollTimer);
      updatePollTimer = null;
    }
  }, 1000);
}

/* =================================================
   LEFT SIDEBAR: FULL-HEIGHT STEAMOS "STEAM" DRAWER
   ================================================= */
const GUIDE_SVGS = {
  play: `<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>`,
  stop: `<svg viewBox="0 0 24 24"><path d="M6 6h12v12H6z"/></svg>`,
  home: `<svg viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>`,
  lib: `<svg viewBox="0 0 24 24"><path d="M4 8h4V4H4v4zm6 12h4v-4h-4v4zm-6 0h4v-4H4v4zm0-6h4v-4H4v4zm6 0h4v-4h-4v4zm6-10v4h4V4h-4zm-6 4h4V4h-4v4zm6 6h4v-4h-4v4zm0 6h4v-4h-4v4z"/></svg>`,
  vol: `<svg viewBox="0 0 24 24"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>`,
  upd: `<svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>`,
  cart: `<svg viewBox="0 0 24 24"><path d="M18 2h-8L4 8v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-6 6h-2V4h2v4zm3 0h-2V4h2v4zm3 0h-2V4h2v4z"/></svg>`,
  gear: `<svg viewBox="0 0 24 24"><path d="M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 c0.05,0.24,0.24,0.41,0.48,0.41h3.84c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6S13.98,15.6,12,15.6z"/></svg>`,
  pwr: `<svg viewBox="0 0 24 24"><path d="M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"/></svg>`
};

function getGuideItems() {
  const items = [];
  if (state.gameRunning) {
    items.push({ icon: GUIDE_SVGS.play, label: `Resume ${state.activeGameName || "Game"}`, badge: "IN-GAME", action: () => resumeGameSession() });
    items.push({ icon: GUIDE_SVGS.stop, label: "Quit Game to Dashboard", badge: "STOP", action: () => quitGameSession() });
  }
  items.push(
    { icon: GUIDE_SVGS.home, label: "Home", badge: "HOME", action: () => { closeGuideBlade(); switchTab(0); } },
    { icon: GUIDE_SVGS.lib, label: `Library (${state.games.length})`, badge: "48 GAMES", action: () => { closeGuideBlade(); switchTab(1); } },
    { icon: GUIDE_SVGS.cart, label: "Cartridge Builder", badge: "SD / USB", action: () => { closeGuideBlade(); openCartridgeModal(); } },
    { icon: GUIDE_SVGS.vol, label: "Audio & Volume", badge: `${state.volumePct}%`, action: () => { closeGuideBlade(); switchTab(4); selectSettingCat(1); } },
    { icon: GUIDE_SVGS.upd, label: "System Updates", badge: "OS 5.0", action: () => { closeGuideBlade(); openUpdateModal(); } },
    { icon: GUIDE_SVGS.gear, label: "Settings", badge: "SYSTEM", action: () => { closeGuideBlade(); switchTab(4); selectSettingCat(0); } },
    { icon: GUIDE_SVGS.pwr, label: "Power & Desktop Mode", badge: "POWER", action: () => { closeGuideBlade(); togglePowerModal(); } }
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
      ${item.icon}
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
  if (!state.guideOpen) closeQamSidebar();
  state.guideOpen = !state.guideOpen;
  state.guideIdx = 0;
  playUiSound("tab");
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

/* =================================================
   RIGHT SIDEBAR: THREE-DOT (•••) QUICK ACCESS MENU
   ================================================= */
const QAM_ICONS = {
  vol: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#22c55e;"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>`,
  mute: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#f87171;"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>`,
  mic: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#38bdf8;"><path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3zm5.91-3c-.49 0-.9.36-.98.85C16.52 14.2 14.47 16 12 16s-4.52-1.8-4.93-4.15c-.08-.49-.49-.85-.98-.85-.61 0-1.09.54-1 1.14.49 3 2.89 5.35 5.91 5.78V20c0 .55.45 1 1 1s1-.45 1-1v-2.08c3.02-.43 5.42-2.78 5.91-5.78.1-.6-.39-1.14-1-1.14z"/></svg>`,
  sun: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#38bdf8;"><path d="M20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69L23.31 12 20 8.69zM12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6 6 2.69 6 6-2.69 6-6 6zm0-10c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z"/></svg>`,
  moon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#fbbf24;"><path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z"/></svg>`,
  bolt: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align:-3px;margin-right:6px;color:#22c55e;"><path d="M7 2v11h3v9l7-12h-4l4-8z"/></svg>`
};

function getQamItems() {
  const items = [];
  if (state.gameRunning) {
    items.push({
      id: "resume",
      title: `Resume ${state.activeGameName || "Game"}`,
      sub: "Return immediately to fullscreen game",
      badge: "PLAYING",
      green: true,
      onA: () => resumeGameSession()
    });
    items.push({
      id: "quit",
      title: "Quit Game to Dashboard",
      sub: "Close active game session",
      badge: "STOP",
      onA: () => quitGameSession()
    });
  }
  items.push(
    {
      id: "volume",
      title: `${state.volumeMuted ? QAM_ICONS.mute + "Master Output (MUTED)" : QAM_ICONS.vol + "Master Output Volume"}`,
      sub: `Use ◀ / ▶ to adjust volume, or A to mute (${state.sinkName})`,
      badge: state.volumeMuted ? "MUTED" : `${state.volumePct}%`,
      green: !state.volumeMuted,
      progress: state.volumeMuted ? 0 : state.volumePct,
      onLeft: () => adjustVolume("down"),
      onRight: () => adjustVolume("up"),
      onA: () => adjustVolume("mute")
    },
    {
      id: "brightness",
      title: `${QAM_ICONS.sun}Display Brightness`,
      sub: "Use ◀ / ▶ or A to adjust Steam Deck panel backlight",
      badge: `${state.brightnessPct}%`,
      progress: state.brightnessPct,
      cyan: true,
      onLeft: () => adjustBrightness("down"),
      onRight: () => adjustBrightness("up"),
      onA: () => adjustBrightness("up")
    },
    {
      id: "sink",
      title: `${QAM_ICONS.vol}Audio Output Sink`,
      sub: "Press A or ◀ / ▶ to switch Speakers / Headphones",
      badge: state.sinkName.includes("Headphone") ? "HEADPHONES" : "SPEAKERS",
      green: true,
      onLeft: () => adjustVolume("cycle-sink"),
      onRight: () => adjustVolume("cycle-sink"),
      onA: () => adjustVolume("cycle-sink")
    },
    {
      id: "mic",
      title: `${QAM_ICONS.mic}Microphone Level`,
      sub: "Use ◀ / ▶ to adjust mic input, or A to toggle mic mute",
      badge: state.micMuted ? "MUTED" : `${state.micPct}%`,
      progress: state.micMuted ? 0 : state.micPct,
      cyan: true,
      onLeft: () => adjustVolume("mic-down"),
      onRight: () => adjustVolume("mic-up"),
      onA: () => adjustVolume("mic-mute")
    },
    {
      id: "night",
      title: `${QAM_ICONS.moon}Night Mode Eye-Care Tint`,
      sub: "Warm amber filter for comfortable night gaming",
      badge: state.nightMode ? "ON" : "OFF",
      green: state.nightMode,
      onA: () => { toggleNightMode(); renderQamMenu(); }
    },
    {
      id: "updates",
      title: `${QAM_ICONS.bolt}Anvil OS 5.0 System Update`,
      sub: "Check for OS & Proton compatibility updates",
      badge: "UP TO DATE",
      green: true,
      onA: () => { closeQamSidebar(); openUpdateModal(); }
    }
  );
  return items;
}

function renderQamMenu() {
  const list = document.getElementById("qam-menu-list");
  if (!list) return;
  const items = getQamItems();
  state.qamIdx = Math.max(0, Math.min(items.length - 1, state.qamIdx));
  list.innerHTML = items
    .map((item, idx) => {
      const barHtml =
        typeof item.progress === "number"
          ? `<div class="slider-track" style="height:8px; margin-top:4px;">
               <div class="slider-fill ${item.cyan ? "cyan" : ""}" style="width:${item.progress}%;"></div>
               <div class="slider-thumb ${item.cyan ? "cyan" : ""}" style="left:${item.progress}%; width:14px; height:14px;"></div>
             </div>`
          : "";
      return `
        <div class="qam-card ${idx === state.qamIdx ? "selected" : ""}" id="qam-item-${idx}">
          <div class="qam-row-top">
            <span>${item.title}</span>
            <span class="xbox-tag ${item.green ? "green" : ""}">${item.badge}</span>
          </div>
          <div class="qam-sub">${item.sub}</div>
          ${barHtml}
        </div>
      `;
    })
    .join("");

  items.forEach((item, idx) => {
    const el = document.getElementById(`qam-item-${idx}`);
    if (el) {
      el.onclick = () => {
        state.qamIdx = idx;
        if (item.onA) item.onA();
        renderQamMenu();
      };
    }
  });
}

function toggleQamSidebar() {
  if (!state.qamOpen) closeGuideBlade();
  state.qamOpen = !state.qamOpen;
  state.qamIdx = 0;
  playUiSound("tab");
  renderQamMenu();
  const sb = document.getElementById("qam-sidebar");
  const bg = document.getElementById("qam-backdrop");
  if (sb) sb.classList.toggle("open", state.qamOpen);
  if (bg) bg.classList.toggle("open", state.qamOpen);
}

function closeQamSidebar() {
  state.qamOpen = false;
  const sb = document.getElementById("qam-sidebar");
  const bg = document.getElementById("qam-backdrop");
  if (sb) sb.classList.remove("open");
  if (bg) bg.classList.remove("open");
}

async function adjustVolume(dir) {
  try {
    const res = await fetch(`/api/volume?dir=${encodeURIComponent(dir)}`);
    const data = await res.json();
    if (data.ok) {
      state.volumePct = data.percent ?? state.volumePct;
      state.volumeMuted = !!data.muted;
      state.micPct = data.mic_percent ?? state.micPct;
      state.micMuted = !!data.mic_muted;
      state.sinkName = data.sink_name || state.sinkName;
      syncTopStatusBar();
      if (state.qamOpen) renderQamMenu();
      if (state.tab === 4 && state.settingsCat === 1) renderSettingsPane();
    }
  } catch (e) {}
}

async function adjustBrightness(dir) {
  try {
    const res = await fetch(`/api/brightness?dir=${encodeURIComponent(dir)}`);
    const data = await res.json();
    if (data.ok) {
      state.brightnessPct = data.percent;
      if (state.qamOpen) renderQamMenu();
      if (state.tab === 4 && state.settingsCat === 2) renderSettingsPane();
    }
  } catch (e) {}
}

/* =================================================
   TOP-CENTER HARDWARE VOLUME & BRIGHTNESS OSD PILL
   ================================================= */
let osdTimer = null;

function showSystemOSD(title, pct, muted, svgHtml) {
  const osd = document.getElementById("system-osd");
  const iconEl = document.getElementById("osd-icon");
  const titleEl = document.getElementById("osd-title");
  const valEl = document.getElementById("osd-val");
  const fillEl = document.getElementById("osd-fill");
  if (!osd) return;

  if (iconEl) iconEl.innerHTML = svgHtml;
  if (titleEl) titleEl.textContent = title;
  if (valEl) valEl.textContent = muted ? "MUTED" : `${pct}%`;
  if (fillEl) fillEl.style.width = `${muted ? 0 : Math.max(0, Math.min(100, pct))}%`;

  osd.classList.add("visible");
  if (osdTimer) clearTimeout(osdTimer);
  osdTimer = setTimeout(() => {
    osd.classList.remove("visible");
  }, 2100);
}

window.onAnvilVolumeOSD = function (pct, muted) {
  state.volumePct = pct;
  state.volumeMuted = !!muted;
  syncTopStatusBar();
  const svg = muted
    ? `<svg width="22" height="22" viewBox="0 0 24 24" fill="#f87171"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>`
    : `<svg width="22" height="22" viewBox="0 0 24 24" fill="#22c55e"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>`;
  showSystemOSD("MASTER VOLUME", pct, muted, svg);
  if (state.qamOpen) renderQamMenu();
  if (state.tab === 4 && state.settingsCat === 1) renderSettingsPane();
};

window.onAnvilBrightnessOSD = function (pct) {
  state.brightnessPct = pct;
  const svg = `<svg width="22" height="22" viewBox="0 0 24 24" fill="#38bdf8"><path d="M20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69L23.31 12 20 8.69zM12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6 6 2.69 6 6-2.69 6-6 6zm0-10c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z"/></svg>`;
  showSystemOSD("BRIGHTNESS", pct, false, svg);
  if (state.qamOpen) renderQamMenu();
  if (state.tab === 4 && state.settingsCat === 2) renderSettingsPane();
};

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
      renderCartridgesPage();
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

function updateGameCurtain(active, gameName, isOverlay) {
  const curtain = document.getElementById("game-curtain");
  if (!curtain) return;
  curtain.classList.toggle("active", !!active);
  if (!active) return;

  const g = state.games.find((item) => item.name === gameName) || state.games[state.selectedIndex] || {};
  const artEl = document.getElementById("curtain-art-img");
  const badgeEl = document.getElementById("curtain-badge");
  const titleEl = document.getElementById("curtain-title");
  const loaderEl = document.getElementById("curtain-loader");

  if (artEl) artEl.src = artUrl(g.grid || g.cover || g.hero);
  if (badgeEl) badgeEl.textContent = isOverlay ? "IN-GAME OVERLAY ACTIVE" : "STARTING CARTRIDGE...";
  if (titleEl) titleEl.textContent = gameName || g.name || "Running Cartridge";
  if (loaderEl) loaderEl.style.display = isOverlay ? "none" : "block";
}

async function launchSelectedGame() {
  const g = state.games[state.selectedIndex];
  if (!g || state.gameRunning) return;

  playUiSound("confirm");
  state.gameRunning = true;
  state.activeGameName = g.name;
  updateGameCurtain(true, g.name, false);

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
  closeQamSidebar();
  await fetch("/api/resume", { method: "POST" });
}

async function quitGameSession() {
  closeGuideBlade();
  closeQamSidebar();
  updateGameCurtain(false, "", false);
  await fetch("/api/kill", { method: "POST" });
}

window.onAnvilGameWindowReady = function () {
  updateGameCurtain(true, state.activeGameName, true);
};

window.onAnvilOverlayState = function (open, mode) {
  if (!open) {
    closeGuideBlade();
    closeQamSidebar();
    return;
  }
  updateGameCurtain(true, state.activeGameName, true);
  if (mode === "guide") {
    closeQamSidebar();
    state.guideOpen = true;
    state.guideIdx = 0;
    renderGuideMenu();
    document.getElementById("xbox-guide")?.classList.add("open");
    document.getElementById("guide-backdrop")?.classList.add("open");
  } else if (mode === "qam") {
    closeGuideBlade();
    state.qamOpen = true;
    state.qamIdx = 0;
    renderQamMenu();
    document.getElementById("qam-sidebar")?.classList.add("open");
    document.getElementById("qam-backdrop")?.classList.add("open");
  }
};

window.onAnvilGameState = function (running, gameName) {
  state.gameRunning = !!running;
  state.activeGameName = gameName || "";
  if (running) {
    updateGameCurtain(true, state.activeGameName, false);
  } else {
    closeGuideBlade();
    closeQamSidebar();
    updateGameCurtain(false, "", false);
    updateSelectedGameHero();
  }
};

window.onAnvilInput = function (action, family, controllerName) {
  if (controllerName) state.controllerName = controllerName;

  if (["up", "down", "left", "right"].includes(action)) playUiSound("tick");
  else if (action === "south") playUiSound("confirm");
  else if (action === "east") playUiSound("back");

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
    back: "SELECT",
    start: "START",
    guide: "GUIDE",
    qam: "QAM"
  };
  state.lastButton = btnMap[action] || action.toUpperCase();

  // Live controller input test in Settings (Category 5)
  if (state.tab === 4 && state.settingsCat === 5) {
    document.querySelectorAll(".pad-key").forEach((el) => el.classList.remove("pressed"));
    const keyEl = document.getElementById(`pad-key-${state.lastButton}`);
    if (keyEl) keyEl.classList.add("pressed");
    const lbl = document.getElementById("last-btn-label");
    if (lbl) lbl.textContent = `LAST INPUT: ${state.lastButton}`;
  }

  // 1. In-Game Overlay Navigation
  if (state.gameRunning) {
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
      return;
    }
    if (state.qamOpen) {
      const items = getQamItems();
      const cur = items[state.qamIdx];
      if (action === "up") {
        state.qamIdx = (state.qamIdx + items.length - 1) % items.length;
        renderQamMenu();
      } else if (action === "down") {
        state.qamIdx = (state.qamIdx + 1) % items.length;
        renderQamMenu();
      } else if (action === "left" && cur?.onLeft) {
        cur.onLeft();
      } else if (action === "right" && cur?.onRight) {
        cur.onRight();
      } else if (action === "south" && cur?.onA) {
        cur.onA();
      } else if (action === "east") {
        resumeGameSession();
      }
      return;
    }
    if (action === "south" || action === "east") {
      resumeGameSession();
    }
    return;
  }

  // 2. STEAM Button (Left Guide Sidebar) & Three-Dot ••• Button (Right Quick Access Sidebar)
  if (action === "guide" || action === "select" || action === "back") {
    toggleGuideBlade();
    return;
  }
  if (action === "qam") {
    toggleQamSidebar();
    return;
  }

  // 3. LB / RB ALWAYS switches tabs cleanly
  if (action === "lb") {
    switchTab(state.tab - 1);
    return;
  }
  if (action === "rb") {
    switchTab(state.tab + 1);
    return;
  }

  // 4. Left Sidebar (STEAM Guide Blade) navigation
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
      closeGuideBlade();
    }
    return;
  }

  // 5. Right Sidebar (••• Quick Access Menu) navigation
  if (state.qamOpen) {
    const items = getQamItems();
    const cur = items[state.qamIdx];
    if (action === "up") {
      state.qamIdx = (state.qamIdx + items.length - 1) % items.length;
      renderQamMenu();
    } else if (action === "down") {
      state.qamIdx = (state.qamIdx + 1) % items.length;
      renderQamMenu();
    } else if (action === "left" && cur?.onLeft) {
      cur.onLeft();
    } else if (action === "right" && cur?.onRight) {
      cur.onRight();
    } else if (action === "south" && cur?.onA) {
      cur.onA();
    } else if (action === "east") {
      closeQamSidebar();
    }
    return;
  }

  // 6. System Update Modal handling
  if (state.updateModalOpen) {
    if (action === "south") {
      runSystemUpdateCheck();
    } else if (action === "east") {
      closeUpdateModal();
    }
    return;
  }

  // 7. Power Modal handling
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

  // 8. Cartridge Builder Modal handling
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

  // 9. Global Dashboard Shortcuts
  if (action === "start") {
    togglePowerModal();
    return;
  }
  if (action === "west") {
    openCartridgeModal();
    return;
  }
  if (action === "north") {
    openUpdateModal();
    return;
  }
  if (action === "east" && state.tab !== 0 && !(state.tab === 4 && !state.settingsFocusSide)) {
    switchTab(0);
    return;
  }

  // 10. Tab-Specific Controller Navigation
  if (state.tab === 0) {
    if (state.homeZone === "shelf") {
      if (action === "left") selectGame(state.selectedIndex - 1);
      else if (action === "right") selectGame(state.selectedIndex + 1);
      else if (action === "up") {
        state.homeZone = "top";
        state.topNavIdx = state.tab;
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
        switchTab(state.topNavIdx);
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
  } else if (state.tab === 2) {
    if (action === "down" && state.storeIdx === 0) state.storeIdx = 1;
    else if (action === "up" && state.storeIdx > 0) state.storeIdx = 0;
    else if (action === "left" && state.storeIdx > 1) state.storeIdx--;
    else if (action === "right" && state.storeIdx >= 1 && state.storeIdx < 4) state.storeIdx++;
    else if (action === "south") {
      if (state.storeIdx === 0) launchSelectedGame();
      else if (state.storeIdx === 1) selectGameByName("Crash Bandicoot");
      else if (state.storeIdx === 2) selectGameByName("Aquapark Tycoon");
      else if (state.storeIdx === 3) selectGameByName("Jak");
      else if (state.storeIdx === 4) selectGameByName("Jackbox");
    }
    syncStoreFocusVisuals();
  } else if (state.tab === 3) {
    const maxCart = state.drives.length;
    if (action === "up") {
      state.cartPageIdx = Math.max(0, state.cartPageIdx - 1);
      renderCartridgesPage();
    } else if (action === "down") {
      state.cartPageIdx = Math.min(maxCart, state.cartPageIdx + 1);
      renderCartridgesPage();
    } else if (action === "south") {
      openCartridgeModal();
    }
  } else if (state.tab === 4) {
    if (state.settingsFocusSide) {
      if (action === "up") selectSettingCat(state.settingsCat - 1);
      else if (action === "down") selectSettingCat(state.settingsCat + 1);
      else if (action === "right" || action === "south") {
        state.settingsFocusSide = false;
        state.settingsRightIdx = 0;
        renderSettingsPane();
      }
    } else {
      const maxRight = Math.max(0, getSettingsRightItemsCount() - 1);
      if (action === "east") {
        state.settingsFocusSide = true;
        renderSettingsPane();
      } else if (action === "up") {
        state.settingsRightIdx = Math.max(0, state.settingsRightIdx - 1);
        renderSettingsPane();
      } else if (action === "down") {
        state.settingsRightIdx = Math.min(maxRight, state.settingsRightIdx + 1);
        renderSettingsPane();
      } else if (action === "left" || action === "right" || action === "south") {
        // In categories where Left adjusts a slider/cycle, only return to sidebar if the row isn't a slider/cycle
        const isAdjustableRow =
          (state.settingsCat === 0 && (state.settingsRightIdx === 1 || state.settingsRightIdx === 2)) ||
          state.settingsCat === 1 ||
          (state.settingsCat === 2 && state.settingsRightIdx <= 2) ||
          (state.settingsCat === 3 && state.settingsRightIdx === 0) ||
          (state.settingsCat === 5 && state.settingsRightIdx === 1);

        if (action === "left" && !isAdjustableRow) {
          state.settingsFocusSide = true;
          renderSettingsPane();
        } else {
          handleSettingsRightAction(action);
        }
      }
    }
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

loadState();
setTimeout(() => {
  if (!state.games || state.games.length === 0) loadState();
}, 600);
