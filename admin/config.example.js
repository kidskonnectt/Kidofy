// Copy this file to `config.js` and fill in your project values.
// IMPORTANT:
// - Use your Supabase Project URL.
// - Use the "anon" (public) key for browser apps.
// - NEVER put the service-role key in a browser file.

const SUPABASE_URL = 'https://YOUR_PROJECT_REF.supabase.co';
const SUPABASE_KEY = 'YOUR_ANON_KEY';

// Bunny.net Storage (for direct uploads from this admin panel)
// SECURITY NOTE: This access key will be present in the browser for admins.
// For higher security, move uploads behind a server/edge function.
const BUNNY_STORAGE_ZONE = 'YOUR_STORAGE_ZONE_NAME';
const BUNNY_ACCESS_KEY = 'YOUR_BUNNY_STORAGE_ACCESS_KEY';
// CDN Base: Use your Cloudflare CDN domain (it pulls from Bunny storage as origin)
const BUNNY_CDN_BASE = 'https://YOUR_CLOUDFLARE_CDN_DOMAIN';
