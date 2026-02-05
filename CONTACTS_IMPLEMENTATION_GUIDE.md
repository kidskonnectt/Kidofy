# Contacts Management System - Implementation Guide

## Overview

This guide covers the complete implementation of the Contacts Management System for KidsApp, including:
- User contact syncing from device
- Admin panel contact management
- Search and filtering capabilities
- SQL queries for all operations

---

## Table of Contents

1. [Database Setup](#database-setup)
2. [Flutter App Implementation](#flutter-app-implementation)
3. [Admin Panel Setup](#admin-panel-setup)
4. [Features & Functionality](#features--functionality)
5. [Testing](#testing)
6. [Deployment Checklist](#deployment-checklist)

---

## Database Setup

### Step 1: Create Contacts Table

Execute the following SQL in Supabase dashboard:

```sql
-- Create Contacts Table
CREATE TABLE public.contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contact_name TEXT NOT NULL,
  phone_number TEXT,
  email TEXT,
  raw_contact_id TEXT,
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, raw_contact_id)
);
```

### Step 2: Create Indexes

```sql
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_contacts_phone_number ON public.contacts(phone_number);
CREATE INDEX idx_contacts_email ON public.contacts(email);
CREATE INDEX idx_contacts_synced_at ON public.contacts(synced_at DESC);
CREATE INDEX idx_contacts_contact_name ON public.contacts(contact_name);
```

### Step 3: Enable RLS

```sql
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
```

### Step 4: Create RLS Policies

```sql
-- Users can view own contacts
CREATE POLICY "Users can view own contacts"
  ON public.contacts FOR SELECT
  USING ( auth.uid() = user_id );

-- Users can insert own contacts
CREATE POLICY "Users can insert own contacts"
  ON public.contacts FOR INSERT
  WITH CHECK ( auth.uid() = user_id );

-- Users can update own contacts
CREATE POLICY "Users can update own contacts"
  ON public.contacts FOR UPDATE
  USING ( auth.uid() = user_id );

-- Users can delete own contacts
CREATE POLICY "Users can delete own contacts"
  ON public.contacts FOR DELETE
  USING ( auth.uid() = user_id );
```

### Step 5: Create Trigger for Updated Timestamp

```sql
CREATE OR REPLACE FUNCTION update_contacts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_contacts_updated_at
  BEFORE UPDATE ON public.contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_contacts_updated_at();
```

---

## Flutter App Implementation

### Step 1: Add Dependencies

The `flutter_contacts` dependency is already in `pubspec.yaml`. No additional setup needed.

### Step 2: Create Contact Service

A new service file has been created: `lib/services/contacts_sync_service.dart`

This provides:
- `syncContactsWithPermission()` - Request permission and sync
- `getContactsForUser()` - Fetch all contacts
- `searchContactsByName()` - Search by name
- `searchContactsByPhone()` - Search by phone
- `searchContactsByEmail()` - Search by email
- `deleteContact()` - Delete single contact
- `getContactsStatistics()` - Get stats

### Step 3: Create Contacts UI Screen

A new screen file has been created: `lib/screens/contacts_screen.dart`

Features:
- Display all synced contacts
- Search functionality
- Filter options (All, Has Phone, Has Email)
- Statistics display
- Delete contact option
- Sync from phone button

### Step 4: Integrate into App

Add to your providers in main.dart or app initialization:

```dart
// In main.dart or your app initialization
ChangeNotifierProvider(
  create: (_) => ContactsSyncProvider(),
  child: YourApp(),
),
```

Then navigate to the contacts screen:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ContactsScreen(userId: currentUserId),
  ),
);
```

### Step 5: Handle Permission in Settings Screen

Add a button in your settings/parent gate screen to sync contacts:

```dart
ElevatedButton.icon(
  onPressed: () async {
    final success = await ContactsSyncService.syncContactsWithPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Contacts synced successfully' 
            : 'Failed to sync contacts'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  },
  icon: const Icon(Icons.sync_contacts),
  label: const Text('Sync Contacts'),
),
```

---

## Admin Panel Setup

### Step 1: Update Navigation

The "Contacts" menu item has been added to `admin/index.html` sidebar.

### Step 2: Admin Panel Features

The contacts management section includes:

- **Search**: Search by contact name, phone, or email
- **Filters**:
  - All Contacts
  - Has Phone Number
  - Has Email
  - Specific User
- **Statistics**:
  - Total contacts synced
  - Contacts with phone
  - Contacts with email
  - Unique users synced
- **Actions**: Delete contacts

### Step 3: Admin Panel Table Display

Shows:
- Contact Name
- Phone Number (clickable tel: link)
- Email (clickable mailto: link)
- User Email (who synced this contact)
- Synced At timestamp
- Actions (delete button)

---

## Features & Functionality

### 1. Contact Syncing

**User Flow:**
1. User grants contacts permission
2. App fetches all contacts from device
3. Contacts are synced to Supabase with user_id
4. Duplicate prevention using raw_contact_id

**Code Location:** `lib/services/contacts_sync_service.dart`

```dart
// Sync contacts
final success = await ContactsSyncService.syncContactsWithPermission();
```

### 2. Search Functionality

**Search by Name:**
```dart
final results = await ContactsSyncService.searchContactsByName(userId, "John");
```

**Search by Phone:**
```dart
final results = await ContactsSyncService.searchContactsByPhone(userId, "+1234");
```

**Search by Email:**
```dart
final results = await ContactsSyncService.searchContactsByEmail(userId, "john@");
```

### 3. Filtering

Admin panel filters:
- **All Contacts**: Show all
- **Has Phone**: Only contacts with phone numbers
- **Has Email**: Only contacts with email addresses
- **Specific User**: Contacts from a particular user

### 4. Statistics

Automatically calculated and displayed:
- Total contacts per user
- Contacts with phone numbers
- Contacts with email addresses
- Total unique users who synced contacts
- Last sync timestamp

### 5. Contact Management

**Delete Single Contact:**
```dart
await ContactsSyncService.deleteContact(contactId);
```

**Delete All User Contacts:**
```dart
await ContactsSyncService.deleteAllContactsForUser(userId);
```

---

## Testing

### 1. Test Database Setup

Run these queries in Supabase SQL editor to verify:

```sql
-- Check table exists
SELECT * FROM information_schema.tables 
WHERE table_name = 'contacts';

-- Check indexes
SELECT indexname FROM pg_indexes 
WHERE tablename = 'contacts';

-- Check RLS enabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'contacts';

-- Check policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'contacts';
```

### 2. Test App Flow

1. **Permission Test:**
   - Run app on device/emulator
   - Tap "Sync Contacts" button
   - Grant/deny permission
   - Check app behavior

2. **Sync Test:**
   - Grant permission
   - Verify contacts appear in app
   - Check Supabase table for records

3. **Search Test:**
   - Type in search box
   - Verify results filter correctly
   - Test search by name, phone, email

4. **Filter Test:**
   - Apply each filter type
   - Verify correct contacts shown
   - Test combined search + filter

### 3. Test Admin Panel

1. Login to admin panel
2. Navigate to "Contacts" section
3. Verify contacts table loads
4. Test search functionality
5. Test filter dropdowns
6. Test delete button

### 4. Test SQL Queries

Run these in Supabase SQL editor:

```sql
-- Count total contacts
SELECT COUNT(*) FROM public.contacts;

-- View recent contacts
SELECT * FROM public.contacts 
ORDER BY synced_at DESC 
LIMIT 10;

-- Test user filter
SELECT * FROM public.contacts 
WHERE user_id = '${testUserId}';

-- Test search
SELECT * FROM public.contacts 
WHERE contact_name ILIKE '%John%';
```

---

## Common Issues & Solutions

### Issue 1: Contacts Not Syncing

**Possible Causes:**
- Permission denied
- User not authenticated
- Network error

**Solution:**
1. Check permission logs in app
2. Verify user is logged in
3. Check network connectivity
4. Try sync again

### Issue 2: Duplicate Contacts

**Solution:**
```sql
-- Remove duplicates using this query
DELETE FROM public.contacts
WHERE id IN (
  SELECT id FROM (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, LOWER(contact_name) 
        ORDER BY created_at DESC
      ) as rn
    FROM public.contacts
  ) t
  WHERE rn > 1
);
```

### Issue 3: Admin Can't See All Contacts

**Solution:** Add admin policy if needed:

```sql
CREATE POLICY "Admins can view all contacts"
  ON public.contacts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );
```

---

## Performance Optimization

### 1. Indexed Queries

All frequently searched columns have indexes:
- `user_id` - For user filtering
- `phone_number` - For phone searches
- `email` - For email searches
- `synced_at` - For time-based filtering
- `contact_name` - For name searches

### 2. Pagination (Optional)

For large contact lists, implement pagination:

```dart
final contacts = await supabaseClient
  .from('contacts')
  .select()
  .eq('user_id', userId)
  .range(0, 49) // First 50
  .order('contact_name');
```

### 3. Caching

Implement local caching to reduce database queries:

```dart
List<ContactsModel> _cachedContacts = [];
DateTime _lastFetch = DateTime(2000);

Future<List<ContactsModel>> getContactsWithCache(String userId) async {
  if (DateTime.now().difference(_lastFetch).inMinutes < 5) {
    return _cachedContacts;
  }
  _cachedContacts = await ContactsSyncService.getContactsForUser(userId);
  _lastFetch = DateTime.now();
  return _cachedContacts;
}
```

---

## Deployment Checklist

- [ ] Execute all SQL schema creation queries
- [ ] Verify RLS policies are active
- [ ] Test contacts sync on test device
- [ ] Verify admin panel loads contacts section
- [ ] Test search and filters
- [ ] Test delete functionality
- [ ] Run performance tests with large datasets
- [ ] Verify permission handling on different Android versions
- [ ] Test on iOS (if applicable)
- [ ] Update app version number
- [ ] Deploy to app store/play store
- [ ] Announce feature to users

---

## File Reference

### New Files Created:

1. **Database Schema:**
   - `contacts_schema.sql` - Table creation and RLS policies

2. **Flutter Services:**
   - `lib/services/contacts_sync_service.dart` - Contact sync logic

3. **Flutter UI:**
   - `lib/screens/contacts_screen.dart` - Contacts UI screen

4. **Admin Panel:**
   - HTML section added to `admin/index.html`
   - JavaScript functions added to `admin/script.js`

5. **Documentation:**
   - `CONTACTS_SQL_QUERIES.md` - Comprehensive SQL query reference
   - `CONTACTS_IMPLEMENTATION_GUIDE.md` - This file

---

## Support & Maintenance

For issues or questions:

1. Check `CONTACTS_SQL_QUERIES.md` for SQL examples
2. Review service code in `contacts_sync_service.dart`
3. Check Supabase dashboard for RLS policy errors
4. Review admin panel console for JavaScript errors
5. Enable debug logging in Flutter for troubleshooting

---

## Future Enhancements

1. **Contact Grouping:** Add ability to group contacts (Family, Work, etc.)
2. **Bulk Operations:** Bulk delete, export, import
3. **Contact Notes:** Add notes field for each contact
4. **Contact Images:** Store contact photos
5. **Sync History:** Track sync history and changes
6. **Backup/Export:** Export contacts to CSV/vCard
7. **Smart Deduplication:** Automatic duplicate detection
8. **Merge Contacts:** Merge duplicate contacts
9. **Scheduling:** Schedule automatic syncs
10. **Analytics:** Contact sync analytics for admin

---

**Last Updated:** February 1, 2026
**Version:** 1.0
