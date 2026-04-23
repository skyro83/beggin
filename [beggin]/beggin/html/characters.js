(function () {
    const charScreen = document.getElementById('character-screen');
    const charContent = document.getElementById('char-content');
    const charConfirm = document.getElementById('char-confirm');
    const charConfirmText = document.getElementById('char-confirm-text');
    const charConfirmYes = document.getElementById('char-confirm-yes');
    const charConfirmNo = document.getElementById('char-confirm-no');

    let characters = [];
    let selectedId = null;
    let canCreate = false;
    let mustCreate = false;

    // ---- Creation state ----
    let creationStep = 0;
    let creationData = {};
    let maxData = {};

    const STEP_LABELS = ['Identite', 'Heritage', 'Visage', 'Cheveux', 'Vetements', 'Overlays', 'Confirmer'];

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

    // ---- Relative time (French) ----
    function relativeTime(ts) {
        if (!ts) return '';
        const diff = Date.now() - new Date(ts).getTime();
        const min = Math.floor(diff / 60000);
        if (min < 1) return "A l'instant";
        if (min < 60) return `Il y a ${min}min`;
        const h = Math.floor(min / 60);
        if (h < 24) return `Il y a ${h}h`;
        const d = Math.floor(h / 24);
        if (d === 1) return 'Hier';
        if (d < 30) return `Il y a ${d}j`;
        return new Date(ts).toLocaleDateString('fr-FR');
    }

    function formatDob(dob) {
        if (!dob) return '';
        const parts = dob.split('-');
        if (parts.length !== 3) return dob;
        return parts[2] + '/' + parts[1] + '/' + parts[0];
    }

    const GENDER_ICONS = {
        male: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="10" cy="14" r="5"/><path d="M19 5l-5.4 5.4M19 5h-5M19 5v5"/></svg>',
        female: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="10" r="5"/><path d="M12 15v6M9 19h6"/></svg>',
    };

    // ---- Parent names (GTA heritage) ----
    const PARENT_NAMES = [
        'Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew',
        'Joan', 'Alex', 'Isaac', 'Evan', 'Ethan',
        'Vincent', 'Angel', 'Diego', 'Adrian', 'Gabriel',
        'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel',
        'Anthony', 'Claude', 'Niko', 'John', 'Roman',
        'Misty', 'Katie', 'Michelle', 'Barbara', 'Denise',
        'Helena', 'Millie', 'Catalina', 'Elizabeth', 'Anna',
        'Audrey', 'Sophie', 'Hannah', 'Amber', 'Grace',
        'Brianna', 'Natalie', 'Olivia', 'Emily', 'Mary',
        'Patricia',
    ];

    const MAX_HAIR_COLORS = 63;
    const MAX_EYE_COLORS = 31;

    // ---- Face feature labels ----
    const FEATURE_LABELS = [
        { name: 'Largeur du nez', group: 'Nez' },
        { name: 'Hauteur du nez', group: 'Nez' },
        { name: 'Longueur du nez', group: 'Nez' },
        { name: 'Arche du nez', group: 'Nez' },
        { name: 'Pointe du nez', group: 'Nez' },
        { name: 'Decalage du nez', group: 'Nez' },
        { name: 'Hauteur des sourcils', group: 'Sourcils' },
        { name: 'Largeur des sourcils', group: 'Sourcils' },
        { name: 'Hauteur des pommettes', group: 'Pommettes' },
        { name: 'Largeur des pommettes', group: 'Pommettes' },
        { name: 'Largeur des joues', group: 'Joues' },
        { name: 'Forme des yeux', group: 'Yeux' },
        { name: 'Largeur des levres', group: 'Levres' },
        { name: 'Largeur de la machoire', group: 'Machoire' },
        { name: 'Longueur de la machoire', group: 'Machoire' },
        { name: 'Hauteur du menton', group: 'Menton' },
        { name: 'Longueur du menton', group: 'Menton' },
        { name: 'Largeur du menton', group: 'Menton' },
        { name: 'Fossette du menton', group: 'Menton' },
        { name: 'Epaisseur du cou', group: 'Cou' },
    ];

    // ---- Overlay labels ----
    const OVERLAY_LABELS = {
        0: 'Imperfections',
        3: 'Vieillissement',
        4: 'Maquillage (joues)',
        5: 'Blush',
        6: 'Teint',
        7: 'Dommages soleil',
        8: 'Rouge a levres',
        9: 'Grains de beaute',
        10: 'Poils de torse',
        11: 'Dommages corporels',
    };

    // ---- Component labels ----
    const COMP_LABELS = {
        4: 'Pantalon',
        6: 'Chaussures',
        7: 'Accessoire',
        8: 'Sous-vetement',
        11: 'Veste',
    };

    const PROP_LABELS = {
        1: 'Lunettes',
        2: 'Oreilles',
        6: 'Montre',
        7: 'Bracelet',
    };

    // ============================================================
    // CHARACTER SELECTION
    // ============================================================
    function renderList() {
        selectedId = null;
        charScreen.classList.remove('creation-mode');
        let html = '<div class="char-grid">';

        for (const c of characters) {
            html += `
                <div class="char-card" data-id="${c.id}">
                    <button class="char-card-delete" data-delete="${c.id}" title="Supprimer">&#x2715;</button>
                    <div class="char-card-gender ${esc(c.gender)}">${GENDER_ICONS[c.gender] || GENDER_ICONS.male}</div>
                    <div class="char-card-name">${esc(c.firstname)} ${esc(c.lastname)}</div>
                    <div class="char-card-dob">${formatDob(c.dateofbirth)}</div>
                    <div class="char-card-lastplayed">${relativeTime(c.last_played)}</div>
                </div>
            `;
        }

        if (canCreate) {
            html += `
                <div class="char-card char-card-new" id="char-new-btn">
                    <div class="char-card-new-icon">+</div>
                    <div class="char-card-new-label">Nouveau personnage</div>
                </div>
            `;
        }

        html += '</div>';
        html += '<div class="char-actions"><button class="char-btn-play" id="char-play-btn" disabled>JOUER</button></div>';

        charContent.innerHTML = html;

        charContent.querySelectorAll('.char-card[data-id]').forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.closest('.char-card-delete')) return;
                charContent.querySelectorAll('.char-card').forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');
                selectedId = parseInt(card.dataset.id);
                const playBtn = document.getElementById('char-play-btn');
                if (playBtn) playBtn.disabled = false;
            });
            card.addEventListener('dblclick', (e) => {
                if (e.target.closest('.char-card-delete')) return;
                const id = parseInt(card.dataset.id);
                if (id) post('selectCharacter', { id });
            });
        });

        const playBtn = document.getElementById('char-play-btn');
        if (playBtn) {
            playBtn.addEventListener('click', () => {
                if (selectedId) post('selectCharacter', { id: selectedId });
            });
        }

        const newBtn = document.getElementById('char-new-btn');
        if (newBtn) {
            newBtn.addEventListener('click', () => {
                startCreation(false);
            });
        }

        charContent.querySelectorAll('[data-delete]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = parseInt(btn.dataset.delete);
                const char = characters.find(c => c.id === id);
                if (!char) return;
                showDeleteConfirm(id, char.firstname + ' ' + char.lastname);
            });
        });
    }

    // ============================================================
    // CHARACTER CREATION — INIT
    // ============================================================
    function startCreation(isMustCreate) {
        creationStep = 0;
        creationData = {
            firstname: '',
            lastname: '',
            dateofbirth: '',
            gender: 'male',
            appearance: {
                heritage: { mother: 0, father: 0, shapeMix: 0.5, skinMix: 0.5 },
                features: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                hair: { style: 0, color: 0, highlight: 0 },
                beard: { style: -1, color: 0, opacity: 1.0 },
                eyebrows: { style: 0, color: 0, opacity: 1.0 },
                eyeColor: 0,
                overlays: {},
                components: {},
                props: {},
            },
        };
        maxData = {};
        mustCreate = isMustCreate;
        renderStep();
    }

    // ============================================================
    // STEP PROGRESS BAR
    // ============================================================
    function buildStepBar() {
        let html = '<div class="char-steps">';
        for (let i = 0; i < STEP_LABELS.length; i++) {
            if (i > 0) {
                html += `<div class="char-step-line ${i <= creationStep ? 'done' : ''}"></div>`;
            }
            const cls = i === creationStep ? 'active' : (i < creationStep ? 'done' : '');
            html += `<div class="char-step-dot ${cls}" data-step="${i}" title="${STEP_LABELS[i]}">${i + 1}</div>`;
        }
        html += '</div>';
        return html;
    }

    function bindStepDots() {
        charContent.querySelectorAll('.char-step-dot').forEach(dot => {
            dot.addEventListener('click', () => {
                const s = parseInt(dot.dataset.step);
                if (s < creationStep) {
                    creationStep = s;
                    renderStep();
                }
            });
        });
    }

    // ============================================================
    // STEP NAVIGATION
    // ============================================================
    function buildStepNav(showPrev, nextLabel) {
        let html = '<div class="char-step-nav">';
        if (showPrev) {
            html += '<button class="char-btn-prev" id="step-prev">Precedent</button>';
        } else {
            html += '<div></div>';
        }
        if (nextLabel === 'confirm') {
            html += '<button class="char-btn-confirm" id="step-next">Confirmer</button>';
        } else {
            html += `<button class="char-btn-next" id="step-next">${nextLabel || 'Suivant'}</button>`;
        }
        html += '</div>';
        return html;
    }

    function bindStepNav(onNext) {
        const prev = document.getElementById('step-prev');
        const next = document.getElementById('step-next');
        if (prev) {
            prev.addEventListener('click', () => {
                if (creationStep === 1) {
                    // Going back to identity — leave creation mode
                    charScreen.classList.remove('creation-mode');
                }
                creationStep--;
                renderStep();
            });
        }
        if (next) {
            next.addEventListener('click', () => {
                if (onNext && !onNext()) return;
                creationStep++;
                renderStep();
            });
        }
    }

    // ============================================================
    // RENDER STEP
    // ============================================================
    function renderStep() {
        switch (creationStep) {
            case 0: renderStepIdentity(); break;
            case 1: renderStepHeritage(); break;
            case 2: renderStepFace(); break;
            case 3: renderStepHair(); break;
            case 4: renderStepClothing(); break;
            case 5: renderStepOverlays(); break;
            case 6: renderStepConfirm(); break;
        }
    }

    // ============================================================
    // STEP 1 — IDENTITY
    // ============================================================
    function renderStepIdentity() {
        charScreen.classList.remove('creation-mode');

        let dayOpts = '<option value="">Jour</option>';
        for (let d = 1; d <= 31; d++) dayOpts += `<option value="${String(d).padStart(2,'0')}">${d}</option>`;

        const MONTHS = ['Janvier','Fevrier','Mars','Avril','Mai','Juin','Juillet','Aout','Septembre','Octobre','Novembre','Decembre'];
        let monthOpts = '<option value="">Mois</option>';
        for (let m = 0; m < 12; m++) monthOpts += `<option value="${String(m+1).padStart(2,'0')}">${MONTHS[m]}</option>`;

        const currentYear = new Date().getFullYear();
        let yearOpts = '<option value="">Annee</option>';
        for (let y = currentYear - 80; y <= currentYear - 18; y++) yearOpts += `<option value="${y}">${y}</option>`;

        const g = creationData.gender || 'male';

        let html = buildStepBar();
        html += `<div class="char-step-content"><div class="char-form">
            <div class="char-form-row">
                <div class="char-form-group">
                    <label class="char-form-label">Prenom</label>
                    <input class="char-form-input" id="cf-firstname" type="text" placeholder="Jean" maxlength="20" value="${esc(creationData.firstname)}" />
                </div>
                <div class="char-form-group">
                    <label class="char-form-label">Nom</label>
                    <input class="char-form-input" id="cf-lastname" type="text" placeholder="Dupont" maxlength="20" value="${esc(creationData.lastname)}" />
                </div>
            </div>
            <div class="char-form-group">
                <label class="char-form-label">Date de naissance</label>
                <div class="char-dob-row">
                    <select id="cf-day">${dayOpts}</select>
                    <select id="cf-month">${monthOpts}</select>
                    <select id="cf-year">${yearOpts}</select>
                </div>
            </div>
            <div class="char-form-group">
                <label class="char-form-label">Genre</label>
                <div class="char-gender-pills">
                    <button class="char-gender-pill ${g === 'male' ? 'active-male' : ''}" data-gender="male">
                        <span class="char-gender-icon">${GENDER_ICONS.male}</span> Homme
                    </button>
                    <button class="char-gender-pill ${g === 'female' ? 'active-female' : ''}" data-gender="female">
                        <span class="char-gender-icon">${GENDER_ICONS.female}</span> Femme
                    </button>
                </div>
            </div>
            <div class="char-form-error" id="cf-error"></div>
            ${buildStepNav(!mustCreate && characters.length > 0 ? false : false, 'Suivant')}
        </div></div>`;

        charContent.innerHTML = html;
        bindStepDots();

        // Restore DOB
        if (creationData.dateofbirth) {
            const p = creationData.dateofbirth.split('-');
            if (p.length === 3) {
                document.getElementById('cf-year').value = p[0];
                document.getElementById('cf-month').value = p[1];
                document.getElementById('cf-day').value = p[2];
            }
        }

        // Gender pills
        charContent.querySelectorAll('.char-gender-pill').forEach(pill => {
            pill.addEventListener('click', () => {
                charContent.querySelectorAll('.char-gender-pill').forEach(p => p.classList.remove('active-male', 'active-female'));
                creationData.gender = pill.dataset.gender;
                pill.classList.add(creationData.gender === 'male' ? 'active-male' : 'active-female');
            });
        });

        // Back button for non-must-create
        if (!mustCreate && characters.length > 0) {
            const nav = charContent.querySelector('.char-step-nav');
            if (nav) {
                const backBtn = document.createElement('button');
                backBtn.className = 'char-btn-prev';
                backBtn.textContent = 'Retour';
                backBtn.addEventListener('click', () => renderList());
                nav.prepend(backBtn);
            }
        }

        // Next validation
        bindStepNav(() => {
            const firstname = (document.getElementById('cf-firstname').value || '').trim();
            const lastname = (document.getElementById('cf-lastname').value || '').trim();
            const day = document.getElementById('cf-day').value;
            const month = document.getElementById('cf-month').value;
            const year = document.getElementById('cf-year').value;
            const errorEl = document.getElementById('cf-error');

            if (firstname.length < 2 || firstname.length > 20) {
                errorEl.textContent = 'Le prenom doit contenir entre 2 et 20 caracteres';
                return false;
            }
            if (lastname.length < 2 || lastname.length > 20) {
                errorEl.textContent = 'Le nom doit contenir entre 2 et 20 caracteres';
                return false;
            }
            if (!day || !month || !year) {
                errorEl.textContent = 'Veuillez renseigner la date de naissance complete';
                return false;
            }

            creationData.firstname = firstname;
            creationData.lastname = lastname;
            creationData.dateofbirth = `${year}-${month}-${day}`;

            // Switch to creation mode and setup the ped
            charScreen.classList.add('creation-mode');
            charContent.innerHTML = '<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.5);">Chargement...</div>';

            post('setupCreation', { gender: creationData.gender }).then(res => {
                if (res && res.maxData) maxData = res.maxData;
                creationStep = 1;
                renderStep();
            });

            return false; // don't auto-advance, we handle it in the callback
        });
    }

    // ============================================================
    // STEP 2 — HERITAGE
    // ============================================================
    function renderStepHeritage() {
        const h = creationData.appearance.heritage;
        post('switchCamera', { cam: 'face' });

        let html = buildStepBar();
        html += '<div class="char-step-content"><div class="char-step-body">';

        html += `<div class="char-section-title">Parents</div>`;
        html += buildArrowSelector('heritage-mother', 'Mere', h.mother, 0, 45, i => PARENT_NAMES[i] || `#${i}`);
        html += buildArrowSelector('heritage-father', 'Pere', h.father, 0, 45, i => PARENT_NAMES[i] || `#${i}`);

        html += `<div class="char-section-title">Ressemblance</div>`;
        html += buildSlider('heritage-shape', 'Forme du visage', h.shapeMix, 0, 1, 0.05, v => Math.round(v * 100) + '%');
        html += buildSlider('heritage-skin', 'Teint de peau', h.skinMix, 0, 1, 0.05, v => Math.round(v * 100) + '%');

        html += buildStepNav(true, 'Suivant');
        html += '</div></div>';
        charContent.innerHTML = html;
        bindStepDots();

        bindArrowSelector('heritage-mother', 0, 45, val => {
            h.mother = val;
            post('updateHeritage', h);
        });
        bindArrowSelector('heritage-father', 0, 45, val => {
            h.father = val;
            post('updateHeritage', h);
        });
        bindSlider('heritage-shape', val => {
            h.shapeMix = val;
            post('updateHeritage', h);
        });
        bindSlider('heritage-skin', val => {
            h.skinMix = val;
            post('updateHeritage', h);
        });

        bindStepNav();
    }

    // ============================================================
    // STEP 3 — FACE FEATURES
    // ============================================================
    function renderStepFace() {
        post('switchCamera', { cam: 'face' });

        let html = buildStepBar();
        html += '<div class="char-step-content"><div class="char-step-body">';

        let lastGroup = '';
        for (let i = 0; i < 20; i++) {
            const fl = FEATURE_LABELS[i];
            if (fl.group !== lastGroup) {
                html += `<div class="char-section-title">${fl.group}</div>`;
                lastGroup = fl.group;
            }
            const val = creationData.appearance.features[i] || 0;
            html += buildSlider(`feat-${i}`, fl.name, val, -1, 1, 0.1, v => v.toFixed(1));
        }

        html += buildStepNav(true, 'Suivant');
        html += '</div></div>';
        charContent.innerHTML = html;
        bindStepDots();

        for (let i = 0; i < 20; i++) {
            bindSlider(`feat-${i}`, val => {
                creationData.appearance.features[i] = parseFloat(val.toFixed(1));
                post('updateFeature', { index: i, value: creationData.appearance.features[i] });
            });
        }

        bindStepNav();
    }

    // ============================================================
    // STEP 4 — HAIR & BEARD
    // ============================================================
    function renderStepHair() {
        post('switchCamera', { cam: 'face' });

        const hair = creationData.appearance.hair;
        const beard = creationData.appearance.beard;
        const eb = creationData.appearance.eyebrows;
        const maxHair = (maxData.comp_2 || 50) - 1;

        let html = buildStepBar();
        html += '<div class="char-step-content"><div class="char-step-body">';

        // Hair
        html += `<div class="char-section-title">Cheveux</div>`;
        html += buildArrowSelector('hair-style', 'Coupe', hair.style, 0, maxHair);
        html += buildArrowSelector('hair-color', 'Couleur', hair.color, 0, MAX_HAIR_COLORS);
        html += buildArrowSelector('hair-highlight', 'Meches', hair.highlight, 0, MAX_HAIR_COLORS);

        // Eyebrows
        html += `<div class="char-section-title">Sourcils</div>`;
        html += buildArrowSelector('eb-style', 'Style', eb.style, 0, 33);
        html += buildSlider('eb-opacity', 'Opacite', eb.opacity, 0, 1, 0.1, v => Math.round(v * 100) + '%');
        html += buildArrowSelector('eb-color', 'Couleur', eb.color, 0, MAX_HAIR_COLORS);

        // Beard (always show, -1 = none)
        html += `<div class="char-section-title">Barbe</div>`;
        html += buildArrowSelector('beard-style', 'Style', beard.style, -1, 28, v => v < 0 ? 'Aucune' : `#${v}`);
        html += buildSlider('beard-opacity', 'Opacite', beard.opacity, 0, 1, 0.1, v => Math.round(v * 100) + '%');
        html += buildArrowSelector('beard-color', 'Couleur', beard.color, 0, MAX_HAIR_COLORS);

        // Eye color
        html += `<div class="char-section-title">Yeux</div>`;
        html += buildArrowSelector('eye-color', 'Couleur des yeux', creationData.appearance.eyeColor, 0, MAX_EYE_COLORS);

        html += buildStepNav(true, 'Suivant');
        html += '</div></div>';
        charContent.innerHTML = html;
        bindStepDots();

        // Bind hair
        bindArrowSelector('hair-style', 0, maxHair, val => {
            hair.style = val;
            post('updateHair', hair);
        });
        bindArrowSelector('hair-color', 0, MAX_HAIR_COLORS, val => {
            hair.color = val;
            post('updateHair', hair);
        });
        bindArrowSelector('hair-highlight', 0, MAX_HAIR_COLORS, val => {
            hair.highlight = val;
            post('updateHair', hair);
        });

        // Bind eyebrows
        bindArrowSelector('eb-style', 0, 33, val => {
            eb.style = val;
            post('updateEyebrows', { style: eb.style, color: eb.color, opacity: eb.opacity });
        });
        bindSlider('eb-opacity', val => {
            eb.opacity = val;
            post('updateEyebrows', { style: eb.style, color: eb.color, opacity: eb.opacity });
        });
        bindArrowSelector('eb-color', 0, MAX_HAIR_COLORS, val => {
            eb.color = val;
            post('updateEyebrows', { style: eb.style, color: eb.color, opacity: eb.opacity });
        });

        // Bind beard
        bindArrowSelector('beard-style', -1, 28, val => {
            beard.style = val;
            post('updateBeard', beard);
        });
        bindSlider('beard-opacity', val => {
            beard.opacity = val;
            post('updateBeard', beard);
        });
        bindArrowSelector('beard-color', 0, MAX_HAIR_COLORS, val => {
            beard.color = val;
            post('updateBeard', beard);
        });

        // Bind eye color
        bindArrowSelector('eye-color', 0, MAX_EYE_COLORS, val => {
            creationData.appearance.eyeColor = val;
            post('updateEyeColor', { color: val });
        });

        bindStepNav();
    }

    // ============================================================
    // STEP 5 — CLOTHING
    // ============================================================
    function renderStepClothing() {
        post('switchCamera', { cam: 'full' });

        const comps = creationData.appearance.components;
        const props = creationData.appearance.props;

        let html = buildStepBar();
        html += '<div class="char-step-content"><div class="char-step-body">';

        html += `<div class="char-section-title">Vetements</div>`;
        html += '<div class="char-clothing-grid">';
        for (const [id, label] of Object.entries(COMP_LABELS)) {
            const maxD = (maxData['comp_' + id] || 1) - 1;
            const cur = (comps[id] && comps[id].drawable) || 0;
            const curT = (comps[id] && comps[id].texture) || 0;
            const maxT = 0;
            html += buildClothingCard(`comp-${id}`, label, cur, maxD, curT, maxT, false);
        }
        html += '</div>';

        html += `<div class="char-section-title">Accessoires</div>`;
        html += '<div class="char-clothing-grid">';
        for (const [id, label] of Object.entries(PROP_LABELS)) {
            const maxD = (maxData['prop_' + id] || 0) - 1;
            const cur = (props[id] && props[id].drawable !== undefined) ? props[id].drawable : -1;
            const curT = (props[id] && props[id].texture) || 0;
            html += buildClothingCard(`prop-${id}`, label, cur, maxD, curT, 0, true);
        }
        html += '</div>';

        html += buildStepNav(true, 'Suivant');
        html += '</div></div>';
        charContent.innerHTML = html;
        bindStepDots();

        // Bind components
        for (const id of Object.keys(COMP_LABELS)) {
            const maxD = (maxData['comp_' + id] || 1) - 1;
            bindClothingCard(`comp-${id}`, maxD, false, (drawable, texture) => {
                if (!comps[id]) comps[id] = { drawable: 0, texture: 0 };
                comps[id].drawable = drawable;
                comps[id].texture = texture;
                return post('updateComponent', { id: parseInt(id), drawable, texture });
            });
        }

        // Bind props
        for (const id of Object.keys(PROP_LABELS)) {
            const maxD = (maxData['prop_' + id] || 0) - 1;
            bindClothingCard(`prop-${id}`, maxD, true, (drawable, texture) => {
                if (!props[id]) props[id] = { drawable: -1, texture: 0 };
                props[id].drawable = drawable;
                props[id].texture = texture;
                return post('updateProp', { id: parseInt(id), drawable, texture });
            });
        }

        bindStepNav();
    }

    // ============================================================
    // STEP 6 — OVERLAYS
    // ============================================================
    function renderStepOverlays() {
        post('switchCamera', { cam: 'face' });

        const overlays = creationData.appearance.overlays;

        let html = buildStepBar();
        html += '<div class="char-step-content"><div class="char-step-body">';

        for (const [idStr, label] of Object.entries(OVERLAY_LABELS)) {
            const id = parseInt(idStr);
            const ov = overlays[id] || { index: -1, opacity: 1.0, color: 0 };

            html += `<div class="char-overlay-group">`;
            html += buildArrowSelector(`ov-${id}`, label, ov.index, -1, 15, v => v < 0 ? 'Aucun' : `#${v}`);
            html += buildSlider(`ov-${id}-opa`, 'Opacite', ov.opacity, 0, 1, 0.1, v => Math.round(v * 100) + '%');
            // Color for makeup overlays (4, 5, 8)
            if (id === 4 || id === 5 || id === 8) {
                html += buildArrowSelector(`ov-${id}-color`, 'Couleur', ov.color || 0, 0, MAX_HAIR_COLORS);
            }
            html += `</div>`;
        }

        html += buildStepNav(true, 'Suivant');
        html += '</div></div>';
        charContent.innerHTML = html;
        bindStepDots();

        for (const idStr of Object.keys(OVERLAY_LABELS)) {
            const id = parseInt(idStr);

            bindArrowSelector(`ov-${id}`, -1, 15, val => {
                if (!overlays[id]) overlays[id] = { index: -1, opacity: 1.0 };
                overlays[id].index = val;
                post('updateOverlay', { id, index: val, opacity: overlays[id].opacity, color: overlays[id].color });
            });

            bindSlider(`ov-${id}-opa`, val => {
                if (!overlays[id]) overlays[id] = { index: -1, opacity: 1.0 };
                overlays[id].opacity = val;
                if (overlays[id].index >= 0) {
                    post('updateOverlay', { id, index: overlays[id].index, opacity: val, color: overlays[id].color });
                }
            });

            if (id === 4 || id === 5 || id === 8) {
                bindArrowSelector(`ov-${id}-color`, 0, MAX_HAIR_COLORS, val => {
                    if (!overlays[id]) overlays[id] = { index: -1, opacity: 1.0 };
                    overlays[id].color = val;
                    if (overlays[id].index >= 0) {
                        post('updateOverlay', { id, index: overlays[id].index, opacity: overlays[id].opacity, color: val });
                    }
                });
            }
        }

        bindStepNav();
    }

    // ============================================================
    // STEP 7 — CONFIRMATION
    // ============================================================
    function renderStepConfirm() {
        post('switchCamera', { cam: 'full' });

        let html = buildStepBar();
        html += '<div class="char-step-content">';
        html += `<div class="char-recap">
            <div class="char-recap-name">${esc(creationData.firstname)} ${esc(creationData.lastname)}</div>
            <div class="char-recap-info">${formatDob(creationData.dateofbirth)} &mdash; ${creationData.gender === 'male' ? 'Homme' : 'Femme'}</div>
            <div class="char-recap-hint">Verifiez votre personnage avant de confirmer</div>
        </div>`;
        html += buildStepNav(true, 'confirm');
        html += '</div>';

        charContent.innerHTML = html;
        bindStepDots();

        const prev = document.getElementById('step-prev');
        if (prev) prev.addEventListener('click', () => { creationStep--; renderStep(); });

        const next = document.getElementById('step-next');
        if (next) {
            next.addEventListener('click', () => {
                next.disabled = true;
                next.textContent = 'Creation...';
                post('finishCreation', {
                    firstname: creationData.firstname,
                    lastname: creationData.lastname,
                    dateofbirth: creationData.dateofbirth,
                    gender: creationData.gender,
                    appearance: creationData.appearance,
                });
            });
        }
    }

    // ============================================================
    // UI BUILDERS
    // ============================================================
    function buildSlider(id, label, value, min, max, step, format) {
        const displayVal = format ? format(value) : value;
        return `<div class="char-slider-group">
            <div class="char-slider-header">
                <span class="char-slider-label">${label}</span>
                <span class="char-slider-value" id="${id}-val">${displayVal}</span>
            </div>
            <input type="range" class="char-slider" id="${id}" min="${min}" max="${max}" step="${step}" value="${value}" />
        </div>`;
    }

    function bindSlider(id, onChange) {
        const slider = document.getElementById(id);
        const valEl = document.getElementById(id + '-val');
        if (!slider) return;

        const format = slider.step == '0.05' || slider.step == '0.1'
            ? v => { const n = parseFloat(v); return slider.max == '1' ? Math.round(n * 100) + '%' : n.toFixed(1); }
            : v => v;

        slider.addEventListener('input', () => {
            const val = parseFloat(slider.value);
            if (valEl) valEl.textContent = format(val);
            if (onChange) onChange(val);
        });
    }

    function buildArrowSelector(id, label, value, min, max, format) {
        const displayVal = format ? format(value) : `#${value}`;
        return `<div class="char-slider-group">
            <div class="char-slider-label">${label}</div>
            <div class="char-arrows" id="${id}-arrows" data-min="${min}" data-max="${max}" data-val="${value}">
                <button class="char-arrow-btn" data-dir="-1">&lt;</button>
                <span class="char-arrow-val" id="${id}-val">${displayVal}</span>
                <button class="char-arrow-btn" data-dir="1">&gt;</button>
            </div>
        </div>`;
    }

    function bindArrowSelector(id, min, max, onChange, format) {
        const container = document.getElementById(id + '-arrows');
        if (!container) return;
        const valEl = document.getElementById(id + '-val');

        const fmt = format || (container.dataset.min === '-1'
            ? v => v < 0 ? 'Aucun' : `#${v}`
            : v => {
                // Check if this is a parent selector
                if (id === 'heritage-mother' || id === 'heritage-father') {
                    return PARENT_NAMES[v] || `#${v}`;
                }
                return `#${v}`;
            });

        container.querySelectorAll('.char-arrow-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                let val = parseInt(container.dataset.val);
                const dir = parseInt(btn.dataset.dir);
                const curMax = parseInt(container.dataset.max);
                const curMin = parseInt(container.dataset.min);
                val += dir;
                if (val > curMax) val = curMin;
                if (val < curMin) val = curMax;
                container.dataset.val = val;
                if (valEl) valEl.textContent = fmt(val);
                if (onChange) onChange(val);
            });
        });
    }

    function updateArrowMax(id, newMax) {
        const container = document.getElementById(id + '-arrows');
        if (container) container.dataset.max = newMax;
    }

    function updateArrowValue(id, val) {
        const container = document.getElementById(id + '-arrows');
        if (!container) return;
        container.dataset.val = val;
        const valEl = document.getElementById(id + '-val');
        if (valEl) valEl.textContent = `#${val}`;
    }

    // ============================================================
    // CLOTHING CARD
    // ============================================================
    function buildClothingCard(id, label, drawable, maxDrawable, texture, maxTexture, isProp) {
        const minD = isProp ? -1 : 0;
        const displayD = isProp && drawable < 0 ? 'Aucun' : `${drawable} / ${maxDrawable}`;
        return `<div class="char-cloth-card" id="${id}-card" data-drawable="${drawable}" data-texture="${texture}" data-max-d="${maxDrawable}" data-max-t="${maxTexture}" data-min-d="${minD}">
            <div class="char-cloth-label">${label}</div>
            <div class="char-cloth-preview">
                <button class="char-cloth-arrow left" data-target="drawable" data-dir="-1">&#8249;</button>
                <div class="char-cloth-info">
                    <span class="char-cloth-drawable" id="${id}-d-val">${displayD}</span>
                    <span class="char-cloth-texture" id="${id}-t-val">Var. ${texture}</span>
                </div>
                <button class="char-cloth-arrow right" data-target="drawable" data-dir="1">&#8250;</button>
            </div>
            <div class="char-cloth-tex-row">
                <button class="char-cloth-tex-btn" data-dir="-1">&#8249;</button>
                <span class="char-cloth-tex-label">Variante</span>
                <button class="char-cloth-tex-btn" data-dir="1">&#8250;</button>
            </div>
        </div>`;
    }

    function bindClothingCard(id, maxDrawable, isProp, onChange) {
        const card = document.getElementById(id + '-card');
        if (!card) return;
        const dValEl = document.getElementById(id + '-d-val');
        const tValEl = document.getElementById(id + '-t-val');
        const minD = isProp ? -1 : 0;

        function updateDisplay() {
            const d = parseInt(card.dataset.drawable);
            const t = parseInt(card.dataset.texture);
            const mD = parseInt(card.dataset.maxD);
            if (dValEl) dValEl.textContent = isProp && d < 0 ? 'Aucun' : `${d} / ${mD}`;
            if (tValEl) tValEl.textContent = `Var. ${t}`;
        }

        // Drawable arrows
        card.querySelectorAll('.char-cloth-arrow').forEach(btn => {
            btn.addEventListener('click', () => {
                let d = parseInt(card.dataset.drawable);
                const dir = parseInt(btn.dataset.dir);
                const mD = parseInt(card.dataset.maxD);
                d += dir;
                if (d > mD) d = minD;
                if (d < minD) d = mD;
                card.dataset.drawable = d;
                card.dataset.texture = 0;
                updateDisplay();
                onChange(d, 0).then(res => {
                    const maxT = (res && res.maxTextures) || 0;
                    card.dataset.maxT = maxT > 0 ? maxT - 1 : 0;
                    card.dataset.texture = 0;
                    updateDisplay();
                });
            });
        });

        // Texture arrows
        card.querySelectorAll('.char-cloth-tex-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const d = parseInt(card.dataset.drawable);
                if (isProp && d < 0) return;
                let t = parseInt(card.dataset.texture);
                const mT = parseInt(card.dataset.maxT) || 0;
                const dir = parseInt(btn.dataset.dir);
                t += dir;
                if (t > mT) t = 0;
                if (t < 0) t = mT;
                card.dataset.texture = t;
                updateDisplay();
                onChange(d, t);
            });
        });
    }

    // ============================================================
    // DELETE CONFIRMATION
    // ============================================================
    function showDeleteConfirm(id, name) {
        charConfirmText.textContent = `Supprimer ${name} ? Cette action est irreversible.`;
        charConfirm.classList.remove('hidden');

        const yesHandler = () => {
            post('deleteCharacter', { id });
            charConfirm.classList.add('hidden');
            cleanup();
        };
        const noHandler = () => {
            charConfirm.classList.add('hidden');
            cleanup();
        };
        const cleanup = () => {
            charConfirmYes.removeEventListener('click', yesHandler);
            charConfirmNo.removeEventListener('click', noHandler);
        };

        charConfirmYes.addEventListener('click', yesHandler);
        charConfirmNo.addEventListener('click', noHandler);
    }

    // ============================================================
    // MESSAGE HANDLER
    // ============================================================
    window.addEventListener('message', (event) => {
        const d = event.data || {};
        switch (d.action) {
            case 'showCharacterSelect':
                characters = d.characters || [];
                canCreate = !!d.canCreate;
                mustCreate = false;
                renderList();
                charScreen.classList.remove('hidden');
                break;

            case 'showCharacterCreate':
                characters = [];
                canCreate = true;
                mustCreate = !!d.mustCreate;
                startCreation(mustCreate);
                charScreen.classList.remove('hidden');
                break;

            case 'hideCharacterScreen':
                charScreen.classList.add('hidden');
                charScreen.classList.remove('creation-mode');
                charConfirm.classList.add('hidden');
                break;

            case 'updateCharacterList':
                characters = d.characters || [];
                canCreate = !!d.canCreate;
                renderList();
                break;
        }
    });
})();
