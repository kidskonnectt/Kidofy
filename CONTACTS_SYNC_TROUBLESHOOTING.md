# Contacts Sync - Troubleshooting Checklist

## ✅ What I Fixed

1. **Added `synced_at` timestamp** to the sync service
   - File: `lib/services/contacts_sync_service.dart`
   - The timestamp wasn't being included in the insert, which could cause issues

2. **Enhanced error logging** 
   - Now you'll see detailed error messages in the Flutter console
   - Look for error messages that indicate what's wrong

## 🔍 Debugging: Check These When Testing

### Step 1: Deploy Contacts Table
**FIRST AND MOST IMPORTANT**: Follow the guide in `CONTACTS_TABLE_DEPLOYMENT.md` to create the contacts table in Supabase.

### Step 2: Check Flutter Console Logs
When you click "Sync Contacts" button:

**Look for these messages:**
```
📱 Requesting contacts permission...
✅ Contacts permission granted
🔄 Starting contacts sync...
📋 Found X contacts on device
✅ Successfully synced X contacts
```

**If you see errors, look for:**
```
❌ Error syncing contacts: ...
⚠️ RLS Policy Error
⚠️ Table not found
```

### Step 3: Verify User is Logged In
- Check that you're logged in as a user before syncing
- RLS policies require `auth.uid()` to match `user_id`

### Step 4: Check Contact Permissions
- Make sure contacts permission is **actually granted** on the device
- In Android: Settings → Apps → KidsApp → Permissions → Contacts (should be ON)
- In iOS: Settings → KidsApp → Contacts (should be ON)

## 📋 Admin Panel Verification

To verify contacts were saved:

1. Go to admin panel (`/admin/index.html`)
2. Check if there's a Contacts section
3. Should show all synced contacts from all users

## 🚀 Quick Testing Steps

1. **Deploy the SQL** (see `CONTACTS_TABLE_DEPLOYMENT.md`)
2. **Rebuild Flutter app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. **Click "Sync Contacts"** button in the app
4. **Check Flutter console** for success/error messages
5. **Verify in Supabase** → Database → contacts table → see new rows

## 📊 Supabase Verification

To manually check if contacts are in the database:

1. Go to Supabase Dashboard
2. Click **Table Editor** (left sidebar)
3. Select **contacts** table
4. You should see rows with:
   - `user_id`: (UUID of logged-in user)
   - `contact_name`: (Name of contact)
   - `phone_number`: (Phone from contacts)
   - `email`: (Email from contacts)
   - `synced_at`: (Timestamp when synced)

## 🆘 Still Not Working?

Check the Flutter console for the **exact error message**. Common issues:

| Error | Cause | Fix |
|-------|-------|-----|
| "Table not found" | contacts table not created | Run SQL from deployment guide |
| "RLS Policy Error" | User not authenticated | Make sure you're logged in |
| "permission denied" | RLS policy not allowing insert | Check table policies in Supabase |
| No error, no save | Network issue | Check internet, try again |

---

**Updated**: 2024 - Sync service enhanced with better error reporting
