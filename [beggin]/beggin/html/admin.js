// ============================================================
// BEGGIN ADMIN PANEL — UI logic
// ============================================================

(function () {
    const panel = document.getElementById('admin-panel');
    const playerListEl = document.getElementById('player-list');
    const onlineEl = document.getElementById('admin-online');
    const searchEl = document.getElementById('admin-search');
    const banListEl = document.getElementById('ban-list');
    const modal = document.getElementById('action-modal');
    const modalTitle = document.getElementById('modal-title');
    const modalBody = document.getElementById('modal-body');

    let cachedPlayers = [];
    let locations = [];
    let vehicles = [];
    let weapons = [];

    // ---------- helpers ----------
    function post(name, data) {
        fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).catch(() => {});
    }
    function action(payload) { post('action', payload); }

    function pingClass(p) {
        if (p > 200) return 'bad';
        if (p > 100) return 'high';
        return '';
    }

    // ---------- panel open/close ----------
    function open(payload) {
        if (payload) {
            locations = payload.locations || [];
            vehicles = payload.vehicles || [];
            weapons = payload.weapons || [];
            renderLocations();
            renderQuickVehicles();
        }
        panel.classList.remove('hidden');
    }
    function close() { panel.classList.add('hidden'); modal.classList.add('hidden'); }

    document.getElementById('admin-close').addEventListener('click', () => post('close'));
    document.getElementById('admin-refresh').addEventListener('click', () => post('refresh'));
    document.getElementById('modal-close').addEventListener('click', () => modal.classList.add('hidden'));

    // ---------- tabs ----------
    document.querySelectorAll('.admin-tab').forEach(t => {
        t.addEventListener('click', () => {
            document.querySelectorAll('.admin-tab').forEach(x => x.classList.remove('active'));
            t.classList.add('active');
            const tab = t.dataset.tab;
            document.querySelectorAll('.admin-pane').forEach(p => p.classList.toggle('active', p.dataset.pane === tab));
        });
    });

    // ---------- player rendering ----------
    function renderPlayers(list) {
        cachedPlayers = list || [];
        const filter = (searchEl.value || '').toLowerCase().trim();
        const filtered = filter
            ? cachedPlayers.filter(p => String(p.source).includes(filter) || (p.name || '').toLowerCase().includes(filter))
            : cachedPlayers;

        onlineEl.textContent = `${cachedPlayers.length} en ligne`;
        playerListEl.innerHTML = '';

        for (const p of filtered) {
            const card = document.createElement('div');
            card.className = 'player-card';
            card.innerHTML = `
                <div class="pc-head">
                    <div class="pc-id">${p.source}</div>
                    <div class="pc-name" title="${p.identifier || ''}">${escapeHtml(p.name)}</div>
                    <div class="pc-ping ${pingClass(p.ping)}">${p.ping}ms</div>
                </div>
                <div class="pc-stats">
                    ${stat('health', p.health)}
                    ${stat('armor', p.armor)}
                    ${stat('food', p.food)}
                    ${stat('thirst', p.thirst)}
                </div>
                <div class="pc-meta">
                    <span>💰 ${fmt(p.cash)} / 🏦 ${fmt(p.bank)}</span>
                    <span>📍 ${p.distance}m</span>
                </div>
                <div class="pc-actions">
                    <button class="pc-act" data-act="tpTo">📍 TP to</button>
                    <button class="pc-act" data-act="tpHere">📦 TP here</button>
                    <button class="pc-act" data-act="tpInVeh">🚗 TP veh</button>
                    <button class="pc-act" data-act="spectate">👁️ Spec</button>
                    <button class="pc-act" data-act="heal">❤️ Heal</button>
                    <button class="pc-act" data-act="revive">🔄 Revive</button>
                    <button class="pc-act" data-act="freezeOn">🧊 Freeze</button>
                    <button class="pc-act" data-act="freezeOff">🔓 Unfrz</button>
                    <button class="pc-act" data-act="muteOn">🔇 Mute</button>
                    <button class="pc-act" data-act="muteOff">🔊 Unmute</button>
                    <button class="pc-act" data-act="money">💰 Argent</button>
                    <button class="pc-act" data-act="needs">🍞 Needs</button>
                    <button class="pc-act" data-act="weapon">🔫 Arme</button>
                    <button class="pc-act" data-act="copyId">📋 ID</button>
                    <button class="pc-act danger" data-act="kick">🚫 Kick</button>
                    <button class="pc-act danger" data-act="ban">🔨 Ban</button>
                </div>
            `;
            card.querySelectorAll('.pc-act').forEach(b => {
                b.addEventListener('click', () => handleAction(b.dataset.act, p));
            });
            playerListEl.appendChild(card);
        }
    }

    function stat(k, v) {
        const val = Math.max(0, Math.min(100, Number(v) || 0));
        return `<div class="pc-stat" data-k="${k}">
            <div class="pc-stat-bar"><div class="pc-stat-fill" style="width:${val}%"></div></div>
            <span class="pc-stat-label">${k}</span>
        </div>`;
    }

    function fmt(n) { return (Number(n) || 0).toLocaleString('fr-FR'); }
    function escapeHtml(s) { return String(s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])); }

    searchEl.addEventListener('input', () => renderPlayers(cachedPlayers));

    // ---------- player actions ----------
    function handleAction(act, p) {
        const t = p.source;
        switch (act) {
            case 'tpTo':     return action({ action: 'tpTo', target: t });
            case 'tpHere':   return action({ action: 'tpHere', target: t });
            case 'tpInVeh':  return action({ action: 'tpInVeh', target: t });
            case 'spectate': return action({ action: 'spectate', target: t });
            case 'heal':     return action({ action: 'heal', target: t });
            case 'revive':   return action({ action: 'revive', target: t });
            case 'freezeOn': return action({ action: 'freeze', target: t, value: true });
            case 'freezeOff':return action({ action: 'freeze', target: t, value: false });
            case 'muteOn':   return action({ action: 'mute', target: t, value: true });
            case 'muteOff':  return action({ action: 'mute', target: t, value: false });
            case 'copyId':   navigator.clipboard?.writeText(p.identifier || ''); return;
            case 'money':    return openMoneyModal(p);
            case 'needs':    return openNeedsModal(p);
            case 'weapon':   return openWeaponModal(p);
            case 'kick':     return openKickModal(p);
            case 'ban':      return openBanModal(p);
        }
    }

    function showModal(title, html, onSubmit) {
        modalTitle.textContent = title;
        modalBody.innerHTML = html;
        modal.classList.remove('hidden');
        const form = modalBody.querySelector('form');
        if (form && onSubmit) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                const data = {};
                form.querySelectorAll('[name]').forEach(el => data[el.name] = el.value);
                onSubmit(data);
                modal.classList.add('hidden');
            });
        }
    }

    function openMoneyModal(p) {
        showModal(`Argent — ${p.name}`, `
            <form>
                <div class="row">
                    <select name="account" class="admin-btn" style="flex:1">
                        <option value="cash">Cash</option>
                        <option value="bank">Banque</option>
                    </select>
                    <select name="op" class="admin-btn" style="flex:1">
                        <option value="add">Ajouter</option>
                        <option value="remove">Retirer</option>
                        <option value="set">Definir</option>
                    </select>
                </div>
                <div class="row">
                    <input name="amount" type="number" placeholder="Montant" required />
                </div>
                <button class="admin-btn admin-btn-primary">Valider</button>
            </form>`,
            (d) => action({ action: 'money', target: p.source, account: d.account, op: d.op, amount: d.amount })
        );
    }

    function openNeedsModal(p) {
        showModal(`Faim/Soif — ${p.name}`, `
            <form>
                <div class="row">
                    <select name="key" class="admin-btn" style="flex:1">
                        <option value="food">🍞 Faim</option>
                        <option value="thirst">💧 Soif</option>
                    </select>
                </div>
                <div class="row"><input name="value" type="number" min="0" max="100" placeholder="0-100" required /></div>
                <button class="admin-btn admin-btn-primary">Valider</button>
            </form>`,
            (d) => action({ action: 'setNeed', target: p.source, key: d.key, value: d.value })
        );
    }

    function openWeaponModal(p) {
        const opts = weapons.map(w => `<option value="${w.hash}" data-ammo="${w.ammo}">${w.label}</option>`).join('');
        showModal(`Donner arme — ${p.name}`, `
            <form>
                <div class="row"><select name="weapon" class="admin-btn" style="flex:1">${opts}</select></div>
                <div class="row"><input name="ammo" type="number" placeholder="Munitions" value="250" /></div>
                <button class="admin-btn admin-btn-primary">Donner</button>
            </form>`,
            (d) => action({ action: 'giveWeapon', target: p.source, weapon: d.weapon, ammo: d.ammo })
        );
    }

    function openKickModal(p) {
        showModal(`Kick — ${p.name}`, `
            <form>
                <div class="row"><input name="reason" type="text" placeholder="Raison" required /></div>
                <button class="admin-btn admin-btn-warn">Confirmer kick</button>
            </form>`,
            (d) => action({ action: 'kick', target: p.source, reason: d.reason })
        );
    }

    function openBanModal(p) {
        showModal(`Ban — ${p.name}`, `
            <form>
                <div class="row"><input name="reason" type="text" placeholder="Raison" required /></div>
                <div class="row"><input name="duration" type="number" placeholder="Duree (heures, vide = permanent)" /></div>
                <button class="admin-btn admin-btn-warn">Confirmer ban</button>
            </form>`,
            (d) => action({ action: 'ban', target: p.source, reason: d.reason, duration: d.duration })
        );
    }

    // ---------- vehicles tab ----------
    function renderQuickVehicles() {
        const c = document.getElementById('veh-quick');
        c.innerHTML = '';
        vehicles.forEach(v => {
            const b = document.createElement('button');
            b.className = 'chip';
            b.textContent = v;
            b.addEventListener('click', () => action({ action: 'vehicle', sub: 'spawn', payload: { model: v } }));
            c.appendChild(b);
        });
    }
    document.querySelectorAll('[data-veh]').forEach(b => {
        b.addEventListener('click', () => {
            const sub = b.dataset.veh;
            if (sub === 'spawn') {
                const m = document.getElementById('veh-model').value.trim();
                if (m) action({ action: 'vehicle', sub: 'spawn', payload: { model: m } });
            } else if (sub === 'invincibleOn') {
                action({ action: 'vehicle', sub: 'invincible', payload: { value: true } });
            } else if (sub === 'invincibleOff') {
                action({ action: 'vehicle', sub: 'invincible', payload: { value: false } });
            } else {
                action({ action: 'vehicle', sub: sub, payload: {} });
            }
        });
    });

    // ---------- teleport tab ----------
    function renderLocations() {
        const c = document.getElementById('tp-locations');
        c.innerHTML = '';
        locations.forEach(loc => {
            const b = document.createElement('button');
            b.className = 'chip';
            b.textContent = loc.label;
            b.addEventListener('click', () => action({ action: 'tpCoords', x: loc.x, y: loc.y, z: loc.z, heading: loc.heading }));
            c.appendChild(b);
        });
    }
    document.getElementById('tp-waypoint').addEventListener('click', () => action({ action: 'tpWaypoint' }));
    document.getElementById('tp-back').addEventListener('click', () => action({ action: 'tpBack' }));
    document.getElementById('tp-coords-go').addEventListener('click', () => {
        action({
            action: 'tpCoords',
            x: document.getElementById('tp-x').value,
            y: document.getElementById('tp-y').value,
            z: document.getElementById('tp-z').value,
        });
    });

    // ---------- staff tab ----------
    document.querySelectorAll('[data-staff]').forEach(cb => {
        cb.addEventListener('change', () => {
            action({ action: 'staff', feature: cb.dataset.staff, value: cb.checked });
        });
    });
    document.querySelectorAll('[data-staff-all]').forEach(b => {
        b.addEventListener('click', () => {
            const on = b.dataset.staffAll === 'on';
            ['god', 'invis', 'noclip', 'esp'].forEach(f => {
                action({ action: 'staff', feature: f, value: on });
                const el = document.querySelector(`[data-staff="${f}"]`);
                if (el) el.checked = on;
            });
        });
    });

    // ---------- server tab ----------
    document.getElementById('srv-announce-go').addEventListener('click', () => {
        const m = document.getElementById('srv-announce').value.trim();
        if (m) {
            action({ action: 'announce', message: m });
            document.getElementById('srv-announce').value = '';
        }
    });
    document.getElementById('srv-unban-go').addEventListener('click', () => {
        const id = document.getElementById('srv-unban').value.trim();
        if (id) action({ action: 'unban', identifier: id });
    });
    document.getElementById('srv-banlist').addEventListener('click', () => action({ action: 'listBans' }));

    function renderBans(list) {
        banListEl.innerHTML = '';
        if (!list || !list.length) { banListEl.innerHTML = '<div class="muted">Aucun ban actif.</div>'; return; }
        list.forEach(b => {
            const row = document.createElement('div');
            row.className = 'ban-row';
            row.innerHTML = `
                <div>
                    <b>${escapeHtml(b.name || '?')}</b><br>
                    <span style="opacity:.7">${escapeHtml(b.identifier)}</span><br>
                    <em>${escapeHtml(b.reason || '')}</em> — par ${escapeHtml(b.banned_by || '?')}<br>
                    <small style="opacity:.6">Cree: ${b.created_at} ${b.expires_at ? '· Expire: ' + b.expires_at : '· Permanent'}</small>
                </div>
                <button class="admin-btn admin-btn-warn">Unban</button>
            `;
            row.querySelector('button').addEventListener('click', () => action({ action: 'unban', identifier: b.identifier }));
            banListEl.appendChild(row);
        });
    }

    // ---------- NUI bridge ----------
    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action === 'openAdmin') open(d);
        else if (d.action === 'closeAdmin') close();
        else if (d.action === 'playerList') renderPlayers(d.list);
        else if (d.action === 'banList') renderBans(d.list);
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !panel.classList.contains('hidden')) post('close');
    });
})();
