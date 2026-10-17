// Anvil Console OS v4.5 — SteamOS 3.6 + Xbox Series X Flagship Dashboard Frontend
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
  update: { version: "4.5.0", build: "20261017.5", channel: "Stable", up_to_date: true, last_checked: "Just now", changelog: [] },
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
    quickVolSub.textContent = `${state.volumeMuted ? "Muted" : state.volumePct + "%"} • ${state.sinkName.split(" ")[0]} Audio`;
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
   7-CATEGORY STEAMOS & XBOX SETTINGS PAGE
   ================================================= */
function selectSettingCat(catIdx) {
  state.settingsCat = Math.max(0, Math.min(6, catIdx));
  state.settingsRightIdx = 0;
  renderSettingsPane();
}

function toggleNightMode() {
  state.nightMode = !state.nightMode;
  const overlay = document.getElementById("night-mode-overlay");
  if (overlay) overlay.classList.toggle("active", state.nightMode);
  renderSettingsPane();
}

function getSettingsRightItemsCount() {
  if (state.settingsCat === 0) return 3; // Check Updates, Channel Selector, Release Notes
  if (state.settingsCat === 1) return 4; // Master Vol, Output Device, Mic Vol, UI Sounds
  if (state.settingsCat === 2) return 3; // Brightness, Night Mode, 1280x800 Scaling
  if (state.settingsCat === 3) return 2; // Wi-Fi, Tailscale
  if (state.settingsCat === 4) return 1 + state.drives.length; // Cartridge Builder + Drives
  if (state.settingsCat === 5) return 2; // Controller Bridge, Guide Lock
  return 2; // Proton & System Info
}

function handleSettingsRightAction(action) {
  const cat = state.settingsCat;
  const idx = state.settingsRightIdx;

  // Category 0: System Updates
  if (cat === 0) {
    if (idx === 0 && action === "south") {
      openUpdateModal();
    } else if (idx === 1 && (action === "left" || action === "right" || action === "south")) {
      const channels = ["Stable (Recommended)", "Preview / Beta", "Developer Mainline"];
      state.updateChannelIdx = (state.updateChannelIdx + (action === "left" ? channels.length - 1 : 1)) % channels.length;
      state.update.channel = channels[state.updateChannelIdx];
      renderSettingsPane();
    } else if (idx === 2 && action === "south") {
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
    }
    return;
  }

  // Category 4: Storage & Cartridges
  if (cat === 4 && action === "south") {
    openCartridgeModal();
  }
}

function renderSettingsPane() {
  const pane = document.getElementById("settings-detail-pane");
  if (!pane) return;

  document.querySelectorAll("#settings-cat-list .xbox-settings-cat").forEach((el, i) => {
    el.classList.toggle("active", i === state.settingsCat);
    el.classList.toggle("focused", state.settingsFocusSide && i === state.settingsCat);
  });

  const f = (idx) => (!state.settingsFocusSide && state.settingsRightIdx === idx ? "focused" : "");

  // 0: SYSTEM UPDATES
  if (state.settingsCat === 0) {
    pane.innerHTML = `
      <div class="xbox-slate-card ${f(0)}" onclick="openUpdateModal()">
        <div class="slate-row">
          <div>
            <span class="xbox-tag green" style="margin-bottom:6px; display:inline-block;">ANVIL CONSOLE OS ${state.update.version || "4.5.0"}</span>
            <div class="slate-title">Software Updates & SteamOS System Image</div>
            <div class="slate-sub">Build ${state.update.build || "20261017.5"}  •  Last checked: <strong>${state.update.last_checked || "Just now"}</strong>  •  Your console is up to date.</div>
          </div>
          <button class="xbox-btn"><span class="a-btn-mini">A</span><span>Check for Updates</span></button>
        </div>
      </div>

      <div class="xbox-slate-card ${f(1)}" onclick="handleSettingsRightAction('south')">
        <div class="slate-row">
          <div>
            <div class="slate-title">OS Update Channel</div>
            <div class="slate-sub">Use ◀ / ▶ or press A to switch between Stable, Preview, and Developer OS channels.</div>
          </div>
          <span class="settings-pill-value cyan">◀  ${state.update.channel || "Stable (Recommended)"}  ▶</span>
        </div>
      </div>

      <div class="xbox-slate-card ${f(2)}" onclick="openUpdateModal()">
        <div class="slate-row">
          <div>
            <div class="slate-title">What's New in Anvil Console OS 4.5.0</div>
            <div class="slate-sub">
              • Added SteamOS-style System Update Window & Release Notes Viewer<br>
              • Added Full Audio & Volume Mixer (Master Output, Sink Switcher, Mic Level, Console UI Sounds)<br>
              • Added Display Brightness Slider & Night Mode Eye-Care Filter<br>
              • Instant Workspace 2 Game Switching + STEAM / ••• In-Game Overlay Sidebars
            </div>
          </div>
          <span class="xbox-tag">CHANGELOG</span>
        </div>
      </div>
    `;
  }
  // 1: AUDIO & VOLUME
  else if (state.settingsCat === 1) {
    const volPct = state.volumeMuted ? 0 : state.volumePct;
    const micPct = state.micMuted ? 0 : state.micPct;
    pane.innerHTML = `
      <div class="xbox-slate-card ${f(0)}" onclick="adjustVolume('mute')">
        <div class="slate-row">
          <div>
            <div class="slate-title">Master Output Volume ${state.volumeMuted ? '<span style="color:#f87171;">(MUTED)</span>' : ""}</div>
            <div class="slate-sub">Use D-Pad ◀ / ▶ to adjust volume level, or press A to toggle mute. Hardware Volume buttons also control this live.</div>
          </div>
          <span class="settings-pill-value ${state.volumeMuted ? "" : "green"}">${state.volumeMuted ? "MUTED" : `${state.volumePct}%`}</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill" style="width:${volPct}%;"></div>
          <div class="slider-thumb" style="left:${volPct}%;"></div>
        </div>
      </div>

      <div class="xbox-slate-card ${f(1)}" onclick="adjustVolume('cycle-sink')">
        <div class="slate-row">
          <div>
            <div class="slate-title">Audio Output Device (PipeWire Sink)</div>
            <div class="slate-sub">Press A or ◀ / ▶ to switch active output between Internal Steam Deck Speakers, Headphones, and DisplayPort/HDMI Audio.</div>
          </div>
          <span class="settings-pill-value cyan">◀  ${state.sinkName}  ▶</span>
        </div>
      </div>

      <div class="xbox-slate-card ${f(2)}" onclick="adjustVolume('mic-mute')">
        <div class="slate-row">
          <div>
            <div class="slate-title">Microphone Input Gain ${state.micMuted ? '<span style="color:#f87171;">(MUTED)</span>' : ""}</div>
            <div class="slate-sub">Use D-Pad ◀ / ▶ to adjust voice chat microphone gain, or press A to mute microphone.</div>
          </div>
          <span class="settings-pill-value ${state.micMuted ? "" : "cyan"}">${state.micMuted ? "MIC MUTED" : `${state.micPct}%`}</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill cyan" style="width:${micPct}%;"></div>
          <div class="slider-thumb cyan" style="left:${micPct}%;"></div>
        </div>
      </div>

      <div class="xbox-slate-card ${f(3)}" onclick="state.uiSounds = !state.uiSounds; renderSettingsPane();">
        <div class="slate-row">
          <div>
            <div class="slate-title">Console UI Navigation Sounds</div>
            <div class="slate-sub">Play subtle tactile acoustic feedback when moving across cartridges, bumpers, and menus.</div>
          </div>
          <span class="settings-pill-value ${state.uiSounds ? "green" : ""}">${state.uiSounds ? "ENABLED" : "MUTED"}</span>
        </div>
      </div>
    `;
  }
  // 2: DISPLAY & BRIGHTNESS
  else if (state.settingsCat === 2) {
    pane.innerHTML = `
      <div class="xbox-slate-card ${f(0)}" onclick="adjustBrightness('up')">
        <div class="slate-row">
          <div>
            <div class="slate-title">Steam Deck Panel Backlight Brightness</div>
            <div class="slate-sub">Use D-Pad ◀ / ▶ to adjust display brightness (amdgpu_bl0 hardware backlight).</div>
          </div>
          <span class="settings-pill-value cyan">${state.brightnessPct}%</span>
        </div>
        <div class="slider-track">
          <div class="slider-fill cyan" style="width:${state.brightnessPct}%;"></div>
          <div class="slider-thumb cyan" style="left:${state.brightnessPct}%;"></div>
        </div>
      </div>

      <div class="xbox-slate-card ${f(1)}" onclick="toggleNightMode()">
        <div class="slate-row">
          <div>
            <div class="slate-title">Night Mode (Warm Amber Eye-Care Tint)</div>
            <div class="slate-sub">Reduces blue light emission for comfortable late-night handheld gaming. Press A to toggle.</div>
          </div>
          <span class="settings-pill-value ${state.nightMode ? "green" : ""}">${state.nightMode ? "ACTIVE (WARM)" : "OFF"}</span>
        </div>
      </div>

      <div class="xbox-slate-card ${f(2)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Native Resolution & Fullscreen Game Scaling</div>
            <div class="slate-sub">1280 × 800 (16:10 Landscape) @ 60 Hz VRR  •  Automatic Workspace 2 Fullscreen Game Windowing</div>
          </div>
          <span class="xbox-tag green">1280×800 60HZ</span>
        </div>
      </div>
    `;
  }
  // 3: NETWORK & WI-FI
  else if (state.settingsCat === 3) {
    pane.innerHTML = `
      <div class="xbox-slate-card ${f(0)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Wi-Fi Connection (${state.network.ssid || "Connected"})</div>
            <div class="slate-sub">Local IPv4 Address: <code>${state.network.ip || "192.168.1.100"}</code>  •  Hostname: <code>${state.network.hostname || "steamdeck"}</code></div>
          </div>
          <span class="xbox-tag green">${state.network.connected ? "CONNECTED" : "OFFLINE"}</span>
        </div>
      </div>

      <div class="xbox-slate-card ${f(1)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Tailscale Mesh VPN & Remote DevBox Link</div>
            <div class="slate-sub">Tailscale IPv4: <code>${state.network.tailscale_ip || "100.101.162.75"}</code>  •  Encrypted Console Link Active</div>
          </div>
          <span class="xbox-tag green">ONLINE</span>
        </div>
      </div>
    `;
  }
  // 4: STORAGE & CARTRIDGES
  else if (state.settingsCat === 4) {
    const drivesHtml = state.drives
      .map(
        (d, idx) => `
      <div class="xbox-slate-card ${f(idx + 1)}" onclick="openCartridgeModal()">
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
      <div class="xbox-slate-card ${f(0)}" onclick="openCartridgeModal()">
        <div class="slate-row">
          <div>
            <span class="xbox-tag green" style="margin-bottom:6px; display:inline-block;">CARTRIDGE PROVISIONING</span>
            <div class="slate-title">Make a Drive, SD Card, or Folder into an Anvil Cartridge</div>
            <div class="slate-sub">Formats <code>Games/</code> + <code>cartridge.meta</code> and registers the mount without touching internal storage.</div>
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
      <div class="xbox-slate-card ${f(0)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Player 1 Exclusive Xbox 360 Bridge & Zero-Drift Filter</div>
            <div class="slate-sub">Locks <code>Microsoft X-Box 360 pad</code> as XInput Slot 0 (Player 1), hides raw Lizard HID/Gyro, and enforces <strong>4000</strong> deadzone.</div>
          </div>
          <span class="xbox-tag green">PLAYER 1 LOCKED</span>
        </div>
      </div>
      <div class="xbox-slate-card ${f(1)}">
        <div class="slate-row">
          <span style="font-size:12px; font-weight:800; color:var(--text-secondary);">LIVE 16-BUTTON CONTROLLER DIAGNOSTIC MATRIX</span>
          <span style="font-size:12px; font-weight:800; color:#22c55e;" id="last-btn-label">LAST INPUT: ${state.lastButton}</span>
        </div>
        <div class="pad-matrix">${matrixHtml}</div>
      </div>
    `;
  }
  // 6: PROTON & SYSTEM INFO
  else {
    pane.innerHTML = `
      <div class="xbox-slate-card ${f(0)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">Default Compatibility Layer</div>
            <div class="slate-sub">GE-Proton11-9 & Proton Experimental with Goldberg Steam API, Media Foundation, and VC++ 2022 Runtime</div>
          </div>
          <span class="xbox-tag green">GE-PROTON11-9</span>
        </div>
      </div>
      <div class="xbox-slate-card ${f(1)}">
        <div class="slate-row">
          <div>
            <div class="slate-title">${state.system.model || "Valve Steam Deck (Jupiter)"}</div>
            <div class="slate-sub">AMD Custom APU 0405  •  16 GB LPDDR5  •  Kernel ${state.system.kernel || "6.12-hypeos"}  •  Uptime: ${state.system.uptime || "Active"}</div>
          </div>
          <span class="xbox-tag green">VERIFIED</span>
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
  const modal = document.getElementById("update-modal");
  if (modal) modal.classList.add("open");
}

function closeUpdateModal() {
  state.updateModalOpen = false;
  const modal = document.getElementById("update-modal");
  if (modal) modal.classList.remove("open");
}

async function runSystemUpdateCheck() {
  if (state.updateChecking) return;
  state.updateChecking = true;
  playUiSound("confirm");

  const statusText = document.getElementById("update-status-text");
  const subText = document.getElementById("update-sub-text");
  const fill = document.getElementById("update-progress-fill");
  const pctEl = document.getElementById("update-pct-text");
  const btnLabel = document.getElementById("update-btn-label");

  const steps = [
    { pct: 25, msg: "Querying Anvil OS Release Manifest (Stable Channel)...", sub: "Connecting to Anvil Console repository..." },
    { pct: 60, msg: "Verifying GE-Proton11-9 & Xbox 360 Bridge Signatures...", sub: "Checking /usr/local/share/anvil integrity..." },
    { pct: 90, msg: "Synchronizing Cartridge Mounts & PipeWire Audio Profiles...", sub: "Validating 48 MicroSD cartridges..." },
    { pct: 100, msg: "Anvil Console OS 4.5.0 is Up to Date", sub: "All system components, Proton runners, and audio drivers are current." }
  ];

  if (btnLabel) btnLabel.textContent = "Checking...";

  for (const s of steps) {
    if (statusText) statusText.textContent = s.msg;
    if (subText) subText.textContent = s.sub;
    if (fill) fill.style.width = `${s.pct}%`;
    if (pctEl) pctEl.textContent = s.pct < 100 ? `${s.pct}%` : "UP TO DATE";
    await new Promise((r) => setTimeout(r, 420));
  }

  try {
    const res = await fetch("/api/update", { method: "POST" });
    const data = await res.json();
    if (data.update) state.update = data.update;
  } catch (e) {}

  if (btnLabel) btnLabel.textContent = "Check Again";
  state.updateChecking = false;
  if (state.tab === 4 && state.settingsCat === 0) renderSettingsPane();
}

/* =================================================
   LEFT SIDEBAR: STEAM / GUIDE BLADE
   ================================================= */
function getGuideItems() {
  const items = [];
  if (state.gameRunning) {
    items.push({ label: `Resume ${state.activeGameName || "Game"}`, badge: "IN-GAME", action: () => resumeGameSession() });
    items.push({ label: "Quit Game to Dashboard", badge: "STOP", action: () => quitGameSession() });
  }
  items.push(
    { label: "Home Dashboard", badge: "HOME", action: () => { closeGuideBlade(); switchTab(0); } },
    { label: `My Games & Apps (${state.games.length})`, badge: "LIBRARY", action: () => { closeGuideBlade(); switchTab(1); } },
    { label: "Audio & Volume Mixer", badge: `${state.volumePct}%`, action: () => { closeGuideBlade(); switchTab(4); selectSettingCat(1); } },
    { label: "System Update Center", badge: "OS 4.5", action: () => { closeGuideBlade(); openUpdateModal(); } },
    { label: "Make a Drive / SD Card into Cartridge", badge: "BUILDER", action: () => { closeGuideBlade(); openCartridgeModal(); } },
    { label: "Settings", badge: "SYSTEM", action: () => { closeGuideBlade(); switchTab(4); selectSettingCat(0); } },
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
      onLeft: () => adjustVolume("mic-down"),
      onRight: () => adjustVolume("mic-up"),
      onA: () => adjustVolume("mic-mute")
    },
    {
      id: "brightness",
      title: `${QAM_ICONS.sun}Display Brightness`,
      sub: "Use ◀ / ▶ or A to adjust Steam Deck panel backlight",
      badge: `${state.brightnessPct}%`,
      progress: state.brightnessPct,
      onLeft: () => adjustBrightness("down"),
      onRight: () => adjustBrightness("up"),
      onA: () => adjustBrightness("up")
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
      title: `${QAM_ICONS.bolt}Anvil OS 4.5 System Update`,
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
          ? `<div class="progress-track" style="height:6px; margin-top:4px;"><div class="progress-fill" style="width:${item.progress}%;"></div></div>`
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

  if (artEl) artEl.src = artUrl(g.box_art || g.cover_art || g.hero_art);
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
        if (action === "left" && state.settingsCat !== 1 && state.settingsCat !== 2 && !(state.settingsCat === 0 && state.settingsRightIdx === 1)) {
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
