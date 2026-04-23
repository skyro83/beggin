(function () {
    const screen   = document.getElementById('inventory-screen');
    const grid     = document.getElementById('inv-grid');
    const search   = document.getElementById('inv-search');
    const wCur     = document.getElementById('inv-weight-cur');
    const wMax     = document.getElementById('inv-weight-max');
    const wBox     = screen.querySelector('.inv-weight');
    const detail   = document.getElementById('inv-detail');
    const exitBtn  = document.getElementById('inv-exit');
    const fastGrid = document.getElementById('inv-fast-slots');

    const prompt      = document.getElementById('inv-prompt');
    const promptTitle = document.getElementById('inv-prompt-title');
    const promptRowT  = document.getElementById('inv-prompt-row-target');
    const promptTgt   = document.getElementById('inv-prompt-target');
    const promptAmt   = document.getElementById('inv-prompt-amount');
    const promptOk    = document.getElementById('inv-prompt-ok');
    const promptClose = document.getElementById('inv-prompt-close');
    const promptCancel= document.getElementById('inv-prompt-cancel');

    const MIN_SLOTS = 30; // pad the grid so it never looks empty

    let itemDefs = {};       // { [name]: { label, weight, type, usable, description } }
    let inventory = {};      // { [name]: amount }
    let selected = null;
    let filter = '';
    let maxWeight = 30000;

    // ---- POST helper ----
    function post(name, data) {
        return fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).then(r => r.json()).catch(() => ({}));
    }

    function esc(s) {
        return String(s).replace(/[&<>"']/g, c => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
        }[c]));
    }

    // ---- Icon (SVG) per type, fallback = generic box ----
    const TYPE_ICONS = {
        food:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M6 7h12l-1 13H7L6 7Z"/><path d="M8 7V5a4 4 0 0 1 8 0v2"/></svg>',
        drink: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M7 3h10l-1 18H8L7 3Z"/><path d="M7.5 9h9"/></svg>',
        medic: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M12 11v5M9.5 13.5h5"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
        tool:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 7l3-3 4 4-3 3"/><path d="M15 8l-9 9v4h4l9-9"/></svg>',
        item:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 8l9-5 9 5v8l-9 5-9-5V8Z"/><path d="M3 8l9 5 9-5M12 13v10"/></svg>',
    };

    function iconSvg(def) {
        if (!def) return TYPE_ICONS.item;
        return TYPE_ICONS[def.type] || TYPE_ICONS.item;
    }

    function typeLabel(type) {
        switch (type) {
            case 'food':  return 'Nourriture';
            case 'drink': return 'Boisson';
            case 'medic': return 'Soin';
            case 'tool':  return 'Outil';
            default:      return 'Objet';
        }
    }

    function formatKg(grams) {
        const kg = (Number(grams) || 0) / 1000;
        return (kg < 10 ? kg.toFixed(2) : kg.toFixed(1)).replace(/\.0+$/, '') + ' kg';
    }

    // ---- Entries ----
    function entries() {
        const list = [];
        for (const name in inventory) {
            const amount = inventory[name];
            if (!amount || amount <= 0) continue;
            const def = itemDefs[name] || { label: name, type: 'item', weight: 0, usable: false };
            list.push({ name, amount, def });
        }
        list.sort((a, b) => (a.def.label || a.name).localeCompare(b.def.label || b.name));
        return list;
    }

    // ---- Weight ----
    function totalWeight() {
        let total = 0;
        for (const name in inventory) {
            const def = itemDefs[name];
            if (def && def.weight) total += def.weight * inventory[name];
        }
        return total;
    }

    function renderWeight() {
        const cur = totalWeight();
        wCur.textContent = (cur / 1000).toFixed(1).replace(/\.0$/, '');
        wMax.textContent = '/ ' + Math.round(maxWeight / 1000) + ' KG';
        wBox.classList.toggle('overload', cur > maxWeight);
    }

    // ---- Grid ----
    function slotHtml(entry) {
        const def = entry.def;
        const cls = 'inv-slot' + (def.usable ? ' usable' : '') + (selected === entry.name ? ' selected' : '');
        return `<div class="${cls}" data-name="${esc(entry.name)}">
            <div class="inv-slot-count">x${entry.amount}</div>
            <div class="inv-slot-icon">${iconSvg(def)}</div>
            <div class="inv-slot-name">${esc(def.label || entry.name)}</div>
            <div class="inv-slot-accent"></div>
        </div>`;
    }

    function emptySlotHtml() {
        return '<div class="inv-slot empty"></div>';
    }

    function renderGrid() {
        const all = entries();
        const f = filter.trim().toLowerCase();
        const list = f
            ? all.filter(e => (e.def.label || e.name).toLowerCase().includes(f) || e.name.toLowerCase().includes(f))
            : all;

        let html = list.map(slotHtml).join('');
        const pad = Math.max(0, MIN_SLOTS - list.length);
        for (let i = 0; i < pad; i++) html += emptySlotHtml();
        grid.innerHTML = html;

        grid.querySelectorAll('.inv-slot[data-name]').forEach(el => {
            el.addEventListener('click', () => {
                selected = el.dataset.name;
                renderGrid();
                renderDetail();
            });
        });

        // Fast access placeholder: show 5 empty slots for now
        if (fastGrid) {
            let fast = '';
            for (let i = 0; i < 5; i++) fast += emptySlotHtml();
            fastGrid.innerHTML = fast;
        }
    }

    // ---- Detail sidebar ----
    function renderDetail() {
        if (!selected || !inventory[selected]) {
            detail.classList.add('inv-detail-empty');
            detail.innerHTML = `
                <div class="inv-detail-empty-msg">
                    <svg viewBox="0 0 24 24" width="36" height="36" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="7" width="18" height="13" rx="2"/>
                        <path d="M8 7V5a4 4 0 0 1 8 0v2"/>
                    </svg>
                    <p>Sélectionnez un item pour voir les actions.</p>
                </div>`;
            return;
        }

        const name = selected;
        const amount = inventory[name] || 0;
        const def = itemDefs[name] || { label: name, type: 'item', weight: 0, usable: false };
        detail.classList.remove('inv-detail-empty');

        const usableBtn = def.usable
            ? `<button class="inv-action-btn inv-action-use" data-act="use">
                   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5L20 7"/></svg>
                   Utiliser
               </button>`
            : `<button class="inv-action-btn inv-action-use" data-act="use" disabled>
                   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5L20 7"/></svg>
                   Non utilisable
               </button>`;

        detail.innerHTML = `
            <div class="inv-detail-head">
                <div class="inv-detail-icon">${iconSvg(def)}</div>
                <div class="inv-detail-info">
                    <div class="inv-detail-name">${esc(def.label || name)}</div>
                    <div class="inv-detail-meta">${esc(typeLabel(def.type))} • x${amount}</div>
                </div>
            </div>
            ${def.description ? `<div class="inv-detail-desc">${esc(def.description)}</div>` : ''}
            <div class="inv-detail-stats">
                <div class="inv-stat">
                    <div class="inv-stat-label">Poids unit.</div>
                    <div class="inv-stat-value">${formatKg(def.weight || 0)}</div>
                </div>
                <div class="inv-stat">
                    <div class="inv-stat-label">Poids total</div>
                    <div class="inv-stat-value">${formatKg((def.weight || 0) * amount)}</div>
                </div>
            </div>
            <div class="inv-detail-actions">
                ${usableBtn}
                <button class="inv-action-btn inv-action-give" data-act="give">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12h14"/><path d="M13 6l6 6-6 6"/></svg>
                    Donner
                </button>
                <button class="inv-action-btn inv-action-drop" data-act="drop">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M6 6l1 14h10l1-14"/></svg>
                    Jeter
                </button>
            </div>`;

        detail.querySelectorAll('.inv-action-btn[data-act]').forEach(btn => {
            btn.addEventListener('click', () => onAction(btn.dataset.act));
        });
    }

    // ---- Actions ----
    function onAction(act) {
        if (!selected) return;
        const max = inventory[selected] || 0;
        if (max <= 0) return;

        if (act === 'use') {
            post('inv_use', { item: selected });
            return;
        }
        if (act === 'drop') {
            openPrompt('drop', 'Jeter ' + (itemDefs[selected]?.label || selected), false, max);
            return;
        }
        if (act === 'give') {
            openPrompt('give', 'Donner ' + (itemDefs[selected]?.label || selected), true, max);
            return;
        }
    }

    // ---- Prompt ----
    let promptMode = null;
    function openPrompt(mode, title, needsTarget, max) {
        promptMode = mode;
        promptTitle.textContent = title;
        promptRowT.classList.toggle('hidden', !needsTarget);
        promptTgt.value = '';
        promptAmt.value = '1';
        promptAmt.max = max;
        prompt.classList.remove('hidden');
        (needsTarget ? promptTgt : promptAmt).focus();
    }
    function closePrompt() {
        promptMode = null;
        prompt.classList.add('hidden');
    }
    function submitPrompt() {
        if (!selected || !promptMode) return;
        const amount = Math.max(1, parseInt(promptAmt.value) || 1);
        if (promptMode === 'drop') {
            post('inv_drop', { item: selected, amount });
        } else if (promptMode === 'give') {
            const target = parseInt(promptTgt.value);
            if (!target || target < 1) return;
            post('inv_give', { item: selected, amount, target });
        }
        closePrompt();
    }

    promptOk.addEventListener('click', submitPrompt);
    promptCancel.addEventListener('click', closePrompt);
    promptClose.addEventListener('click', closePrompt);
    prompt.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { e.preventDefault(); submitPrompt(); }
        if (e.key === 'Escape') { e.preventDefault(); closePrompt(); }
    });

    // ---- Search ----
    search.addEventListener('input', () => {
        filter = search.value || '';
        renderGrid();
    });

    // ---- Exit ----
    exitBtn.addEventListener('click', () => {
        post('inv_close', {});
    });

    // ---- ESC closes screen (or prompt first) ----
    document.addEventListener('keydown', (e) => {
        if (screen.classList.contains('hidden')) return;
        if (e.key !== 'Escape') return;
        if (!prompt.classList.contains('hidden')) {
            closePrompt();
        } else {
            post('inv_close', {});
        }
    });

    // ---- Open/close from client ----
    function open(data) {
        if (data.items) itemDefs = data.items;
        if (data.maxWeight) maxWeight = data.maxWeight;
        inventory = data.inventory || {};
        if (!inventory[selected]) selected = null;
        filter = '';
        search.value = '';
        renderWeight();
        renderGrid();
        renderDetail();
        screen.classList.remove('hidden');
    }

    function close() {
        closePrompt();
        screen.classList.add('hidden');
    }

    function update(data) {
        if (data.inventory) inventory = data.inventory;
        if (!inventory[selected]) selected = null;
        renderWeight();
        renderGrid();
        renderDetail();
    }

    window.addEventListener('message', (event) => {
        const d = event.data || {};
        switch (d.action) {
            case 'inv_open':   open(d); break;
            case 'inv_close':  close(); break;
            case 'inv_update': update(d); break;
        }
    });
})();
