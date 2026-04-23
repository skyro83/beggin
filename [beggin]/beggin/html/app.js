const hud = document.getElementById('hud');
const cardWeather = document.getElementById('card-weather');
const weatherIcon = document.getElementById('weather-icon');
const weatherLabel = document.getElementById('weather-label');
const weatherTime = document.getElementById('weather-time');
const locationStreet = document.getElementById('location-street');
const fills = {
    health: document.getElementById('fill-health'),
    armor: document.getElementById('fill-armor'),
    food: document.getElementById('fill-food'),
    thirst: document.getElementById('fill-thirst'),
};
const topDay = document.getElementById('top-day');
const topTime = document.getElementById('top-time');
const topId = document.getElementById('top-id');
const notifContainer = document.getElementById('notifications');

const WEATHER_MAP = {
    EXTRASUNNY: { icon: '☀️', label: 'SUNNY',    cls: 'weather-extrasunny' },
    CLEAR:      { icon: '☀️', label: 'CLEAR',    cls: 'weather-clear' },
    CLOUDS:     { icon: '⛅', label: 'CLOUDY',   cls: 'weather-clouds' },
    SMOG:       { icon: '🌫️', label: 'SMOG',     cls: 'weather-smog' },
    FOGGY:      { icon: '🌫️', label: 'FOGGY',    cls: 'weather-foggy' },
    OVERCAST:   { icon: '☁️', label: 'OVERCAST', cls: 'weather-overcast' },
    RAIN:       { icon: '🌧️', label: 'RAIN',     cls: 'weather-rain' },
    THUNDER:    { icon: '⛈️', label: 'THUNDER',  cls: 'weather-thunder' },
    CLEARING:   { icon: '🌤️', label: 'CLEARING', cls: 'weather-clearing' },
    NEUTRAL:    { icon: '🌥️', label: 'NEUTRAL',  cls: 'weather-neutral' },
    SNOW:       { icon: '❄️', label: 'SNOW',     cls: 'weather-snow' },
    BLIZZARD:   { icon: '🌨️', label: 'BLIZZARD', cls: 'weather-blizzard' },
    SNOWLIGHT:  { icon: '🌨️', label: 'SNOW',     cls: 'weather-snowlight' },
    XMAS:       { icon: '🎄', label: 'XMAS',     cls: 'weather-xmas' },
    HALLOWEEN:  { icon: '🎃', label: 'HALLOWEEN',cls: 'weather-halloween' },
};

const DAYS_FR = ['DIM.', 'LUN.', 'MAR.', 'MER.', 'JEU.', 'VEN.', 'SAM.'];

function updateStats(data) {
    hud.classList.remove('hidden');
    for (const key of ['health', 'armor', 'food', 'thirst']) {
        const v = Math.max(0, Math.min(100, Number(data[key] ?? 100)));
        const el = fills[key];
        if (!el) continue;
        el.style.width = v + '%';
        const stat = el.closest('.stat');
        stat.classList.toggle('low', v <= 20);
    }
}

function updateEnv(data) {
    if (data.weather) {
        const w = WEATHER_MAP[data.weather] || WEATHER_MAP.CLEAR;
        weatherIcon.textContent = w.icon;
        weatherLabel.textContent = w.label;
        cardWeather.className = 'card card-weather ' + w.cls;
    }
    if (data.time) weatherTime.textContent = data.time;
    if (data.street !== undefined) locationStreet.textContent = data.street || '---';
}

function updateTopbar(data) {
    if (data.playerId !== undefined) {
        let text = '#' + data.playerId;
        if (data.charName) text += ' — ' + data.charName;
        topId.textContent = text;
    }
}

function tickRealClock() {
    const d = new Date();
    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    topTime.textContent = hh + ':' + mm;
    topDay.textContent = DAYS_FR[d.getDay()];
}

setInterval(tickRealClock, 1000);
tickRealClock();

function setHudVisible(v) {
    hud.classList.toggle('hidden', !v);
}

const NOTIF_ICONS = {
    info:    'ℹ',
    success: '✓',
    warning: '!',
    error:   '✕',
};

function showNotification({ title, message, type = 'info', duration = 5000 }) {
    const el = document.createElement('div');
    el.className = 'notif notif-' + type;
    el.innerHTML = `
        <div class="notif-accent"></div>
        <div class="notif-icon">${NOTIF_ICONS[type] || 'ℹ'}</div>
        <div class="notif-body">
            ${title ? `<div class="notif-title">${escapeHtml(title)}</div>` : ''}
            <div class="notif-message">${escapeHtml(message || '')}</div>
        </div>
    `;
    notifContainer.appendChild(el);
    setTimeout(() => {
        el.classList.add('leaving');
        setTimeout(() => el.remove(), 300);
    }, duration);
}

function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}

window.addEventListener('message', (event) => {
    const d = event.data || {};
    switch (d.action) {
        case 'updateStats':   updateStats(d); break;
        case 'updateEnv':     updateEnv(d); break;
        case 'updateTopbar':  updateTopbar(d); break;
        case 'setVisible':    setHudVisible(!!d.visible); break;
        case 'notify':        showNotification(d); break;
    }
});
