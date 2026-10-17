const ART = {
  elden: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1245620/library_hero.jpg",
  borderlands: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/397540/library_hero.jpg",
  skyrim: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/489830/library_hero.jpg",
  hades: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1145360/library_hero.jpg",
  outer: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/753640/library_hero.jpg",
  mesa: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/362890/library_hero.jpg",
  celeste: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/504230/library_hero.jpg",
  control: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/870780/library_hero.jpg"
};
const POSTER = {
  elden: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1245620/library_600x900_2x.jpg",
  borderlands: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/397540/library_600x900_2x.jpg",
  skyrim: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/489830/library_600x900_2x.jpg",
  hades: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/1145360/library_600x900_2x.jpg",
  outer: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/753640/library_600x900_2x.jpg",
  mesa: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/362890/library_600x900_2x.jpg",
  celeste: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/504230/library_600x900_2x.jpg",
  control: "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/870780/library_600x900_2x.jpg"
};

const games = [
  { id: "elden", title: "Elden Ring", label: "ELDEN RING", genres: "Action RPG · Souls-like", time: "92 hours", last: "Played today", progress: 74, price: "$59.99", art: ART.elden, gradient: "linear-gradient(140deg,#243b3e,#b38247)", description: "Rise, Tarnished. Return to the Lands Between and continue your journey from the Roundtable Hold." },
  { id: "borderlands", title: "Borderlands 3", label: "BORDERLANDS", genres: "Looter Shooter · Co-op", time: "38 hours", last: "Yesterday", progress: 46, price: "$29.99", art: ART.borderlands, gradient: "linear-gradient(140deg,#d6852d,#45243f)", description: "The galaxy is loud, lawless, and full of loot. Your next vault is waiting." },
  { id: "skyrim", title: "Skyrim Special Edition", label: "SKYRIM", genres: "Open World · RPG", time: "121 hours", last: "4 days ago", progress: 63, price: "$39.99", art: ART.skyrim, gradient: "linear-gradient(140deg,#39444d,#111820)", description: "Your legend waits beyond the northern pass. Continue exploring the wilds of Skyrim." },
  { id: "hades", title: "Hades", label: "HADES", genres: "Roguelike · Action", time: "26 hours", last: "Last week", progress: 31, price: "$24.99", art: ART.hades, gradient: "linear-gradient(135deg,#651f24,#17141e 68%,#176164)", description: "Defy the god of the dead and fight your way out of the Underworld one more time." },
  { id: "outer", title: "Outer Wilds", label: "OUTER WILDS", genres: "Exploration · Mystery", time: "14 hours", last: "2 weeks ago", progress: 55, price: "$24.99", art: ART.outer, gradient: "linear-gradient(145deg,#183953,#080e18)", description: "There is more to discover in the solar system before the loop begins again." },
  { id: "mesa", title: "Black Mesa", label: "BLACK MESA", genres: "FPS · Sci-fi", time: "19 hours", last: "Last month", progress: 88, price: "$19.99", art: ART.mesa, gradient: "linear-gradient(135deg,#e76525,#2a2f33 58%,#111416)", description: "Return to the research facility where everything went wrong." },
  { id: "celeste", title: "Celeste", label: "CELESTE", genres: "Platformer · Indie", time: "11 hours", last: "3 months ago", progress: 92, price: "$19.99", art: ART.celeste, gradient: "linear-gradient(145deg,#2b3d7b,#812f6d 60%,#e27865)", description: "Help Madeline survive her inner demons on her journey to the top of Celeste Mountain." },
  { id: "control", title: "Control", label: "CONTROL", genres: "Action · Supernatural", time: "23 hours", last: "5 months ago", progress: 68, price: "$29.99", art: ART.control, gradient: "linear-gradient(125deg,#9b1720,#2b0b0d 55%,#090b0e)", description: "A corruptive presence has invaded the Federal Bureau of Control. Only you can stop it." }
];

const icon = (name) => ({
  download: '<svg viewBox="0 0 24 24"><path d="M12 3v12m0 0 5-5m-5 5-5-5M5 21h14"/></svg>',
  settings: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.83 2.83-.06-.06A1.7 1.7 0 0 0 15 19.4a1.7 1.7 0 0 0-1 .6 1.7 1.7 0 0 0-.4 1v.1h-4v-.1a1.7 1.7 0 0 0-1.1-1.6 1.7 1.7 0 0 0-1.88.34l-.06.06-2.83-2.83.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-.6-1 1.7 1.7 0 0 0-1-.4h-.1v-4H3a1.7 1.7 0 0 0 1.6-1.1 1.7 1.7 0 0 0-.34-1.88l-.06-.06 2.83-2.83.06.06A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-.6 1.7 1.7 0 0 0 .4-1v-.1h4V3a1.7 1.7 0 0 0 1.1 1.6 1.7 1.7 0 0 0 1.88-.34l.06-.06 2.83 2.83-.06.06A1.7 1.7 0 0 0 19.4 9c.14.38.36.72.6 1 .27.3.62.4 1 .4h.1v4H21a1.7 1.7 0 0 0-1.6.6Z"/></svg>',
  search: '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg>'
})[name];

const layeredArt = game => game.art ? `url('${game.art}'),${game.gradient}` : game.gradient;
const artStyle = (game, property = "--card") => game.art ? `${property}-art:${layeredArt(game)};${property}-gradient:${game.gradient}` : `${property}-gradient:${game.gradient}`;
const selectedGame = () => games.find(game => game.id === localStorage.getItem("anvilSelectedGame")) || games[0];
const gameCard = game => `<button class="game-card" data-game="${game.id}" style="${artStyle(game)};--progress:${game.progress}%"><span class="label">${game.label}</span><span class="copy"><strong class="title">${game.title}</strong><span class="card-foot"><span>${game.time}</span><span>${game.progress}%</span></span></span><span class="progress"><i></i></span></button>`;
const libraryTile = game => `<button class="library-tile" data-game="${game.id}" style="${game.art ? `--game-art:${layeredArt(game)}` : `--game-gradient:${game.gradient}`}"><span class="tile-copy"><strong>${game.title}</strong><small>${game.time} played · ${game.progress}% complete</small></span></button>`;
const searchBox = placeholder => `<label class="search">${icon("search")}<input type="search" placeholder="${placeholder}" aria-label="${placeholder}"></label>`;

function shell(page, content) {
  const navPage = page === "game" ? "library" : page;
  return `<div class="os-shell">
    <header class="topbar">
      <a class="brand" href="index.html" aria-label="Anvil home"><svg viewBox="0 0 64 64"><path d="M11 12h42l-5 13-10 4v7h13v8H13v-8h13v-7l-10-4-5-13Zm9 8 9 4h6l9-4H20ZM8 48h48l4 6H4l4-6Z"/></svg><span>ANVIL</span></a>
      <nav class="primary-nav" aria-label="Primary"><a class="nav-link ${navPage === "home" ? "active" : ""}" href="index.html">Home</a><a class="nav-link ${navPage === "store" ? "active" : ""}" href="store.html">Store</a><a class="nav-link ${navPage === "library" ? "active" : ""}" href="library.html">Library</a><a class="nav-link ${navPage === "community" ? "active" : ""}" href="Community.html">Community</a></nav>
      <div class="system-actions"><a class="icon-link ${page === "downloads" ? "active" : ""}" href="download.html" aria-label="Downloads">${icon("download")}</a><a class="icon-link ${page === "settings" ? "active" : ""}" href="settings.html" aria-label="Settings">${icon("settings")}</a><a class="profile-chip" href="profile.html"><span>Juxtopposed</span><span class="avatar">JX</span></a></div>
    </header><div class="app-view" id="app-view">${content}</div>
    <footer class="controller-bar"><div><span><b>LS</b> Navigate</span><span><b>A</b> Select</span><span><b>B</b> Back</span></div><div><i class="online-dot"></i><span>Anvil Network</span><time id="system-clock"></time></div></footer></div>`;
}

function homePage() {
  const game = games[0];
  return `<main class="home-page"><section class="home-hero" id="home-hero" style="--hero-image:url('${game.art}')"><div class="hero-copy"><p class="eyebrow">Ready to play</p><h1 id="hero-title">${game.title}</h1><p id="hero-description">${game.description}</p><div class="game-meta"><span id="hero-time">${game.time} played</span><span id="hero-last">${game.last}</span><span class="synced">Cloud synced</span></div><div class="row" style="gap:10px"><button class="button primary" data-launch="${game.id}"><i class="play-triangle"></i>Play now <span class="key">A</span></button><button class="button" data-open-game="${game.id}">Game details <span class="key">Y</span></button></div></div></section><div class="home-shelves"><div class="section-head"><div><h2>Jump back in</h2><p>Your recent games, ready where you left them.</p></div><a class="text-link" href="library.html">View full library →</a></div><div class="card-row">${games.slice(0, 6).map(gameCard).join("")}</div></div></main>`;
}

function storePage() {
  const deals = [games[3], games[6], games[4], games[7]];
  return `<main class="page store-page"><div class="page-narrow"><div class="store-toolbar"><div><p class="eyebrow">Anvil Store</p><h1 class="page-title">Find your next world.</h1></div>${searchBox("Search the store")}</div><section class="store-feature" style="--feature-art:url('${ART.elden}')"><div class="feature-copy"><p class="eyebrow">Featured this week</p><h2>Elden Ring</h2><p>Journey through the Lands Between in an adventure of mythic scale. Fully verified for Anvil.</p><div class="price-row"><span class="sale">-30%</span><span class="price">$41.99</span><button class="button primary small" data-cart="Elden Ring">Add to cart</button></div></div></section><section class="section"><div class="section-head"><div><h2>Special offers</h2><p>Hand-picked games, optimized for Anvil.</p></div><a class="text-link" href="#">Browse all deals →</a></div><div class="product-grid">${deals.map(game => `<button class="product-card" data-game="${game.id}"><div class="product-art" style="${game.art ? `--product-art:url('${game.art}')` : `--product-gradient:${game.gradient}`}"></div><div class="product-body"><span class="product-price">${game.price}</span><h3 class="product-title">${game.title}</h3><span class="tags">${game.genres}</span></div></button>`).join("")}</div></section></div></main>`;
}

function libraryPage() {
  return `<main class="page"><div class="page-narrow"><p class="eyebrow">Your collection</p><h1 class="page-title">Library</h1><p class="page-subtitle">${games.length} installed games · 184 GB used</p><div class="library-layout"><aside class="library-sidebar"><div class="side-label">Collections</div><button class="side-filter active" data-filter="all">All games <span>${games.length}</span></button><button class="side-filter" data-filter="recent">Recently played <span>5</span></button><button class="side-filter" data-filter="installed">Installed <span>8</span></button><button class="side-filter" data-filter="favorites">Favorites <span>3</span></button><div class="side-label">Dynamic</div><button class="side-filter" data-filter="rpg">Role-playing <span>3</span></button><button class="side-filter" data-filter="indie">Indie gems <span>3</span></button></aside><section class="library-main"><div class="library-top">${searchBox("Filter your library")}<button class="button small">Recently played ↓</button></div><div class="library-grid" id="library-grid">${games.map(libraryTile).join("")}</div></section></div></div></main>`;
}

function gamePage() {
  const game = selectedGame();
  return `<main class="game-page" style="${game.art ? `--detail-art:url('${game.art}')` : `--detail-art:${game.gradient}`}"><section class="game-detail"><div class="game-detail-copy"><p class="eyebrow">Ready to play</p><h1>${game.title}</h1><p class="game-description">${game.description} Anvil has checked your save and controller profile; everything is ready.</p><div class="detail-stats"><div class="detail-stat"><small>Play time</small><strong>${game.time}</strong></div><div class="detail-stat"><small>Achievements</small><strong>${game.progress}%</strong></div><div class="detail-stat"><small>Last played</small><strong>${game.last}</strong></div></div><div class="row" style="gap:10px"><button class="button primary" data-launch="${game.id}"><i class="play-triangle"></i>Play <span class="key">A</span></button><button class="button" data-toast="Added to favorites">♡ Favorite</button><a class="button ghost" href="library.html">Back to library</a></div></div></section></main>`;
}

function communityPage() {
  return `<main class="page"><div class="page-narrow"><p class="eyebrow">The commons</p><h1 class="page-title">Community</h1><p class="page-subtitle">See what your friends are playing and share the moments worth keeping.</p><div class="two-column"><section class="panel"><h2 class="panel-title">Activity feed</h2><article class="feed-item"><span class="avatar">NK</span><div><p><strong>Niko</strong> unlocked <b>Shardbearer Godrick</b> in Elden Ring.</p><div class="activity-image" style="--activity-art:url('${ART.elden}')"></div><small>18 minutes ago · 4 reactions</small></div></article><article class="feed-item"><span class="avatar">AM</span><div><p><strong>Amaya</strong> recommends <b>Outer Wilds</b>: “Go in blind. Trust me.”</p><small>2 hours ago · 11 reactions</small></div></article><article class="feed-item"><span class="avatar">RO</span><div><p><strong>Rowan</strong> started a new co-op session in Borderlands 3.</p><small>Yesterday · Joinable</small></div></article></section><aside><section class="panel"><h2 class="panel-title">Friends online · 4</h2>${[["NK","Niko","Elden Ring"],["AM","Amaya","Outer Wilds"],["RO","Rowan","Borderlands 3"],["VP","Vesper","In the menus"]].map(friend => `<div class="friend-item"><span class="avatar">${friend[0]}</span><span class="friend-copy"><strong>${friend[1]}</strong><small>${friend[2]}</small></span><i class="dot"></i></div>`).join("")}</section><section class="panel" style="margin-top:14px"><h2 class="panel-title">Your groups</h2><div class="friend-item"><span class="avatar">CO</span><span class="friend-copy"><strong>Co-op Night</strong><small>14 members · Event Friday</small></span></div><div class="friend-item"><span class="avatar">IN</span><span class="friend-copy"><strong>Indie Explorers</strong><small>38 members · 6 new posts</small></span></div></section></aside></div></div></main>`;
}

function downloadsPage() {
  return `<main class="page"><div class="page-narrow"><p class="eyebrow">System activity</p><h1 class="page-title">Downloads</h1><p class="page-subtitle">Updates and installs continue while you play.</p><div class="download-summary"><div class="summary-stat"><small>Network</small><strong>42.8 MB/s</strong></div><div class="summary-stat"><small>Disk usage</small><strong>118 MB/s</strong></div><div class="summary-stat"><small>Time remaining</small><strong>8 min</strong></div></div><section class="panel download-list"><h2 class="panel-title">Active queue</h2>${[[games[1],68,"12.4 GB of 18.2 GB","Downloading"],[games[2],34,"2.1 GB of 6.3 GB","Updating"],[games[3],100,"Verified and ready","Complete"]].map(([game,value,size,state]) => `<div class="download-item"><div class="download-art" style="${game.art ? `--download-art:url('${game.art}')` : `--download-gradient:${game.gradient}`}"></div><div class="download-copy"><strong>${game.title}</strong><small>${state}</small></div><div class="download-progress"><div class="bar" style="--value:${value}%"><i></i></div><small>${size}</small></div><div class="download-actions"><button class="button small" data-pause>${value === 100 ? "Open" : "Pause"}</button></div></div>`).join("")}</section><section class="panel download-list"><h2 class="panel-title">Scheduled</h2><div class="download-item"><div class="download-art" style="--download-gradient:${games[5].gradient}"></div><div class="download-copy"><strong>Black Mesa</strong><small>Workshop content</small></div><div class="download-progress"><small>Starts when the active queue finishes</small></div><div class="download-actions"><button class="button small ghost">Move up</button></div></div></section></div></main>`;
}

const settingGroups = {
  General: [["Start Anvil when the system boots","Skip the desktop and go straight to your games",true],["Use 24-hour clock","Show system time in 24-hour format",false],["Enable offline mode automatically","Keep installed games available when the network drops",true]],
  Display: [["Adaptive brightness","Adjust brightness to match your room",true],["Reduce motion","Use simpler transitions throughout Anvil",false],["HDR","Use high dynamic range on supported displays",true]],
  Controller: [["Game rumble","Allow games and Anvil to use haptics",true],["Nintendo button layout","Swap confirm and cancel buttons",false],["Wake with controller","Allow a paired controller to wake the system",true]],
  Downloads: [["Download while playing","Limit speed automatically to protect gameplay",true],["Automatic updates","Keep recently played games updated",true],["Allow remote downloads","Install from your phone or web browser",false]]
};

function settingsPage() {
  return `<main class="page"><div class="page-narrow"><p class="eyebrow">Anvil preferences</p><h1 class="page-title">Settings</h1><p class="page-subtitle">Make this system feel like yours.</p><div class="settings-layout"><nav class="settings-nav">${Object.keys(settingGroups).map((name,index) => `<button class="settings-tab ${index === 0 ? "active" : ""}" data-settings="${name}">${name}</button>`).join("")}<button class="settings-tab" data-settings="System">System</button></nav><section class="panel settings-panel" id="settings-panel"></section></div></div></main>`;
}

function profilePage() {
  return `<main class="page"><div class="page-narrow"><p class="eyebrow">Player profile</p><h1 class="page-title">Your corner of Anvil.</h1><section class="panel profile-hero"><div class="profile-avatar">JX</div><div class="profile-copy"><h2>Juxtopposed</h2><p>Online · Member since 2019 · Level 42</p></div><div class="profile-stats"><div class="profile-stat"><strong>128</strong><small>Games</small></div><div class="profile-stat"><strong>3,840</strong><small>Achievements</small></div><div class="profile-stat"><strong>84</strong><small>Friends</small></div></div></section><section class="section"><div class="section-head"><div><h2>Recent achievements</h2><p>Your latest hard-earned milestones.</p></div><button class="button small">Edit profile</button></div><div class="achievement-grid"><article class="panel achievement"><div class="achievement-icon">♜</div><div><strong>Shardbearer Godrick</strong><p>Defeated Godrick the Grafted · Elden Ring</p></div></article><article class="panel achievement"><div class="achievement-icon">✦</div><div><strong>Archaeologist</strong><p>Completed the ship log · Outer Wilds</p></div></article><article class="panel achievement"><div class="achievement-icon">◆</div><div><strong>Escape Artist</strong><p>Cleared an escape attempt · Hades</p></div></article></div></section><section class="section"><div class="section-head"><div><h2>Recently played</h2></div><a class="text-link" href="library.html">See library →</a></div><div class="card-row">${games.slice(0, 4).map(gameCard).join("")}</div></section></div></main>`;
}

function renderSettings(name) {
  const panel = document.getElementById("settings-panel");
  if (!panel) return;
  if (name === "System") {
    panel.innerHTML = `<h2 class="panel-title">System</h2><div class="setting-row"><div><strong>Anvil OS update</strong><p>Preview 01 · Last checked just now</p></div><button class="button small" data-toast="Anvil is up to date">Check for updates</button></div><div class="setting-row"><div><strong>Storage</strong><p>184 GB used of 512 GB</p></div><span class="select-value">Manage</span></div><div class="setting-row"><div><strong>About this system</strong><p>Hardware, software, and legal information</p></div><span class="select-value">View</span></div>`;
    return;
  }
  panel.innerHTML = `<h2 class="panel-title">${name}</h2>${settingGroups[name].map(([title,desc,on]) => `<div class="setting-row"><div><strong>${title}</strong><p>${desc}</p></div><button class="toggle ${on ? "on" : ""}" role="switch" aria-checked="${on}" aria-label="${title}"></button></div>`).join("")}`;
}

function toast(message) {
  document.querySelector(".toast")?.remove();
  const element = document.createElement("div"); element.className = "toast"; element.textContent = message; document.body.appendChild(element);
  setTimeout(() => element.remove(), 2200);
}

function setHomeGame(game) {
  const hero = document.getElementById("home-hero"); if (!hero) return;
  hero.style.setProperty("--hero-image", game.art ? `url('${game.art}')` : game.gradient);
  document.getElementById("hero-title").textContent = game.title; document.getElementById("hero-description").textContent = game.description; document.getElementById("hero-time").textContent = `${game.time} played`; document.getElementById("hero-last").textContent = game.last;
  document.querySelector("[data-launch]").dataset.launch = game.id; document.querySelector("[data-open-game]").dataset.openGame = game.id;
  document.querySelectorAll(".game-card").forEach(card => card.classList.toggle("selected", card.dataset.game === game.id));
}

function initialize(page) {
  if (page === "home") setHomeGame(games[0]);
  if (page === "settings") renderSettings("General");
  document.querySelectorAll(".feed-item,.friend-item,.achievement,.community-card,.showcase-card").forEach(item => item.tabIndex = 0);
  const initialFocus = {
    home: ".cover-tile.selected",
    store: ".store-feature .button",
    library: ".side-filter.active",
    game: ".game-detail .button.primary",
    community: ".community-action",
    downloads: "[data-pause]",
    settings: ".settings-tab.active",
    profile: ".profile-feature"
  }[page];
  requestAnimationFrame(() => document.querySelector(initialFocus)?.focus({preventScroll:true}));
  const clock = document.getElementById("system-clock");
  const updateClock = () => { if (clock) clock.textContent = new Intl.DateTimeFormat([], {hour:"numeric", minute:"2-digit"}).format(new Date()); };
  updateClock(); setInterval(updateClock, 30000);
  document.addEventListener("click", event => {
    const gameTarget = event.target.closest("[data-game]");
    if (gameTarget) { const game = games.find(item => item.id === gameTarget.dataset.game); localStorage.setItem("anvilSelectedGame", game.id); if (page === "home") setHomeGame(game); else window.location.href = "game.html"; }
    const openTarget = event.target.closest("[data-open-game]"); if (openTarget) { localStorage.setItem("anvilSelectedGame", openTarget.dataset.openGame); window.location.href = "game.html"; }
    const launchTarget = event.target.closest("[data-launch]"); if (launchTarget) { const game = games.find(item => item.id === launchTarget.dataset.launch); toast(`Launching ${game.title}…`); launchTarget.innerHTML = "Launching… <span class=\"key\">A</span>"; setTimeout(() => launchTarget.innerHTML = '<i class="play-triangle"></i>Play now <span class="key">A</span>', 1400); }
    const cartTarget = event.target.closest("[data-cart]"); if (cartTarget) toast(`${cartTarget.dataset.cart} added to cart`);
    const toastTarget = event.target.closest("[data-toast]"); if (toastTarget) toast(toastTarget.dataset.toast);
    const toggle = event.target.closest(".toggle"); if (toggle) { toggle.classList.toggle("on"); toggle.setAttribute("aria-checked", toggle.classList.contains("on")); }
    const settingsTab = event.target.closest("[data-settings]"); if (settingsTab) { document.querySelectorAll(".settings-tab").forEach(tab => tab.classList.toggle("active", tab === settingsTab)); renderSettings(settingsTab.dataset.settings); }
    const profileTab = event.target.closest("[data-profile-tab]"); if (profileTab) { document.querySelectorAll("[data-profile-tab]").forEach(tab => tab.classList.toggle("active", tab === profileTab)); toast(`${profileTab.textContent.trim()} selected`); }
    const filter = event.target.closest("[data-filter]"); if (filter) { document.querySelectorAll(".side-filter").forEach(item => item.classList.toggle("active", item === filter)); const subset = filter.dataset.filter === "all" || filter.dataset.filter === "installed" ? games : filter.dataset.filter === "recent" ? games.slice(0, 5) : filter.dataset.filter === "rpg" ? games.filter(game => game.genres.includes("RPG")) : filter.dataset.filter === "indie" ? games.filter(game => ["hades","outer","celeste"].includes(game.id)) : games.slice(0, 3); document.getElementById("library-grid").innerHTML = subset.length ? subset.map(libraryTile).join("") : '<div class="empty">Nothing here yet.</div>'; }
    const pause = event.target.closest("[data-pause]"); if (pause) { const paused = pause.dataset.paused !== "true"; pause.dataset.paused = String(paused); pause.innerHTML = `${paused ? "Resume" : "Pause"} <span class="key">A</span>`; toast(paused ? "Download paused" : "Download resumed"); }
  });
  document.addEventListener("focusin", event => {
    const gameTarget = event.target.closest("[data-game]");
    if (page === "home" && gameTarget) setHomeGame(games.find(game => game.id === gameTarget.dataset.game));
  });
  document.addEventListener("input", event => { if (event.target.matches('.library-main input[type="search"]')) { const query = event.target.value.toLowerCase(); const matches = games.filter(game => `${game.title} ${game.genres}`.toLowerCase().includes(query)); document.getElementById("library-grid").innerHTML = matches.length ? matches.map(libraryTile).join("") : '<div class="empty">No games match that search.</div>'; } });
  setupSpatialNavigation(); setupGamepad();
}

function setupSpatialNavigation() {
  document.addEventListener("pointermove", () => document.body.classList.remove("gamepad-mode"), {passive:true});
  document.addEventListener("keydown", event => {
    if (event.key === "Escape") { event.preventDefault(); history.back(); return; }
    if (event.target.matches("input") || !["ArrowLeft","ArrowRight","ArrowUp","ArrowDown"].includes(event.key)) return;
    document.body.classList.add("gamepad-mode");
    const focusables = [...document.querySelectorAll('a[href],button:not([disabled]),input')].filter(el => el.offsetParent !== null);
    if (!focusables.length) return;
    event.preventDefault();
    const current = document.activeElement;
    if (!focusables.includes(current)) { focusables[0].focus(); return; }
    const rect = current.getBoundingClientRect(); const cx = rect.left + rect.width / 2; const cy = rect.top + rect.height / 2;
    const direction = event.key.replace("Arrow", "").toLowerCase();
    const candidates = focusables.filter(el => { if (el === current) return false; const r = el.getBoundingClientRect(); const x = r.left + r.width / 2; const y = r.top + r.height / 2; return direction === "right" ? x > cx + 4 : direction === "left" ? x < cx - 4 : direction === "down" ? y > cy + 4 : y < cy - 4; });
    const score = el => { const r = el.getBoundingClientRect(); const dx = Math.abs(r.left + r.width / 2 - cx); const dy = Math.abs(r.top + r.height / 2 - cy); return (direction === "left" || direction === "right") ? dx + dy * 2.5 : dy + dx * 2.5; };
    candidates.sort((a,b) => score(a) - score(b)); (candidates[0] || current).focus(); candidates[0]?.scrollIntoView({block:"nearest", inline:"nearest"});
  });
}

function setupGamepad() {
  let held = false;
  function poll() {
    const pad = navigator.getGamepads?.()[0];
    if (pad) {
      const direction = pad.axes[0] > .55 ? "ArrowRight" : pad.axes[0] < -.55 ? "ArrowLeft" : pad.axes[1] > .55 ? "ArrowDown" : pad.axes[1] < -.55 ? "ArrowUp" : null;
      const pressed = direction || pad.buttons[0]?.pressed || pad.buttons[1]?.pressed;
      if (pressed && !held) { document.body.classList.add("gamepad-mode"); if (direction) document.dispatchEvent(new KeyboardEvent("keydown", {key:direction})); else if (pad.buttons[0]?.pressed) document.activeElement?.click(); else history.back(); }
      held = pressed;
    }
    requestAnimationFrame(poll);
  }
  requestAnimationFrame(poll);
}

/* Immersive console destinations. These intentionally replace the denser
   dashboard compositions above while keeping the shared data and behavior. */
function profilePage() {
  return `<main class="console-profile">
    <div class="profile-atmosphere"></div>
    <section class="identity-stage">
      <div class="identity-avatar">JX<span class="presence"></span></div>
      <div class="identity-copy"><div class="status-pill"><i></i> Online now</div><h1>Juxtopposed</h1><p>@juxtopposed · Forging worlds since 2019</p><div class="level-line"><strong>LEVEL 42</strong><div class="level-track"><i></i></div><span>2,840 XP to 43</span></div></div>
      <div class="identity-actions"><button class="button primary profile-action" data-toast="Profile editor opened">Edit profile <span class="key">A</span></button><button class="button" data-toast="Profile is now private">Privacy</button></div>
    </section>
    <nav class="profile-tabs" aria-label="Profile sections"><button class="active" data-profile-tab>Overview</button><button data-profile-tab>Achievements</button><button data-profile-tab>Activity</button><button data-profile-tab>Friends <span>84</span></button></nav>
    <section class="profile-content">
      <div class="section-head"><div><p class="eyebrow">Player showcase</p><h2>What defines your play.</h2></div><div class="profile-numbers"><span><strong>128</strong> Games</span><span><strong>3,840</strong> Achievements</span><span><strong>1,426h</strong> Played</span></div></div>
      <div class="showcase-row">
        <button class="showcase-card rare" data-toast="Achievement showcase opened"><span class="showcase-kicker">Rarest achievement · 2.8%</span><span class="showcase-icon">♜</span><strong>Shardbearer Godrick</strong><small>Elden Ring · Unlocked yesterday</small></button>
        <button class="showcase-card favorite" data-game="outer" style="--showcase-art:${games[4].gradient}"><span class="showcase-kicker">Favorite game</span><strong>Outer Wilds</strong><small>14 hours · 55% complete</small></button>
        <button class="showcase-card persona" data-toast="Playstyle details opened"><span class="showcase-kicker">Your playstyle</span><strong>THE EXPLORER</strong><p>Curious. Patient. Always checks behind the waterfall.</p><div class="trait-row"><span>Worlds</span><span>Stories</span><span>Secrets</span></div></button>
      </div>
      <div class="recent-strip"><div><strong>Recently played</strong><small>Across Anvil</small></div>${games.slice(0,4).map(gameCard).join("")}</div>
    </section>
  </main>`;
}

function communityPage() {
  return `<main class="console-community">
    <section class="community-hero"><div><p class="eyebrow">The commons</p><h1>Play together.</h1><p>Your people, parties, and worlds—all one button away.</p></div><button class="button primary community-action" data-toast="Party created">Start a party <span class="key">A</span></button></section>
    <section class="community-focus-grid">
      <button class="community-card party-live" data-toast="Joining Niko's party"><div class="live-badge"><i></i> Joinable now</div><div class="party-avatars"><span>NK</span><span>AM</span><span>RO</span><b>+1</b></div><span class="card-eyebrow">Friends in Elden Ring</span><strong>Roundtable regulars</strong><p>4 players · Voice open</p><span class="join-label">Join party <b>A</b></span></button>
      <button class="community-card activity-feature" data-game="elden" style="--community-art:url('${ART.elden}'),${games[0].gradient}"><span class="card-eyebrow">Niko · 18 min ago</span><strong>Shardbearer Godrick</strong><p>Achievement unlocked · 4 reactions</p></button>
      <button class="community-card recommendation" data-game="outer" style="--community-art:${games[4].gradient}"><span class="card-eyebrow">Amaya recommends</span><strong>“Go in blind. Trust me.”</strong><p>Outer Wilds · 11 friends own this</p></button>
    </section>
    <section class="friends-rail"><div class="rail-title"><strong>Friends online</strong><span>4 online · 84 total</span></div>${[["NK","Niko","Elden Ring"],["AM","Amaya","Outer Wilds"],["RO","Rowan","Borderlands 3"],["VP","Vesper","Anvil Home"]].map(friend => `<button class="friend-console" data-toast="Opening ${friend[1]}'s profile"><span class="avatar">${friend[0]}</span><span><strong>${friend[1]}</strong><small>${friend[2]}</small></span><i></i></button>`).join("")}<button class="friend-console all-friends" data-toast="Friends list opened"><b>+80</b><span><strong>All friends</strong><small>View everyone</small></span></button></section>
  </main>`;
}

function downloadsPage() {
  const active = games[1];
  return `<main class="console-downloads">
    <section class="transfer-hero" style="--transfer-art:${layeredArt(active)}">
      <div class="transfer-shade"></div><div class="transfer-copy"><p class="eyebrow">Downloading now</p><h1>${active.title}</h1><p>Installing campaign data and high-resolution textures.</p><div class="transfer-progress"><div><i></i></div><strong>68%</strong></div><div class="transfer-meta"><span><small>Downloaded</small>12.4 / 18.2 GB</span><span><small>Speed</small>42.8 MB/s</span><span><small>Remaining</small>3 min</span></div><div class="row" style="gap:12px"><button class="button primary" data-pause>Pause <span class="key">A</span></button><button class="button" data-toast="Download options opened">Options</button></div></div>
    </section>
    <section class="queue-rail"><div class="rail-title"><strong>Next in queue</strong><span>2 updates · 8 minutes remaining</span></div>
      <button class="queue-card" data-toast="Skyrim moved to the top"><span class="queue-art" style="--queue-art:${layeredArt(games[2])}"></span><span><small>Updating · 34%</small><strong>Skyrim Special Edition</strong><i class="mini-progress" style="--value:34%"></i></span><b>2.1 / 6.3 GB</b></button>
      <button class="queue-card" data-toast="Hades is ready"><span class="queue-art" style="--queue-art:${games[3].gradient}"></span><span><small class="ready">Ready to play</small><strong>Hades</strong><i class="mini-progress complete" style="--value:100%"></i></span><b>Verified</b></button>
      <button class="queue-card" data-toast="Black Mesa moved up"><span class="queue-art" style="--queue-art:${games[5].gradient}"></span><span><small>Scheduled</small><strong>Black Mesa</strong><i class="mini-progress" style="--value:0%"></i></span><b>Workshop</b></button>
    </section>
  </main>`;
}

function settingsPage() {
  return `<main class="console-settings"><div class="settings-atmosphere"></div><header><p class="eyebrow">Anvil system</p><h1>Settings</h1><p>Shape the console around the way you play.</p></header><div class="settings-console-layout"><nav class="settings-blade">${Object.keys(settingGroups).map((name,index) => `<button class="settings-tab ${index===0?"active":""}" data-settings="${name}"><span>${["⌂","◐","⌁","⇣"][index]}</span>${name}<b>›</b></button>`).join("")}<button class="settings-tab" data-settings="System"><span>◇</span>System<b>›</b></button></nav><section class="settings-detail" id="settings-panel"></section></div></main>`;
}

function renderSettings(name) {
  const panel=document.getElementById("settings-panel"); if(!panel) return;
  if(name==="System"){panel.innerHTML=`<div class="settings-detail-head"><p>System</p><h2>Console and storage</h2></div><div class="console-setting"><span><strong>Anvil OS update</strong><small>Preview 01 · Checked moments ago</small></span><button class="button small" data-toast="Anvil is up to date">Check now</button></div><div class="console-setting"><span><strong>Internal storage</strong><small>184 GB used of 512 GB</small></span><div class="storage-ring">36%</div></div><div class="console-setting"><span><strong>About this Anvil</strong><small>Hardware, software, and legal information</small></span><b class="chevron">›</b></div>`;return;}
  panel.innerHTML=`<div class="settings-detail-head"><p>${name}</p><h2>${{General:"Everyday behavior",Display:"Picture and motion",Controller:"Input and haptics",Downloads:"Updates and bandwidth"}[name]}</h2></div>${settingGroups[name].map(([title,desc,on])=>`<div class="console-setting"><span><strong>${title}</strong><small>${desc}</small></span><button class="toggle ${on?"on":""}" role="switch" aria-checked="${on}" aria-label="${title}"></button></div>`).join("")}`;
}

function profilePage() {
  const recent = games[0];
  return `<main class="profile-v3" style="--profile-wall:url('${ART.control}')">
    <div class="profile-v3-wall"></div>
    <div class="profile-v3-content">
      <header class="profile-v3-identity">
        <div class="profile-v3-avatar">JX<span></span></div>
        <div class="profile-v3-name"><div class="online-label"><i></i> Online</div><h1>Juxtopposed</h1><p>@juxtopposed · Member since 2019</p></div>
        <div class="profile-v3-level"><div class="level-disc"><strong>42</strong><small>Level</small></div><div><strong>2,840 XP</strong><small>until level 43</small></div></div>
      </header>
      <nav class="profile-v3-tabs" aria-label="Profile sections"><button class="active" data-profile-tab>Overview</button><button data-profile-tab>Games</button><button data-profile-tab>Achievements</button><button data-profile-tab>Friends</button><button class="profile-edit" data-toast="Profile editor opened">Edit profile</button></nav>
      <section class="profile-v3-grid">
        <button class="profile-feature" data-game="${recent.id}" style="--feature-game:${layeredArt(recent)}">
          <span class="profile-card-shade"></span><span class="profile-card-copy"><small>Continue playing</small><strong>${recent.title}</strong><span>${recent.time} played · ${recent.progress}% complete</span><b>Play now <i class="key">A</i></b></span>
        </button>
        <div class="profile-v3-side">
          <button class="profile-v3-card achievement-card" data-toast="Achievements opened"><div><small>Achievement progress</small><strong>3,840</strong><span>across 128 games</span></div><div class="achievement-disc"><b>78%</b></div></button>
          <button class="profile-v3-card friends-card" data-toast="Friends list opened"><div><small>Friends online</small><strong>4 playing now</strong><span>84 friends total</span></div><div class="friend-stack"><i>NK</i><i>AM</i><i>RO</i><i>+1</i></div></button>
        </div>
      </section>
      <footer class="profile-v3-stats"><span><small>Games owned</small><strong>128</strong></span><span><small>Total playtime</small><strong>1,426 hours</strong></span><span><small>Completion rate</small><strong>68%</strong></span><span><small>Perfect games</small><strong>12</strong></span><span><small>Account standing</small><strong class="good">Excellent</strong></span></footer>
    </div>
  </main>`;
}

function homePage() {
  const game=games[0];
  return `<main class="color-console-home" id="color-home">
    <div class="color-home-art" id="color-home-art"></div>
    <section class="cover-stage">
      <div class="home-greeting"><span>Games</span><small>Your library · ready to play</small></div>
      <div class="cover-rail" id="cover-rail">${games.slice(0,7).map(item=>`<button class="cover-tile" data-game="${item.id}" style="--poster:url('${POSTER[item.id]}')"><span class="verified">✓</span></button>`).join("")}</div>
      <div class="selected-summary"><div><p id="color-game-kicker">Continue playing</p><h1 id="color-game-title">${game.title}</h1><span id="color-game-description">${game.description}</span></div><div class="summary-actions"><button class="color-play" data-launch="${game.id}"><i class="play-triangle"></i> Start <b>A</b></button><button class="color-detail" data-open-game="${game.id}">Details <b>Y</b></button></div></div>
    </section>
    <section class="game-data-tray">
      <article class="completion-module"><span>Game completion</span><strong id="color-completion">${game.progress}%</strong><div><i id="color-progress" style="width:${game.progress}%"></i></div><small>Keep going—your next achievement is close.</small></article>
      <article class="achievement-module"><span>Recent achievement</span><div class="achievement-row"><b>♜</b><div><strong>The First Step</strong><small>Discovered a new path</small></div></div><em>Unlocked yesterday</em></article>
      <article class="activity-module"><span>Session overview</span><div><p><small>Total playtime</small><strong id="color-time">${game.time}</strong></p><p><small>Last played</small><strong id="color-last">${game.last}</strong></p></div><button data-toast="Activity opened">View activity →</button></article>
      <article class="capture-module"><span>Recent captures</span><div><i style="--capture:url('${ART.elden}')"></i><i style="--capture:url('${ART.outer}')"></i></div><button data-toast="Capture gallery opened">Open gallery →</button></article>
    </section>
  </main>`;
}

function setHomeGame(game) {
  const home=document.getElementById("color-home"); if(!home) return;
  const themes={elden:["#b06b38","#d44f55"],borderlands:["#e7a72e","#df416b"],skyrim:["#697988","#40505f"],hades:["#a62f36","#e2573f"],outer:["#205b77","#d06b36"],mesa:["#c5562d","#29333a"],celeste:["#7855b5","#e76c7c"]};
  const [a,b]=themes[game.id]||["#b45335","#d05258"];
  home.style.setProperty("--tone-a",a); home.style.setProperty("--tone-b",b);
  document.body.style.setProperty("--tone-a",a); document.body.style.setProperty("--tone-b",b);
  document.getElementById("color-home-art").style.setProperty("--selected-art",layeredArt(game));
  document.getElementById("color-game-title").textContent=game.title;
  document.getElementById("color-game-description").textContent=game.description;
  document.getElementById("color-completion").textContent=`${game.progress}%`;
  document.getElementById("color-progress").style.width=`${game.progress}%`;
  document.getElementById("color-time").textContent=game.time;
  document.getElementById("color-last").textContent=game.last;
  document.querySelector("[data-launch]").dataset.launch=game.id;
  document.querySelector("[data-open-game]").dataset.openGame=game.id;
  document.querySelectorAll(".cover-tile").forEach(card=>card.classList.toggle("selected",card.dataset.game===game.id));
}

const page = document.body.dataset.page || "home";
const renderers = { home: homePage, store: storePage, library: libraryPage, game: gamePage, community: communityPage, downloads: downloadsPage, settings: settingsPage, profile: profilePage };
document.getElementById("root").innerHTML = shell(page, (renderers[page] || homePage)());
initialize(page);
