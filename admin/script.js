// Initialize Supabase
// IMPORTANT: The Supabase CDN exposes a global `supabase` object.
// Do NOT shadow it (e.g. `const supabase = supabase.createClient(...)`) because
// it triggers a Temporal Dead Zone ReferenceError and the whole script stops.
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// State
let currentUser = null;
let allVideos = [];
let allReports = [];
let allCategories = [];
let allContacts = [];
let allUsers = [];

function validateBunnyConfig() {
    // Optional until the user tries to upload.
    const zoneOk = typeof BUNNY_STORAGE_ZONE === 'string' && BUNNY_STORAGE_ZONE.trim().length > 0;
    const keyOk = typeof BUNNY_ACCESS_KEY === 'string' && BUNNY_ACCESS_KEY.trim().length > 0;
    const cdnOk = typeof BUNNY_CDN_BASE === 'string' && BUNNY_CDN_BASE.trim().startsWith('http');
    return zoneOk && keyOk && cdnOk;
}

function safeFilename(name) {
    const cleaned = String(name ?? 'file')
        .replace(/[^a-zA-Z0-9._-]+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_+|_+$/g, '');
    return cleaned || 'file';
}

function formatHms(totalSeconds) {
    if (!Number.isFinite(totalSeconds) || totalSeconds <= 0) return '00:00';
    const seconds = Math.floor(totalSeconds);
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    const mm = String(m).padStart(2, '0');
    const ss = String(s).padStart(2, '0');
    return h > 0 ? `${String(h).padStart(2, '0')}:${mm}:${ss}` : `${mm}:${ss}`;
}

function parseCategoryColorToCss(colorValue) {
    // DB stores `color` as text like '0xFFFFD600' (preferred) or sometimes as an int.
    if (colorValue == null) return '#000000';
    if (typeof colorValue === 'number' && Number.isFinite(colorValue)) {
        const hex = (colorValue >>> 0).toString(16).padStart(8, '0').toUpperCase();
        return '#' + hex.slice(2);
    }

    const s = String(colorValue).trim();
    if (!s) return '#000000';

    // Accept '#RRGGBB'
    if (s.startsWith('#') && s.length >= 7) return s.substring(0, 7);

    // Accept '0xAARRGGBB'
    if (s.startsWith('0x') || s.startsWith('0X')) {
        const hex = s.replace(/^0x/i, '').padStart(8, '0').toUpperCase();
        return '#' + hex.slice(2);
    }

    // Fallback: try parse as base-16
    const parsed = parseInt(s, 16);
    if (Number.isFinite(parsed)) {
        const hex = (parsed >>> 0).toString(16).padStart(8, '0').toUpperCase();
        return '#' + hex.slice(2);
    }

    return '#000000';
}

function getVideoDurationSeconds(file) {
    return new Promise((resolve, reject) => {
        try {
            const url = URL.createObjectURL(file);
            const video = document.createElement('video');
            video.preload = 'metadata';
            video.onloadedmetadata = () => {
                const duration = video.duration;
                URL.revokeObjectURL(url);
                resolve(duration);
            };
            video.onerror = () => {
                URL.revokeObjectURL(url);
                reject(new Error('Could not read video duration from selected file.'));
            };
            video.src = url;
        } catch (e) {
            reject(e);
        }
    });
}

async function uploadToBunny(path, file) {
    if (!validateBunnyConfig()) {
        throw new Error('Bunny config missing. Set BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE in admin/config.js');
    }

    const cleanPath = String(path).replace(/^\/+/, '');
    const url = `https://storage.bunnycdn.com/${encodeURIComponent(BUNNY_STORAGE_ZONE)}/${cleanPath}`;
    const resp = await fetch(url, {
        method: 'PUT',
        headers: {
            'AccessKey': BUNNY_ACCESS_KEY,
            'Content-Type': file.type || 'application/octet-stream',
        },
        body: file,
    });

    if (!resp.ok) {
        const body = await resp.text().catch(() => '');
        throw new Error(`Bunny upload failed (${resp.status}). ${body}`);
    }

    return cleanPath;
}

async function uploadToBunnyWithProgress(path, file, onProgress) {
    if (!validateBunnyConfig()) {
        throw new Error('Bunny config missing. Set BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE in admin/config.js');
    }

    const cleanPath = String(path).replace(/^\/+/, '');
    const url = `https://storage.bunnycdn.com/${encodeURIComponent(BUNNY_STORAGE_ZONE)}/${cleanPath}`;

    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();

        xhr.upload.addEventListener('progress', (e) => {
            if (e.lengthComputable) {
                const percentComplete = (e.loaded / e.total) * 100;
                onProgress(percentComplete);
            }
        });

        xhr.addEventListener('load', () => {
            if (xhr.status === 200 || xhr.status === 201) {
                onProgress(100);
                resolve(cleanPath);
            } else {
                reject(new Error(`Bunny upload failed (${xhr.status}). ${xhr.responseText}`));
            }
        });

        xhr.addEventListener('error', () => {
            reject(new Error('Network error during upload'));
        });

        xhr.addEventListener('abort', () => {
            reject(new Error('Upload cancelled'));
        });

        xhr.open('PUT', url, true);
        xhr.setRequestHeader('AccessKey', BUNNY_ACCESS_KEY);
        xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
        xhr.send(file);
    });
}

async function deleteBunnyFile(path) {
    if (!validateBunnyConfig()) {
        throw new Error('Bunny config missing. Set BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE in admin/config.js');
    }

    const cleanPath = String(path).replace(/^\/+/, '');
    const url = `https://storage.bunnycdn.com/${encodeURIComponent(BUNNY_STORAGE_ZONE)}/${cleanPath}`;
    
    try {
        const resp = await fetch(url, {
            method: 'DELETE',
            headers: {
                'AccessKey': BUNNY_ACCESS_KEY,
            },
        });

        if (!resp.ok && resp.status !== 404) {
            console.warn(`Bunny delete warning (${resp.status}): ${path}`);
        }
    } catch (e) {
        console.warn('Bunny delete error:', e.message);
    }
}

function validateSupabaseConfig() {
    const errorText = document.getElementById('login-error');
    const urlOk = typeof SUPABASE_URL === 'string' && SUPABASE_URL.startsWith('https://') && SUPABASE_URL.includes('.supabase.co');
    const keyOk = typeof SUPABASE_KEY === 'string' && SUPABASE_KEY.trim().length > 20;

    if (!urlOk || !keyOk) {
        if (errorText) {
            errorText.textContent = 'Supabase config missing/invalid. Set SUPABASE_URL and SUPABASE_KEY in admin/index.html.';
            errorText.classList.remove('hidden');
        }
        return false;
    }

    // Heuristic: most anon keys are JWT-like and long; publishable keys also shouldn’t be tiny.
    if (!(SUPABASE_KEY.startsWith('eyJ') || SUPABASE_KEY.startsWith('sb_'))) {
        if (errorText) {
            errorText.textContent = 'Supabase key format looks wrong. Use the Project API key from Supabase Dashboard → Settings → API.';
            errorText.classList.remove('hidden');
        }
        return false;
    }

    return true;
}

// Auth Logic
async function handleLogin() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const errorText = document.getElementById('login-error');
    errorText.classList.add('hidden');

    if (!validateSupabaseConfig()) return;

    try {
        if (!email || !password) {
            throw new Error('Email and password are required.');
        }

        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });

        if (error) throw error;

        // Check is_admin - IMPORTANT: This query does NOT use RLS
        const { data: userData, error: userError } = await supabaseClient
            .from('users')
            .select('is_admin')
            .eq('id', data.user.id)
            .single();

        if (userError) throw userError;
        if (!userData || userData.is_admin !== true) {
            throw new Error('Unauthorized: Access restricted to admins.');
        }

        currentUser = data.user;
        toggleView(true);
        loadDashboardData('users');

    } catch (err) {
        errorText.textContent = err?.message ?? String(err);
        errorText.classList.remove('hidden');
        if (currentUser) {
             await supabaseClient.auth.signOut();
             currentUser = null;
        }
    }
}

async function handleLogout() {
    await supabaseClient.auth.signOut();
    toggleView(false);
}

// Session Check
window.onload = async () => {
    if (!validateSupabaseConfig()) return;
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (session) {
         // Verify admin again - this query does NOT use RLS
         const { data: userData } = await supabaseClient
            .from('users')
            .select('is_admin')
            .eq('id', session.user.id)
            .single();
        
         if (userData && userData.is_admin) {
             currentUser = session.user;
             toggleView(true);
             loadDashboardData('users');
         } else {
             // Not admin but has session? Sign out.
             await supabaseClient.auth.signOut();
             toggleView(false);
         }
    }
};

function toggleView(isLoggedIn) {
     if (isLoggedIn) {
         document.getElementById('login-container').classList.add('hidden');
         document.getElementById('dashboard-container').classList.remove('hidden');
         document.getElementById('user-display').textContent = currentUser.email;
     } else {
         document.getElementById('login-container').classList.remove('hidden');
         document.getElementById('dashboard-container').classList.add('hidden');
         currentUser = null;
     }
}

// Navigation
function showSection(sectionId) {
    document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
    // Simple way to find the link tapped - in real app, bind ID or use event target closer
    // For now assuming order: 0: Users, 1: Videos, 2: Channels, 3: Categories, 4: Contacts, 5: Mart, 6: Referrals, 7: Reports
    
    ['users', 'videos', 'channels', 'categories', 'contacts', 'mart', 'referrals', 'reports'].forEach(id => {
        document.getElementById(`${id}-section`).classList.add('hidden');
    });
    document.getElementById(`${sectionId}-section`).classList.remove('hidden');
    document.getElementById('section-title').textContent = sectionId.charAt(0).toUpperCase() + sectionId.slice(1);
    
    loadDashboardData(sectionId);

    // On mobile, collapse the sidebar after navigation.
    closeSidebar();
}

function openSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');
    if (!sidebar || !overlay) return;
    sidebar.classList.remove('-translate-x-full');
    overlay.classList.remove('hidden');
}

function closeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');
    if (!sidebar || !overlay) return;
    
    // On mobile, always close.
    // On desktop, we don't auto-close via this function (usually called by overlay click), 
    // unless we strictly want to reset specific states?
    // Current logic: If overlay clicked, it means we are in mobile/overlay mode.
    
    sidebar.classList.add('-translate-x-full');
    overlay.classList.add('hidden');
}

function toggleSidebarInternal() {
    closeSidebar();
}

function toggleSidebarDesktop() {
    const sidebar = document.getElementById('sidebar');
    const content = document.getElementById('main-content');
    
    // Toggle the class valid for desktop
    if (sidebar.classList.contains('md:translate-x-0')) {
        // HIDE
        sidebar.classList.remove('md:translate-x-0'); 
        // Ensure it has the hide class
        sidebar.classList.add('-translate-x-full');
        
        // Adjust content margin
        content.classList.remove('md:ml-64');
        content.classList.add('md:ml-0');
    } else {
        // SHOW
        sidebar.classList.add('md:translate-x-0');
        sidebar.classList.remove('-translate-x-full');
        
        content.classList.add('md:ml-64');
        content.classList.remove('md:ml-0');
    }
}


// Data Loading
async function loadDashboardData(type) {
    if (type === 'users') {
        const { data, error } = await supabaseClient.from('users').select('*');
        if (data) {
            allUsers = data;
            renderUsers(data);
            populateContactsUserFilter();
        }
    } else if (type === 'videos') {
         const { data, error } = await supabaseClient.from('videos').select('*');
         if (data) {
             allVideos = data;
             renderVideos(data);
             populateVideoFilters(); // New function
         }
    } else if (type === 'channels') {
         const { data, error } = await supabaseClient.from('channels').select('*');
         if (data) renderChannels(data);
    } else if (type === 'categories') {
         const { data, error } = await supabaseClient.from('categories').select('*');
         if (data) {
             allCategories = data; // Store internally
             renderCategories(data);
         }
    } else if (type === 'contacts') {
         const { data, error } = await supabaseClient
            .from('contacts')
            .select(`
                id,
                user_id,
                contact_name,
                phone_number,
                email,
                synced_at,
                created_at,
                auth.users(email)
            `)
            .order('synced_at', { ascending: false });
         if (data) {
             allContacts = data;
             renderContacts(data);
             calculateContactsStats(data);
         }
    } else if (type === 'mart') {
         const { data, error } = await supabaseClient.from('mart_videos').select('*').order('display_order', { ascending: true });
         if (data) renderMart(data);
    } else if (type === 'referrals') {
         const { data, error } = await supabaseClient
            .from('referrals')
            .select('*')
            .order('created_at', { ascending: false });
         if (data) renderReferrals(data);
    } else if (type === 'reports') {
         const { data, error } = await supabaseClient
            .from('reports')
            .select('*')
            .order('created_at', { ascending: false });
         if (data) {
             allReports = data;
             renderReports(data);
         }
    }
}

// Search & Filter Logic
function populateVideoFilters() {
    const sel = document.getElementById('video-filter-category');
    if (!sel) return;
    // We need categories loaded. If not loaded, fetch them (or wait).
    // Assuming categories are fetched or we can simulate distinct from videos?
    // Ideally we fetched categories separately. Let's try to just fetch them if empty.
    
    if (allCategories.length === 0) {
        supabaseClient.from('categories').select('*').then(({data}) => {
            if (data) {
                allCategories = data;
                _fillCategoryOptions(sel);
            }
        });
    } else {
        _fillCategoryOptions(sel);
    }
}

function _fillCategoryOptions(selectElement) {
    const currentVal = selectElement.value;
    selectElement.innerHTML = '<option value="">All Categories</option>';
    allCategories.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.name;
        selectElement.appendChild(opt);
    });
    selectElement.value = currentVal;
}

function filterVideos() {
    const query = document.getElementById('video-search').value.toLowerCase();
    const catId = document.getElementById('video-filter-category').value;
    
    const filtered = allVideos.filter(v => {
        const matchesQuery = (
            (v.title && v.title.toLowerCase().includes(query)) ||
            (v.channel_name && v.channel_name.toLowerCase().includes(query)) ||
            (v.id && String(v.id).includes(query))
        );
        const matchesCategory = catId ? (v.category_id === catId) : true;
        return matchesQuery && matchesCategory;
    });
    renderVideos(filtered);
}

function filterReports() {
    const query = document.getElementById('report-search').value.toLowerCase();
    const status = document.getElementById('report-filter-status').value;

    const filtered = allReports.filter(r => {
         const matchesQuery = (
            (r.id && String(r.id).includes(query)) ||
            (r.user_id && String(r.user_id).toLowerCase().includes(query)) ||
            (r.video_id && String(r.video_id).toLowerCase().includes(query)) ||
            (r.reason && String(r.reason).toLowerCase().includes(query))
         );
         const matchesStatus = status ? (r.status === status) : true;
         return matchesQuery && matchesStatus;
    });
    renderReports(filtered);
}

function renderReferrals(referrals) {
    const tbody = document.getElementById('referrals-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';
    referrals.forEach(r => {
        const tr = document.createElement('tr');
        tr.className = 'border-b';
        tr.innerHTML = `
            <td class="p-3 text-sm text-gray-700">${r.id}</td>
            <td class="p-3 text-sm text-gray-700">${r.referrer_id ?? '-'}</td>
            <td class="p-3 text-sm text-gray-700">${r.referred_email ?? '-'}</td>
            <td class="p-3">
                <span class="px-2 py-1 rounded text-xs bg-gray-100 text-gray-800">${r.status ?? 'pending'}</span>
            </td>
            <td class="p-3 text-gray-500 text-sm">${r.created_at ? new Date(r.created_at).toLocaleString() : '-'}</td>
            <td class="p-3">
                <button onclick="showEditReferralModal(${r.id})" class="text-blue-600 text-sm hover:underline mr-3">Edit</button>
                <button onclick="deleteReferral(${r.id})" class="text-red-600 text-sm hover:underline">Delete</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function showEditReferralModal(id) {
    const { data, error } = await supabaseClient.from('referrals').select('*').eq('id', id).single();
    if (error) return alert(error.message);

    document.getElementById('modal-title').textContent = 'Edit Referral';
    document.getElementById('modal-content').innerHTML = `
        <div class="mb-3">
            <div class="text-xs text-gray-500">ID</div>
            <div class="font-mono text-sm">${data.id}</div>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Referrer</label>
            <input id="ref-referrer" class="w-full border p-2 rounded" value="${data.referrer_id ?? ''}" disabled>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Referred</label>
            <input id="ref-referred" class="w-full border p-2 rounded" value="${data.referred_email ?? ''}">
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Status</label>
            <select id="ref-status" class="w-full border p-2 rounded">
                ${['pending','completed','rejected'].map(s => `<option value="${s}" ${String(data.status ?? 'pending')===s?'selected':''}>${s}</option>`).join('')}
            </select>
        </div>
    `;
    const actionBtn = document.getElementById('modal-action-btn');
    actionBtn.textContent = 'Update';
    actionBtn.onclick = async () => {
        const referred = document.getElementById('ref-referred').value;
        const status = document.getElementById('ref-status').value;
        const { error: uerr } = await supabaseClient.from('referrals').update({ referred_email: referred, status }).eq('id', id);
        if (uerr) return alert(uerr.message);
        closeModal();
        loadDashboardData('referrals');
    };
    document.getElementById('modal').classList.remove('hidden');
}

async function deleteReferral(id) {
    if (!confirm('Delete referral?')) return;
    const { error } = await supabaseClient.from('referrals').delete().eq('id', id);
    if (error) return alert(error.message);
    loadDashboardData('referrals');
}

function renderReports(reports) {
    const tbody = document.getElementById('reports-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';
    reports.forEach(r => {
        const tr = document.createElement('tr');
        tr.className = 'border-b';
        const resp = (r.response ?? '').toString();
        tr.innerHTML = `
            <td class="p-3 text-sm text-gray-700">${r.id}</td>
            <td class="p-3 text-sm text-gray-700">${r.user_id ?? '-'}</td>
            <td class="p-3 text-sm text-gray-700">${r.video_id ?? '-'}</td>
            <td class="p-3 text-sm text-gray-700">${(r.reason ?? '').toString().slice(0, 40)}</td>
            <td class="p-3"><span class="px-2 py-1 rounded text-xs bg-gray-100 text-gray-800">${r.status ?? 'open'}</span></td>
            <td class="p-3 text-gray-500 text-sm">${r.created_at ? new Date(r.created_at).toLocaleString() : '-'}</td>
            <td class="p-3 text-sm text-gray-700">${resp ? resp.slice(0, 30) : '<span class="text-gray-400">Waiting…</span>'}</td>
            <td class="p-3">
                <button onclick="showEditReportModal(${r.id})" class="text-blue-600 text-sm hover:underline mr-3">Edit</button>
                <button onclick="deleteReport(${r.id})" class="text-red-600 text-sm hover:underline">Delete</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function showEditReportModal(id) {
    const { data, error } = await supabaseClient.from('reports').select('*').eq('id', id).single();
    if (error) return alert(error.message);

    document.getElementById('modal-title').textContent = 'Edit Report';
    document.getElementById('modal-content').innerHTML = `
        <div class="mb-3">
            <div class="text-xs text-gray-500">ID</div>
            <div class="font-mono text-sm">${data.id}</div>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Status</label>
            <select id="rep-status" class="w-full border p-2 rounded">
                ${['open','pending','resolved','closed'].map(s => `<option value="${s}" ${String(data.status ?? 'open')===s?'selected':''}>${s}</option>`).join('')}
            </select>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Response (Kids Konnect)</label>
            <textarea id="rep-response" class="w-full border p-2 rounded" rows="4" placeholder="Write a response...">${(data.response ?? '').toString()}</textarea>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Reason</label>
            <input class="w-full border p-2 rounded" value="${(data.reason ?? '').toString()}" disabled>
        </div>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Description</label>
            <textarea class="w-full border p-2 rounded" rows="3" disabled>${(data.description ?? '').toString()}</textarea>
        </div>
    `;
    const actionBtn = document.getElementById('modal-action-btn');
    actionBtn.textContent = 'Update';
    actionBtn.onclick = async () => {
        const status = document.getElementById('rep-status').value;
        const response = document.getElementById('rep-response').value;
        const payload = { status, response };
        if (response && response.trim().length > 0) {
            payload.responded_at = new Date().toISOString();
        }
        const { error: uerr } = await supabaseClient.from('reports').update(payload).eq('id', id);
        if (uerr) return alert(uerr.message);
        closeModal();
        loadDashboardData('reports');
    };
    document.getElementById('modal').classList.remove('hidden');
}

async function deleteReport(id) {
    if (!confirm('Delete report?')) return;
    const { error } = await supabaseClient.from('reports').delete().eq('id', id);
    if (error) return alert(error.message);
    loadDashboardData('reports');
}

// Render Users
function renderUsers(users) {
    const tbody = document.getElementById('users-table-body');
    tbody.innerHTML = '';
    users.forEach(user => {
        const tr = document.createElement('tr');
        tr.className = 'border-b';
        const lastLogin = user.last_login ? new Date(user.last_login).toLocaleDateString() : '-';
        const watchTime = user.total_watch_time_seconds ? Math.floor(user.total_watch_time_seconds / 60) + ' min' : '-';
        tr.innerHTML = `
            <td class="p-3">${user.email}</td>
            <td class="p-3">
                <span class="px-2 py-1 rounded text-xs ${user.is_admin ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-800'}">
                    ${user.is_admin ? 'Admin' : 'User'}
                </span>
            </td>
            <td class="p-3 text-gray-500 text-sm">${new Date(user.created_at).toLocaleDateString()}</td>
            <td class="p-3 text-gray-500 text-sm">${lastLogin}</td>
            <td class="p-3 text-gray-500 text-sm">${user.total_profiles || 0}</td>
            <td class="p-3 text-gray-500 text-sm">${watchTime}</td>
            <td class="p-3">
                 <button onclick="toggleAdmin('${user.id}', ${!user.is_admin})" class="text-blue-600 text-sm hover:underline">
                    ${user.is_admin ? 'Revoke Admin' : 'Make Admin'}
                 </button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function renderContacts(contacts) {
    const tbody = document.getElementById('contacts-table-body');
    tbody.innerHTML = '';
    contacts.forEach(contact => {
        const tr = document.createElement('tr');
        tr.className = 'border-b hover:bg-gray-50';
        const syncedAt = contact.synced_at ? new Date(contact.synced_at).toLocaleString() : '-';
        const userEmail = contact.auth?.email || 'Unknown';
        tr.innerHTML = `
            <td class="p-3 font-medium">${contact.contact_name}</td>
            <td class="p-3">${contact.phone_number ? `<a href="tel:${contact.phone_number}" class="text-blue-600 hover:underline">${contact.phone_number}</a>` : '-'}</td>
            <td class="p-3">${contact.email ? `<a href="mailto:${contact.email}" class="text-blue-600 hover:underline">${contact.email}</a>` : '-'}</td>
            <td class="p-3 text-sm text-gray-600">${userEmail}</td>
            <td class="p-3 text-sm text-gray-500">${syncedAt}</td>
            <td class="p-3">
                <button onclick="deleteContact('${contact.id}')" class="text-red-600 text-sm hover:underline">Delete</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function populateContactsUserFilter() {
    const sel = document.getElementById('contacts-filter-user');
    if (!sel) return;
    
    const currentVal = sel.value;
    sel.innerHTML = '<option value="">All Users</option>';
    
    // Get unique users from contacts
    const uniqueUsers = [];
    const userIds = new Set();
    
    allContacts.forEach(c => {
        if (!userIds.has(c.user_id)) {
            userIds.add(c.user_id);
            uniqueUsers.push({
                id: c.user_id,
                email: c.auth?.email || 'Unknown'
            });
        }
    });
    
    uniqueUsers.forEach(user => {
        const opt = document.createElement('option');
        opt.value = user.id;
        opt.textContent = user.email;
        sel.appendChild(opt);
    });
    
    sel.value = currentVal;
}

function filterContacts() {
    const query = document.getElementById('contacts-search').value.toLowerCase();
    const filterType = document.getElementById('contacts-filter-type').value;
    const userId = document.getElementById('contacts-filter-user').value;
    
    const filtered = allContacts.filter(c => {
        const matchesQuery = (
            (c.contact_name && c.contact_name.toLowerCase().includes(query)) ||
            (c.phone_number && c.phone_number.includes(query)) ||
            (c.email && c.email.toLowerCase().includes(query))
        );
        
        const matchesType = !filterType || 
            (filterType === 'phone' && c.phone_number) ||
            (filterType === 'email' && c.email);
        
        const matchesUser = !userId || c.user_id === userId;
        
        return matchesQuery && matchesType && matchesUser;
    });
    
    renderContacts(filtered);
}

function calculateContactsStats(contacts) {
    const totalContacts = contacts.length;
    const withPhone = contacts.filter(c => c.phone_number).length;
    const withEmail = contacts.filter(c => c.email).length;
    const uniqueUsers = new Set(contacts.map(c => c.user_id)).size;
    
    document.getElementById('total-contacts').textContent = totalContacts;
    document.getElementById('contacts-with-phone').textContent = withPhone;
    document.getElementById('contacts-with-email').textContent = withEmail;
    document.getElementById('unique-users').textContent = uniqueUsers;
}

async function deleteContact(contactId) {
    if (!confirm('Are you sure you want to delete this contact?')) return;
    
    const { error } = await supabaseClient.from('contacts').delete().eq('id', contactId);
    if (error) {
        alert('Error: ' + error.message);
        return;
    }
    
    loadDashboardData('contacts');
}


function renderVideos(videos) {
    const grid = document.getElementById('videos-grid');
    grid.innerHTML = '';
    videos.forEach(video => {
        const div = document.createElement('div');
        div.className = 'border rounded p-3 flex flex-col gap-2';
        const isShorts = video.is_shorts === true;
        div.innerHTML = `
            <div class="h-32 bg-gray-200 rounded relative overflow-hidden">
                ${video.thumbnail_path ? `<img src="${getBunnyUrl(video.thumbnail_path)}" class="w-full h-full object-cover">` : `<div class="w-full h-full flex items-center justify-center text-gray-500 text-sm">No Thumbnail</div>`}
                 <div class="absolute bottom-1 right-1 bg-black bg-opacity-75 text-white text-xs px-1 rounded">
                    ${video.duration}
                 </div>
                 <div class="absolute top-1 right-1 bg-blue-700 bg-opacity-90 text-white text-[10px] px-2 py-0.5 rounded font-mono">ID: ${video.id}</div>
                 ${isShorts ? `<div class="absolute top-1 left-1 bg-purple-700 bg-opacity-90 text-white text-[10px] px-2 py-0.5 rounded">SHORTS</div>` : ''}
            </div>
            <h4 class="font-bold truncate">${video.title}</h4>
            <div class="text-xs text-gray-500">${video.channel_name}</div>
            <div class="text-xs text-blue-600 font-mono">Video ID: ${video.id}</div>
            <div class="grid grid-cols-2 gap-1 text-xs">
                <div class="flex items-center gap-1"><span class="text-blue-600">👁️ ${video.views || 0}</span></div>
                <div class="flex items-center gap-1"><span class="text-green-600">👍 ${video.likes || 0}</span></div>
                <div class="flex items-center gap-1"><span class="text-red-600">👎 ${video.dislikes || 0}</span></div>
                <div class="flex items-center gap-1"><span class="text-orange-600">⏱️ ${(video.avg_watch_duration_seconds || 0).toFixed(1)}s</span></div>
            </div>
            <div class="flex gap-2">
                <button onclick="showEditVideoModal(${video.id})" class="text-blue-500 text-sm flex-1">Edit</button>
                <button onclick="deleteVideo(${video.id})" class="text-red-500 text-sm flex-1">Delete</button>
            </div>
        `;
        grid.appendChild(div);
    });
}

// Render Channels
function renderChannels(channels) {
    const grid = document.getElementById('channels-grid');
    grid.innerHTML = '';
    channels.forEach(channel => {
        const div = document.createElement('div');
        const avatarUrl = channel.avatar_path ? getBunnyUrl(channel.avatar_path) : '';

        div.className = 'border rounded p-3 flex flex-col gap-3 w-full';
        div.innerHTML = `
            ${avatarUrl ? `
                <img src="${avatarUrl}" alt="${channel.name}" class="w-full h-40 rounded object-cover bg-gray-100" />
            ` : `
                <div class="w-full h-40 rounded bg-gray-200 flex items-center justify-center">
                    <span class="text-gray-500 text-sm">No Avatar</span>
                </div>
            `}
            <div>
              <span class="font-bold text-lg">${channel.name}</span>
              <p class="text-xs text-gray-600 mt-1">${channel.description || 'No description'}</p>
              <span class="text-xs text-gray-500 block mt-2">ID: ${channel.id}</span>
            </div>
            <div class="flex gap-2">
                <button onclick="showEditChannelModal(${channel.id})" class="text-blue-500 text-sm flex-1">Edit</button>
                <button onclick="deleteChannel(${channel.id})" class="text-red-500 text-sm flex-1">Delete</button>
            </div>
        `;
        grid.appendChild(div);
    });
}

// Render Categories
function renderCategories(categories) {
    const grid = document.getElementById('categories-grid');
    grid.innerHTML = '';
    categories.forEach(cat => {
        const div = document.createElement('div');
        const hex = parseCategoryColorToCss(cat.color);
        const iconPath = cat.icon_path ?? cat.icon_url ?? null;
        const iconUrl = iconPath ? getBunnyUrl(iconPath) : '';

        div.className = 'border rounded p-3 flex items-center gap-3 w-full sm:w-72';
        div.innerHTML = `
            ${iconUrl ? `
                <img src="${iconUrl}" alt="${cat.name}" class="w-10 h-10 rounded object-cover bg-gray-100" />
            ` : `
                <div class="w-10 h-10 rounded-full" style="background-color: ${hex}"></div>
            `}
            <div class="flex flex-col">
              <span class="font-medium leading-tight">${cat.name}</span>
              <span class="text-xs text-gray-500">ID: ${cat.id}</span>
            </div>
            <button onclick="deleteCategory(${cat.id})" class="ml-auto text-red-500">&times;</button>
        `;
        grid.appendChild(div);
    });
}

// Actions
async function toggleAdmin(id, newStatus) {
    const { error } = await supabaseClient.from('users').update({ is_admin: newStatus }).eq('id', id);
    if (error) alert(error.message);
    else loadDashboardData('users');
}

async function deleteVideo(id) {
    if(!confirm("Delete video?")) return;
    try {
        // First fetch video to get file paths
        const { data: videoData, error: fetchError } = await supabaseClient
            .from('videos')
            .select('thumbnail_path, video_path, channel_avatar_path')
            .eq('id', id)
            .single();
        
        if (fetchError) {
            alert('Error fetching video: ' + fetchError.message);
            return;
        }

        // Delete from Bunny storage
        if (videoData.thumbnail_path) {
            await deleteBunnyFile(videoData.thumbnail_path);
        }
        if (videoData.video_path) {
            await deleteBunnyFile(videoData.video_path);
        }
        if (videoData.channel_avatar_path) {
            await deleteBunnyFile(videoData.channel_avatar_path);
        }

        // Delete from database
        const { error } = await supabaseClient.from('videos').delete().eq('id', id);
        if (error) {
            alert('Error deleting video from database: ' + error.message);
        } else {
            alert('Video deleted successfully');
            loadDashboardData('videos');
        }
    } catch (e) {
        alert('Error: ' + e.message);
    }
}

async function deleteCategory(id) {
     if(!confirm("Delete category?")) return;
    const { error } = await supabaseClient.from('categories').delete().eq('id', id);
    if (!error) loadDashboardData('categories');
}

// Channel Functions
async function deleteChannel(id) {
     if(!confirm("Delete channel?")) return;
    try {
        const { error } = await supabaseClient.from('channels').delete().eq('id', id);
        if (error) {
            alert('Error deleting channel: ' + error.message);
        } else {
            alert('Channel deleted successfully');
            loadDashboardData('channels');
        }
    } catch (e) {
        alert('Error: ' + e.message);
    }
}

// Modals
function closeModal() {
    document.getElementById('modal').classList.add('hidden');
}

function showAddUserModal() {
    const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Add User";
    document.getElementById('modal-content').innerHTML = `
        <p class="text-sm text-gray-600 mb-4">Note: This will create a user in Auth system. You must sign out to test login.</p>
        <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Email</label>
            <input id="new-email" type="email" class="w-full border p-2 rounded">
        </div>
         <div class="mb-3">
            <label class="block text-sm font-bold mb-1">Password</label>
            <input id="new-password" type="password" class="w-full border p-2 rounded">
        </div>
        <div class="flex items-center gap-2">
            <input type="checkbox" id="new-is-admin">
            <label>Is Admin?</label>
        </div>
    `;
    
    document.getElementById('modal-action-btn').onclick = async () => {
        const email = document.getElementById('new-email').value;
        const password = document.getElementById('new-password').value;
        const isAdmin = document.getElementById('new-is-admin').checked;
        
        // As a client, we can only SignUp using our own session (swapping) or just signUp (Auth API).
        // Standard supabase client signUp logs the *current* user out if successful sometimes or returns session.
        // Actually, supabase.auth.signUp creates a user but may start a session.
        // It's tricky in a pure SPA admin panel without backend functions to "create user without login".
        // Workaround: We use a second client instance with a totally different storage key? No.
        // We will TRY to just call signUp. If it signs us in, we handle it. (Actually it usually returns session).
        // ALERT: The prompt asked for "Add user option". 
        // CORRECT WAY: Call a Supabase Edge Function that uses Service Role Key to create user.
        // HACK WAY (Client side only): Sign up, it might replace session.
        
        alert("To create users properly without logging out the admin, you should use Supabase Edge Functions. \n\nFor this demo, we will attempt signUp, but it might affect your session.");
        
        const { data, error } = await supabaseClient.auth.signUp({
            email,
            password,
            // We can't set public table data here directly in signup call safely unless trigger handles it
            // Our trigger handles insert to public.users with Default FALSE.
        });

        if (error) {
            alert(error.message);
        } else {
            // If we are still logged in as admin (check session), update the new user's admin status
            // If SignUp logic auto-logs in the new user, we lost admin session. 
            // supabase.auth.signUp documentation says: "If email confirmation is enabled... user is not signed in". 
            // If disabled, it returns session. 
            
            // Assume we can't easily do this in pure client JS without losing session unless we use a secondary Supabase client instance that doesn't persist session?
            
            // Let's try to update the is_admin if we have the ID and are still admin.
            if (data.user && isAdmin) {
                 // Wait a bit for trigger
                 setTimeout(async () => {
                     // We need to be admin to do this.
                     const { error: updateError } = await supabaseClient.from('users').update({ is_admin: true }).eq('id', data.user.id);
                     if (updateError) console.error(updateError);
                     else {
                         alert("User created and set as Admin!");
                         loadDashboardData('users');
                         closeModal();
                     }
                 }, 2000);
            } else {
                alert("User created via Auth! (Admin status update might require re-login if session was lost)");
                closeModal();
            }
        }
    };
    
    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function showAddVideoModal() {
     const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Add Video";
    document.getElementById('modal-content').innerHTML = `
                <div class="space-y-3">
                    <input id="v-title" placeholder="Title" class="w-full border p-2 rounded">
                    
                    <div>
                        <label class="block text-sm font-bold mb-1">Channel</label>
                        <select id="v-channel" class="w-full border p-2 rounded">
                            <option value="">Loading channels...</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-bold mb-1">Content Level</label>
                        <select id="v-content-level" class="w-full border p-2 rounded">
                            <option value="Preschool">Preschool</option>
                            <option value="Younger">Younger</option>
                        </select>
                    </div>

                    <div class="flex items-center gap-2">
                        <input id="v-is-shorts" type="checkbox" class="h-4 w-4">
                        <label for="v-is-shorts" class="text-sm font-medium">Is Shorts?</label>
                    </div>

                    <div>
                        <label class="block text-sm font-bold mb-1">Category</label>
                        <select id="v-cat-id" class="w-full border p-2 rounded">
                            <option value="">Loading categories...</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-bold mb-1">Thumbnail (optional)</label>
                        <input id="v-thumb-file" type="file" accept="image/*" class="w-full border p-2 rounded bg-white">
                        <p class="text-xs text-gray-500 mt-1">Optional: Leave empty to upload without thumbnail.</p>
                    </div>

                    <div>
                        <label class="block text-sm font-bold mb-1">Video File (required)</label>
                        <input id="v-video-file" type="file" accept="video/*" class="w-full border p-2 rounded bg-white">
                        <p class="text-xs text-gray-500 mt-1">Duration will be detected automatically.</p>
                        <p id="v-duration-display" class="text-sm mt-1">Duration: -</p>
                    </div>

                    <p id="v-upload-status" class="text-sm text-gray-600 hidden"></p>

                    <div class="text-xs text-gray-500">
                        Bunny folders expected: <b>videos/</b>, <b>images/avatars/</b>, <b>images/thumbnails/</b>
                    </div>
                </div>
    `;

        // Load channels and categories into selects
        (async () => {
                const channelSelectEl = document.getElementById('v-channel');
                const { data: channelData, error: channelError } = await supabaseClient
                        .from('channels')
                        .select('id,name')
                        .order('name', { ascending: true });
                if (channelError) {
                        channelSelectEl.innerHTML = `<option value="">Failed to load channels</option>`;
                } else {
                        const opts = (channelData ?? []).map(c => `<option value="${c.name}">${c.name}</option>`);
                        channelSelectEl.innerHTML = `<option value="">Select channel</option>` + opts.join('');
                }

                const selectEl = document.getElementById('v-cat-id');
                const { data, error } = await supabaseClient
                        .from('categories')
                        .select('id,name')
                        .order('id', { ascending: true });
                if (error) {
                        selectEl.innerHTML = `<option value="">Failed to load categories</option>`;
                        return;
                }

                const opts = (data ?? []).map(c => `<option value="${c.id}">${c.id} - ${c.name}</option>`);
                selectEl.innerHTML = `<option value="">Select category</option>` + opts.join('');
        })();

        // Auto duration when selecting video
        const videoInput = document.getElementById('v-video-file');
        const durationEl = document.getElementById('v-duration-display');
        let computedDurationSeconds = null;
        videoInput.addEventListener('change', async () => {
                computedDurationSeconds = null;
                durationEl.textContent = 'Duration: detecting...';
                const file = videoInput.files && videoInput.files[0];
                if (!file) {
                        durationEl.textContent = 'Duration: -';
                        return;
                }
                try {
                        const seconds = await getVideoDurationSeconds(file);
                        computedDurationSeconds = seconds;
                        durationEl.textContent = `Duration: ${formatHms(seconds)}`;
                } catch (e) {
                        durationEl.textContent = 'Duration: (failed to detect)';
                }
        });
    
    document.getElementById('modal-action-btn').onclick = async () => {
        const btn = document.getElementById('modal-action-btn');
        const statusEl = document.getElementById('v-upload-status');
        statusEl.classList.remove('hidden');

        const title = document.getElementById('v-title').value.trim();
        const channel_name = document.getElementById('v-channel').value.trim();
        const content_level = document.getElementById('v-content-level')?.value ?? 'Preschool';
        const category_id = document.getElementById('v-cat-id').value;
        const is_shorts = document.getElementById('v-is-shorts').checked === true;
        const thumbFile = document.getElementById('v-thumb-file').files?.[0] ?? null;
        const videoFile = document.getElementById('v-video-file').files?.[0] ?? null;

        if (!title || !channel_name) {
            alert('Title and Channel Name are required.');
            return;
        }
        if (!category_id) {
            alert('Please select a category.');
            return;
        }
        if (!videoFile) {
            alert('Video file is required.');
            return;
        }
        if (!validateBunnyConfig()) {
            alert('Bunny config missing. Add BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE to admin/config.js');
            return;
        }

        btn.disabled = true;
        btn.textContent = 'Uploading...';
        let videoId = null;
        let uploadedPaths = [];

        try {
            const ts = Date.now();
            const vidName = safeFilename(videoFile.name);
            const thumbName = thumbFile ? safeFilename(thumbFile.name) : null;
            const durationText = formatHms(computedDurationSeconds ?? 0);

            // STEP 1: Upload video to Bunny FIRST (to get video_path - it's required)
            statusEl.textContent = 'Uploading video file to Bunny...';
            const video_path = await uploadToBunny(`videos/${ts}_${vidName}`, videoFile);
            uploadedPaths.push(video_path);

            // STEP 2: Upload thumbnail if provided
            let thumbnail_path = null;
            if (thumbFile) {
                statusEl.textContent = 'Uploading thumbnail to Bunny...';
                thumbnail_path = await uploadToBunny(`images/thumbnails/${ts}_${thumbName}`, thumbFile);
                uploadedPaths.push(thumbnail_path);
            }

            // STEP 3: Save to Supabase AFTER files are uploaded
            statusEl.textContent = 'Creating video record in database...';
            const payload = {
                title,
                channel_name,
                content_level,
                duration: durationText,
                thumbnail_path,
                video_path, // Now we have the actual path
                category_id,
                is_shorts,
            };

            // Attempt insert; handle missing columns gracefully
            let { data: insertedData, error } = await supabaseClient.from('videos').insert(payload).select();
            if (error && /channel_avatar_path/i.test(error.message)) {
                const { channel_avatar_path: _, ...fallback } = payload;
                ({ data: insertedData, error } = await supabaseClient.from('videos').insert(fallback).select());
            }
            if (error && /content_level/i.test(error.message)) {
                const { content_level: ___, ...fallback } = payload;
                ({ data: insertedData, error } = await supabaseClient.from('videos').insert(fallback).select());
            }
            if (error && /is_shorts/i.test(error.message)) {
                const { is_shorts: __, ...fallback } = payload;
                ({ data: insertedData, error } = await supabaseClient.from('videos').insert(fallback).select());
            }

            if (error) {
                // If DB insert fails, cleanup files from Bunny
                statusEl.textContent = 'Upload failed, cleaning up...';
                for (const path of uploadedPaths) {
                    await deleteBunnyFile(path).catch(e => {
                        console.error('Cleanup error (Bunny):', e);
                    });
                }
                throw error;
            }

            videoId = insertedData?.[0]?.id;
            if (!videoId) throw new Error('Failed to create video record');

            statusEl.textContent = 'Done.';
            loadDashboardData('videos');
            closeModal();
        } catch (e) {
            alert('Error: ' + (e?.message ?? String(e)));
        } finally {
            btn.disabled = false;
            btn.textContent = 'Save';
        }
    };
     modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function showAddCategoryModal() {
     const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Add Category";
    document.getElementById('modal-content').innerHTML = `
        <input id="c-name" placeholder="Name" class="w-full border p-2 mb-2 rounded">
        <input id="c-color" type="color" class="w-full border p-2 mb-2 rounded h-10">
        <div>
            <label class="block text-sm font-bold mb-1">Category Icon (optional)</label>
            <input id="c-icon-file" type="file" accept="image/*" class="w-full border p-2 mb-2 rounded bg-white">
            <p class="text-xs text-gray-500">Uploads to Bunny (images/category_icons/).</p>
        </div>
    `;
    
    document.getElementById('modal-action-btn').onclick = async () => {
        const name = document.getElementById('c-name').value;
        const colorHex = document.getElementById('c-color').value;
        const iconFile = document.getElementById('c-icon-file').files?.[0] ?? null;
        // Convert to int
        const color = parseInt(colorHex.replace('#', '0xFF'), 16);

        // Schema stores `color` as text (see `supabase_schema.sql`). Store as '0xFFRRGGBB'.
        const colorStr = '0xFF' + colorHex.substring(1).toUpperCase();

        let categoryId = null;
        let uploadedPaths = [];

        try {
            // STEP 1: Create category in DB FIRST (with null icon_path)
            const initialPayload = { name, color: colorStr, icon_path: null };

            let { data: insertedData, error: err2 } = await supabaseClient.from('categories').insert(initialPayload).select();
            if (err2 && /icon_path/i.test(err2.message)) {
                const { icon_path: _, ...fallback } = initialPayload;
                ({ data: insertedData, error: err2 } = await supabaseClient.from('categories').insert(fallback).select());
            }

            if (err2) throw err2;
            categoryId = insertedData?.[0]?.id;
            if (!categoryId) throw new Error('Failed to create category record');

            // STEP 2: Upload icon to Bunny (only after DB record created)
            let icon_path = null;
            try {
                if (iconFile) {
                    if (!validateBunnyConfig()) {
                        throw new Error('Bunny config missing. Add BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE to admin/config.js');
                    }
                    const ts = Date.now();
                    const iconName = safeFilename(iconFile.name);
                    icon_path = await uploadToBunny(`images/category_icons/${ts}_${iconName}`, iconFile);
                    uploadedPaths.push(icon_path);

                    // STEP 3: Update DB with actual icon path
                    const { error: updateError } = await supabaseClient.from('categories').update({ icon_path }).eq('id', categoryId);
                    if (updateError) throw updateError;
                }

                loadDashboardData('categories');
                closeModal();
            } catch (uploadError) {
                // If upload fails, delete orphaned DB entry
                console.error('Upload error:', uploadError);
                
                if (categoryId) {
                    await supabaseClient.from('categories').delete().eq('id', categoryId).catch(e => {
                        console.error('Cleanup error (DB):', e);
                    });
                }

                for (const path of uploadedPaths) {
                    await deleteBunnyFile(path).catch(e => {
                        console.error('Cleanup error (Bunny):', e);
                    });
                }

                throw uploadError;
            }
        } catch (e) {
            alert('Error: ' + (e?.message ?? String(e)));
        }
    };
     modal.classList.remove('hidden');
    modal.classList.add('flex');
}


// Channel Modal Functions
function showAddChannelModal() {
     const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Add Channel";
    document.getElementById('modal-content').innerHTML = `
        <div class="space-y-3">
            <input id="ch-name" placeholder="Channel Name" class="w-full border p-2 rounded" required>
            <textarea id="ch-description" placeholder="Description" class="w-full border p-2 rounded" rows="3"></textarea>
            <div>
                <label class="block text-sm font-bold mb-1">Channel Avatar (optional)</label>
                <input id="ch-avatar-file" type="file" accept="image/*" class="w-full border p-2 rounded bg-white">
                <p class="text-xs text-gray-500 mt-1">Uploads to Bunny (images/avatars/).</p>
            </div>
        </div>
    `;
    
    document.getElementById('modal-action-btn').onclick = async () => {
        const name = document.getElementById('ch-name').value.trim();
        const description = document.getElementById('ch-description').value.trim();
        const avatarFile = document.getElementById('ch-avatar-file').files?.[0] ?? null;

        if (!name) {
            alert('Channel name is required.');
            return;
        }

        let channelId = null;
        let uploadedPaths = [];

        try {
            // STEP 1: Create channel in DB FIRST (with null avatar_path)
            const initialPayload = { name, description: description || null, avatar_path: null };

            const { data: insertedData, error } = await supabaseClient.from('channels').insert(initialPayload).select();

            if (error) throw error;
            channelId = insertedData?.[0]?.id;
            if (!channelId) throw new Error('Failed to create channel record');

            // STEP 2: Upload avatar to Bunny (only after DB record created)
            let avatar_path = null;
            try {
                if (avatarFile) {
                    if (!validateBunnyConfig()) {
                        throw new Error('Bunny config missing. Add BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE to admin/config.js');
                    }
                    const ts = Date.now();
                    const avatarName = safeFilename(avatarFile.name);
                    avatar_path = await uploadToBunny(`images/avatars/${ts}_${avatarName}`, avatarFile);
                    uploadedPaths.push(avatar_path);

                    // STEP 3: Update DB with actual avatar path
                    const { error: updateError } = await supabaseClient.from('channels').update({ avatar_path }).eq('id', channelId);
                    if (updateError) throw updateError;
                }

                loadDashboardData('channels');
                closeModal();
            } catch (uploadError) {
                // If upload fails, delete orphaned DB entry
                console.error('Upload error:', uploadError);
                
                if (channelId) {
                    await supabaseClient.from('channels').delete().eq('id', channelId).catch(e => {
                        console.error('Cleanup error (DB):', e);
                    });
                }

                for (const path of uploadedPaths) {
                    await deleteBunnyFile(path).catch(e => {
                        console.error('Cleanup error (Bunny):', e);
                    });
                }

                throw uploadError;
            }
        } catch (e) {
            alert('Error: ' + (e?.message ?? String(e)));
        }
    };
     modal.classList.remove('hidden');
    modal.classList.add('flex');
}

function showEditChannelModal(id) {
     const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Edit Channel";
    
    // Fetch channel data
    (async () => {
        const { data, error } = await supabaseClient.from('channels').select('*').eq('id', id).single();
        if (error) {
            alert('Error loading channel: ' + error.message);
            return;
        }

        const channel = data;
        document.getElementById('modal-content').innerHTML = `
            <div class="space-y-3">
                <input id="ch-name" placeholder="Channel Name" value="${channel.name}" class="w-full border p-2 rounded" required>
                <textarea id="ch-description" placeholder="Description" class="w-full border p-2 rounded" rows="3">${channel.description || ''}</textarea>
                <div>
                    <label class="block text-sm font-bold mb-1">Channel Avatar (optional)</label>
                    <input id="ch-avatar-file" type="file" accept="image/*" class="w-full border p-2 rounded bg-white">
                    <p class="text-xs text-gray-500 mt-1">Upload new avatar or leave empty to keep current.</p>
                </div>
            </div>
        `;

        document.getElementById('modal-action-btn').textContent = 'Update';
        document.getElementById('modal-action-btn').onclick = async () => {
            const name = document.getElementById('ch-name').value.trim();
            const description = document.getElementById('ch-description').value.trim();
            const avatarFile = document.getElementById('ch-avatar-file').files?.[0] ?? null;

            if (!name) {
                alert('Channel name is required.');
                return;
            }

            let uploadedPaths = [];

            try {
                // Prepare update payload
                const updatePayload = { name, description: description || null };
                let avatar_path = channel.avatar_path;

                // STEP 1: Upload new avatar to Bunny (if provided)
                if (avatarFile) {
                    if (!validateBunnyConfig()) {
                        throw new Error('Bunny config missing. Add BUNNY_STORAGE_ZONE, BUNNY_ACCESS_KEY, BUNNY_CDN_BASE to admin/config.js');
                    }
                    const ts = Date.now();
                    const avatarName = safeFilename(avatarFile.name);
                    avatar_path = await uploadToBunny(`images/avatars/${ts}_${avatarName}`, avatarFile);
                    uploadedPaths.push(avatar_path);
                }

                // STEP 2: Update database with new avatar path
                updatePayload.avatar_path = avatar_path;
                const { error } = await supabaseClient.from('channels').update(updatePayload).eq('id', id);

                if (error) {
                    // If update fails, delete newly uploaded files
                    for (const path of uploadedPaths) {
                        await deleteBunnyFile(path).catch(e => {
                            console.error('Cleanup error (Bunny):', e);
                        });
                    }
                    throw error;
                }

                loadDashboardData('channels');
                closeModal();
            } catch (e) {
                alert('Error: ' + (e?.message ?? String(e)));
            }
        };
    })();

    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

// Video Edit Modal Function
function showEditVideoModal(id) {
     const modal = document.getElementById('modal');
    document.getElementById('modal-title').textContent = "Edit Video";
    
    // Fetch video data
    (async () => {
        const { data, error } = await supabaseClient.from('videos').select('*').eq('id', id).single();
        if (error) {
            alert('Error loading video: ' + error.message);
            return;
        }

        const video = data;
        document.getElementById('modal-content').innerHTML = `
            <div class="space-y-3">
                <input id="v-title" placeholder="Title" value="${video.title}" class="w-full border p-2 rounded" required>
                <input id="v-channel" placeholder="Channel Name" value="${video.channel_name}" class="w-full border p-2 rounded" required>
                
                <div>
                    <label class="block text-sm font-bold mb-1">Thumbnail (optional - upload new to replace)</label>
                    <input id="v-thumb-file" type="file" accept="image/*" class="w-full border p-2 rounded bg-white">
                </div>
                
                <div>
                    <label class="block text-sm font-bold mb-1">Channel Avatar (optional - upload new to replace)</label>
                    <input id="v-channel-avatar-file" type="file" accept="image/*" class="w-full border p-2 rounded bg-white">
                </div>
                
                <div>
                    <label class="block text-sm font-bold mb-1">Content Level</label>
                    <select id="v-content-level" class="w-full border p-2 rounded">
                        <option value="Preschool" ${video.content_level === 'Preschool' ? 'selected' : ''}>Preschool</option>
                        <option value="Younger" ${(video.content_level === 'Younger' || video.content_level === 'Older') ? 'selected' : ''}>Younger</option>
                    </select>
                </div>
                
                <div class="flex items-center gap-2">
                    <input id="v-is-shorts" type="checkbox" ${video.is_shorts ? 'checked' : ''}>
                    <label>Is Shorts?</label>
                </div>
            </div>
        `;

        document.getElementById('modal-action-btn').textContent = 'Update';
        document.getElementById('modal-action-btn').onclick = async () => {
            const title = document.getElementById('v-title').value.trim();
            const channel_name = document.getElementById('v-channel').value.trim();
            const content_level = document.getElementById('v-content-level').value;
            const is_shorts = document.getElementById('v-is-shorts').checked;
            const thumbFile = document.getElementById('v-thumb-file').files?.[0] ?? null;
            const channelAvatarFile = document.getElementById('v-channel-avatar-file').files?.[0] ?? null;

            if (!title || !channel_name) {
                alert('Title and Channel Name are required.');
                return;
            }

            let uploadedPaths = [];

            try {
                // Prepare update payload with existing values
                const updatePayload = { title, channel_name, content_level, is_shorts };
                let thumbnail_path = video.thumbnail_path;
                let channel_avatar_path = video.channel_avatar_path;

                // STEP 1: Upload new files to Bunny (if provided)
                if (thumbFile) {
                    if (!validateBunnyConfig()) {
                        throw new Error('Bunny config missing.');
                    }
                    const ts = Date.now();
                    const thumbName = safeFilename(thumbFile.name);
                    thumbnail_path = await uploadToBunny(`images/thumbnails/${ts}_${thumbName}`, thumbFile);
                    uploadedPaths.push(thumbnail_path);
                }

                if (channelAvatarFile) {
                    if (!validateBunnyConfig()) {
                        throw new Error('Bunny config missing.');
                    }
                    const ts = Date.now();
                    const avatarName = safeFilename(channelAvatarFile.name);
                    channel_avatar_path = await uploadToBunny(`images/avatars/${ts}_${avatarName}`, channelAvatarFile);
                    uploadedPaths.push(channel_avatar_path);
                }

                // STEP 2: Update database with new paths
                updatePayload.thumbnail_path = thumbnail_path;
                updatePayload.channel_avatar_path = channel_avatar_path;
                
                const { error } = await supabaseClient.from('videos').update(updatePayload).eq('id', id);

                if (error) {
                    // If update fails, delete newly uploaded files
                    for (const path of uploadedPaths) {
                        await deleteBunnyFile(path).catch(e => {
                            console.error('Cleanup error (Bunny):', e);
                        });
                    }
                    throw error;
                }

                loadDashboardData('videos');
                closeModal();
            } catch (e) {
                alert('Error: ' + (e?.message ?? String(e)));
            }
        };
    })();

    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

// Utils
function getBunnyUrl(path) {
    if(!path) return '';
    if(path.startsWith('http')) return path;
    if(path.startsWith('/')) path = path.substring(1);
    // Prefer configured CDN base if available
    const base = (typeof BUNNY_CDN_BASE === 'string' && BUNNY_CDN_BASE.startsWith('http'))
        ? BUNNY_CDN_BASE.replace(/\/+$/, '') + '/'
        : 'https://kidskonnect.b-cdn.net/';
    return base + path;
}
// ============================================
// MART PRODUCT MANAGEMENT
// ============================================

function renderMart(martVideos) {
    const grid = document.getElementById('mart-grid');
    grid.innerHTML = '';
    
    // Filter out demo items and show only real uploaded items
    const realItems = martVideos.filter(product => product && product.id);
    
    if (realItems.length === 0) {
        grid.innerHTML = '<div class="col-span-full text-center py-8 text-gray-500">No products uploaded yet. Click "Add Product" to create one.</div>';
        return;
    }
    
    realItems.forEach(product => {
        const div = document.createElement('div');
        div.className = 'border rounded p-4 flex flex-col gap-3 bg-pink-50';
        const isActive = product.is_active ? '✓ Active' : '✗ Inactive';
        const statsHtml = `<div class="text-sm text-gray-600">Views: ${product.views || 0} | Clicks: ${product.clicks || 0}</div>`;
        const thumbnailHtml = product.thumbnail_url 
            ? `<img src="${getBunnyUrl(product.thumbnail_url)}" class="w-full h-full object-cover rounded" onerror="this.style.display='none'">`
            : `<div class="flex items-center justify-center h-24 bg-gray-300 rounded"><span class="text-gray-600">No Thumbnail</span></div>`;
        
        div.innerHTML = `
            <div>
                <h4 class="font-bold text-sm">${product.shop_name}</h4>
                <p class="text-xs text-gray-600 truncate">${product.product_link}</p>
            </div>
            <div class="h-24 bg-gray-200 rounded overflow-hidden">
                ${thumbnailHtml}
            </div>
            ${statsHtml}
            <div class="text-xs text-gray-500">${isActive}</div>
            <div class="flex gap-2">
                <button onclick="editMartModal(${product.id})" class="flex-1 bg-blue-500 text-white px-2 py-1 rounded text-xs hover:bg-blue-600">Edit</button>
                <button onclick="deleteMart(${product.id})" class="flex-1 bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600">Delete</button>
            </div>
        `;
        grid.appendChild(div);
    });
}

function showAddMartModal() {
    const modal = document.getElementById('modal');
    document.getElementById('modal-title').innerText = 'Add Mart Product';
    
    const content = `
        <div class="space-y-4">
            <div>
                <label class="block text-sm font-bold mb-1">Product Title</label>
                <input type="text" id="mart-title" class="w-full px-3 py-2 border rounded" placeholder="e.g., Educational Toy Set">
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Shop/Brand Name</label>
                <input type="text" id="mart-shop-name" class="w-full px-3 py-2 border rounded">
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Product Link (Affiliate URL)</label>
                <input type="url" id="mart-product-link" class="w-full px-3 py-2 border rounded" placeholder="https://...">
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Video File (9:16 aspect ratio)</label>
                <input type="file" id="mart-video-file" accept="video/*" class="w-full px-3 py-2 border rounded">
                <p class="text-xs text-gray-500 mt-1">Recommended: 9:16 vertical video (up to 100MB)</p>
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Thumbnail Image (required)</label>
                <input type="file" id="mart-thumbnail-file" accept="image/*" class="w-full px-3 py-2 border rounded">
                <p class="text-xs text-gray-500 mt-1">Preview image for the product.</p>
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Display Order</label>
                <input type="number" id="mart-order" class="w-full px-3 py-2 border rounded" value="0">
            </div>
            <div>
                <label class="block text-sm font-bold mb-1">Active</label>
                <input type="checkbox" id="mart-active" checked>
            </div>
            <p id="mart-upload-status" class="text-sm text-gray-600 hidden mt-3"></p>
        </div>
    `;
    
    document.getElementById('modal-content').innerHTML = content;
    
    document.getElementById('modal-action-btn').onclick = (async () => {
        const btn = document.getElementById('modal-action-btn');
        const statusEl = document.getElementById('mart-upload-status');
        
        const title = document.getElementById('mart-title').value.trim();
        const shopName = document.getElementById('mart-shop-name').value.trim();
        const productLink = document.getElementById('mart-product-link').value.trim();
        const videoFile = document.getElementById('mart-video-file').files[0];
        const thumbnailFile = document.getElementById('mart-thumbnail-file').files[0];
        const displayOrder = parseInt(document.getElementById('mart-order').value) || 0;
        const isActive = document.getElementById('mart-active').checked;

        if (!title || !shopName || !productLink || !videoFile || !thumbnailFile) {
            alert('Product Title, Shop Name, Product Link, Video, and Thumbnail are required.');
            return;
        }

        btn.disabled = true;
        btn.textContent = 'Uploading...';
        statusEl.classList.remove('hidden');

        try {
            if (!validateBunnyConfig()) {
                alert('Bunny config missing.');
                return;
            }

            const ts = Date.now();
            
            // Upload video to videos/mart folder
            statusEl.textContent = 'Uploading video (0%)...';
            const videoName = safeFilename(videoFile.name);
            const videoPath = await uploadToBunnyWithProgress(`videos/mart/${ts}_${videoName}`, videoFile, (progress) => {
                statusEl.textContent = `Uploading video (${Math.round(progress)}%)...`;
            });
            
            // Upload thumbnail
            statusEl.textContent = 'Uploading thumbnail (0%)...';
            const thumbName = safeFilename(thumbnailFile.name);
            const thumbnailPath = await uploadToBunnyWithProgress(`images/thumbnails/${ts}_${thumbName}`, thumbnailFile, (progress) => {
                statusEl.textContent = `Uploading thumbnail (${Math.round(progress)}%)...`;
            });

            statusEl.textContent = 'Saving to database...';
            const payload = {
                title: title,
                shop_name: shopName,
                product_link: productLink,
                video_url: videoPath,
                thumbnail_url: thumbnailPath,
                display_order: displayOrder,
                is_active: isActive
            };

            const { error } = await supabaseClient.from('mart_videos').insert([payload]);

            if (error) {
                alert('Error: ' + error.message);
            } else {
                statusEl.textContent = 'Product added successfully!';
                setTimeout(() => {
                    loadDashboardData('mart');
                    closeModal();
                }, 1500);
            }
        } catch (e) {
            alert(e?.message ?? String(e));
        } finally {
            btn.disabled = false;
            btn.textContent = 'Save';
        }
    });

    modal.classList.remove('hidden');
    modal.classList.add('flex');
}

async function deleteMart(id) {
    if (!confirm('Delete this product?')) return;

    try {
        // Fetch product to get file paths
        const { data: product, error: fetchError } = await supabaseClient
            .from('mart_videos')
            .select('*')
            .eq('id', id)
            .single();

        if (!fetchError && product) {
            // Delete files from Bunny storage
            try {
                if (product.video_url) await deleteBunnyFile(product.video_url);
                if (product.thumbnail_url) await deleteBunnyFile(product.thumbnail_url);
            } catch (e) {
                console.warn('File deletion warning:', e.message);
            }
        }

        // Delete from database
        const { error } = await supabaseClient.from('mart_videos').delete().eq('id', id);

        if (error) {
            alert('Error: ' + error.message);
        } else {
            alert('Product deleted successfully!');
            loadDashboardData('mart');
        }
    } catch (e) {
        alert(e?.message ?? String(e));
    }
}

function editMartModal(id) {
    (async () => {
        try {
            const { data: product, error } = await supabaseClient
                .from('mart_videos')
                .select('*')
                .eq('id', id)
                .single();

            if (error) {
                alert('Error loading product: ' + error.message);
                return;
            }
            if (!product) {
                alert('Product not found');
                return;
            }

            const modal = document.getElementById('modal');
            document.getElementById('modal-title').innerText = 'Edit Mart Product';

            const content = `
                <div class="space-y-4">
                    <div>
                        <label class="block text-sm font-bold mb-1">Product Title</label>
                        <input type="text" id="mart-title" class="w-full px-3 py-2 border rounded" value="${String(product.title ?? '').replace(/"/g, '&quot;')}" placeholder="e.g., Educational Toy Set">
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Shop/Brand Name</label>
                        <input type="text" id="mart-shop-name" class="w-full px-3 py-2 border rounded" value="${String(product.shop_name ?? '').replace(/"/g, '&quot;')}">
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Product Link (Affiliate URL)</label>
                        <input type="url" id="mart-product-link" class="w-full px-3 py-2 border rounded" value="${String(product.product_link ?? '').replace(/"/g, '&quot;')}" placeholder="https://...">
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Replace Video (optional)</label>
                        <input type="file" id="mart-video-file" accept="video/*" class="w-full px-3 py-2 border rounded">
                        <p class="text-xs text-gray-500 mt-1">Current: ${product.video_url ? product.video_url : 'None'}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Replace Thumbnail (optional)</label>
                        <input type="file" id="mart-thumbnail-file" accept="image/*" class="w-full px-3 py-2 border rounded">
                        <p class="text-xs text-gray-500 mt-1">Current: ${product.thumbnail_url ? product.thumbnail_url : 'None'}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Display Order</label>
                        <input type="number" id="mart-order" class="w-full px-3 py-2 border rounded" value="${Number.isFinite(product.display_order) ? product.display_order : 0}">
                    </div>
                    <div>
                        <label class="block text-sm font-bold mb-1">Active</label>
                        <input type="checkbox" id="mart-active" ${product.is_active ? 'checked' : ''}>
                    </div>
                    <p id="mart-upload-status" class="text-sm text-gray-600 hidden mt-3"></p>
                </div>
            `;

            document.getElementById('modal-content').innerHTML = content;

            const actionBtn = document.getElementById('modal-action-btn');
            actionBtn.textContent = 'Update';

            actionBtn.onclick = (async () => {
                const btn = actionBtn;
                const statusEl = document.getElementById('mart-upload-status');

                const title = document.getElementById('mart-title').value.trim();
                const shopName = document.getElementById('mart-shop-name').value.trim();
                const productLink = document.getElementById('mart-product-link').value.trim();
                const videoFile = document.getElementById('mart-video-file').files[0];
                const thumbnailFile = document.getElementById('mart-thumbnail-file').files[0];
                const displayOrder = parseInt(document.getElementById('mart-order').value) || 0;
                const isActive = document.getElementById('mart-active').checked;

                if (!title || !shopName || !productLink) {
                    alert('Product Title, Shop Name, and Product Link are required.');
                    return;
                }

                btn.disabled = true;
                btn.textContent = 'Updating...';
                statusEl.classList.remove('hidden');

                try {
                    if (!validateBunnyConfig()) {
                        alert('Bunny config missing.');
                        return;
                    }

                    const ts = Date.now();

                    let nextVideoUrl = product.video_url;
                    let nextThumbUrl = product.thumbnail_url;

                    if (videoFile) {
                        statusEl.textContent = 'Uploading new video (0%)...';
                        const videoName = safeFilename(videoFile.name);
                        const uploaded = await uploadToBunnyWithProgress(
                            `videos/mart/${ts}_${videoName}`,
                            videoFile,
                            (progress) => {
                                statusEl.textContent = `Uploading new video (${Math.round(progress)}%)...`;
                            }
                        );
                        nextVideoUrl = uploaded;

                        // Delete old video
                        if (product.video_url) {
                            await deleteBunnyFile(product.video_url);
                        }
                    }

                    if (thumbnailFile) {
                        statusEl.textContent = 'Uploading new thumbnail (0%)...';
                        const thumbName = safeFilename(thumbnailFile.name);
                        const uploaded = await uploadToBunnyWithProgress(
                            `images/thumbnails/${ts}_${thumbName}`,
                            thumbnailFile,
                            (progress) => {
                                statusEl.textContent = `Uploading new thumbnail (${Math.round(progress)}%)...`;
                            }
                        );
                        nextThumbUrl = uploaded;

                        // Delete old thumbnail
                        if (product.thumbnail_url) {
                            await deleteBunnyFile(product.thumbnail_url);
                        }
                    }

                    statusEl.textContent = 'Saving to database...';

                    const payload = {
                        title,
                        shop_name: shopName,
                        product_link: productLink,
                        video_url: nextVideoUrl,
                        thumbnail_url: nextThumbUrl,
                        display_order: displayOrder,
                        is_active: isActive,
                    };

                    const { error: updateError } = await supabaseClient
                        .from('mart_videos')
                        .update(payload)
                        .eq('id', id);

                    if (updateError) {
                        alert('Error: ' + updateError.message);
                        return;
                    }

                    statusEl.textContent = 'Updated successfully!';
                    setTimeout(() => {
                        loadDashboardData('mart');
                        closeModal();
                    }, 800);
                } catch (e) {
                    alert(e?.message ?? String(e));
                } finally {
                    btn.disabled = false;
                    btn.textContent = 'Update';
                }
            });

            modal.classList.remove('hidden');
            modal.classList.add('flex');
        } catch (e) {
            alert(e?.message ?? String(e));
        }
    })();
}