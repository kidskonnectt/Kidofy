# Contacts Management - SQL Queries Guide

## Overview
This document contains all SQL queries needed for the contacts management system in KidsApp. These queries can be executed in the Supabase SQL editor.

---

## 1. SCHEMA SETUP

### Create the Contacts Table
```sql
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

### Create Indexes for Performance
```sql
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_contacts_phone_number ON public.contacts(phone_number);
CREATE INDEX idx_contacts_email ON public.contacts(email);
CREATE INDEX idx_contacts_synced_at ON public.contacts(synced_at DESC);
CREATE INDEX idx_contacts_contact_name ON public.contacts(contact_name);
```

### Enable Row Level Security (RLS)
```sql
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
```

---

## 2. ROW LEVEL SECURITY (RLS) POLICIES

### Policy: Users can view their own contacts
```sql
CREATE POLICY "Users can view own contacts"
  ON public.contacts FOR SELECT
  USING ( auth.uid() = user_id );
```

### Policy: Users can insert their own contacts
```sql
CREATE POLICY "Users can insert own contacts"
  ON public.contacts FOR INSERT
  WITH CHECK ( auth.uid() = user_id );
```

### Policy: Users can update their own contacts
```sql
CREATE POLICY "Users can update own contacts"
  ON public.contacts FOR UPDATE
  USING ( auth.uid() = user_id );
```

### Policy: Users can delete their own contacts
```sql
CREATE POLICY "Users can delete own contacts"
  ON public.contacts FOR DELETE
  USING ( auth.uid() = user_id );
```

### Policy: Admins can view all contacts (Optional)
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

## 3. TRIGGERS & FUNCTIONS

### Create Function for Auto-updating timestamp
```sql
CREATE OR REPLACE FUNCTION update_contacts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Create Trigger
```sql
CREATE TRIGGER trigger_contacts_updated_at
  BEFORE UPDATE ON public.contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_contacts_updated_at();
```

---

## 4. BASIC QUERIES

### 4.1 Get all contacts for a user
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}'
ORDER BY contact_name ASC;
```

### 4.2 Get contacts count for a user
```sql
SELECT COUNT(*) as total_contacts 
FROM public.contacts 
WHERE user_id = '${userId}';
```

### 4.3 Get contacts with phone numbers
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND phone_number IS NOT NULL
ORDER BY contact_name ASC;
```

### 4.4 Get contacts with email addresses
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND email IS NOT NULL
ORDER BY contact_name ASC;
```

---

## 5. SEARCH QUERIES

### 5.1 Search by contact name (ILIKE for case-insensitive)
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND contact_name ILIKE '%${searchTerm}%'
ORDER BY contact_name ASC;
```

### 5.2 Search by phone number
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND phone_number ILIKE '%${searchTerm}%'
ORDER BY contact_name ASC;
```

### 5.3 Search by email
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND email ILIKE '%${searchTerm}%'
ORDER BY contact_name ASC;
```

### 5.4 Search by any field (name, phone, email)
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND (
  contact_name ILIKE '%${searchTerm}%' 
  OR phone_number ILIKE '%${searchTerm}%' 
  OR email ILIKE '%${searchTerm}%'
)
ORDER BY contact_name ASC;
```

---

## 6. FILTER QUERIES

### 6.1 Get contacts synced in last 7 days
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND synced_at >= NOW() - INTERVAL '7 days'
ORDER BY synced_at DESC;
```

### 6.2 Get contacts synced in last N days
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND synced_at >= NOW() - INTERVAL '${days} days'
ORDER BY synced_at DESC;
```

### 6.3 Get recently updated contacts
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}'
ORDER BY updated_at DESC
LIMIT 20;
```

### 6.4 Get contacts starting with a specific letter
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND contact_name ILIKE '${letter}%'
ORDER BY contact_name ASC;
```

---

## 7. ANALYTICS & STATISTICS QUERIES

### 7.1 Get statistics for a user
```sql
SELECT 
  COUNT(*) as total_contacts,
  COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) as with_phone,
  COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as with_email,
  COUNT(DISTINCT SUBSTR(contact_name, 1, 1)) as unique_first_letters,
  MAX(synced_at) as last_sync,
  MIN(created_at) as first_sync
FROM public.contacts
WHERE user_id = '${userId}';
```

### 7.2 Get all users and their contact counts (Admin view)
```sql
SELECT 
  u.id,
  u.email,
  COUNT(c.id) as total_contacts,
  COUNT(CASE WHEN c.phone_number IS NOT NULL THEN 1 END) as with_phone,
  COUNT(CASE WHEN c.email IS NOT NULL THEN 1 END) as with_email,
  MAX(c.synced_at) as last_sync
FROM auth.users u
LEFT JOIN public.contacts c ON u.id = c.user_id
GROUP BY u.id, u.email
ORDER BY total_contacts DESC;
```

### 7.3 Get top N users by contact count
```sql
SELECT 
  u.email,
  COUNT(c.id) as contact_count
FROM auth.users u
LEFT JOIN public.contacts c ON u.id = c.user_id
GROUP BY u.id, u.email
ORDER BY contact_count DESC
LIMIT 10;
```

### 7.4 Get contacts without phone or email
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND phone_number IS NULL 
AND email IS NULL
ORDER BY contact_name ASC;
```

---

## 8. DUPLICATE & DATA QUALITY QUERIES

### 8.1 Find duplicate contacts by name within a user
```sql
SELECT 
  contact_name,
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as ids
FROM public.contacts
WHERE user_id = '${userId}'
GROUP BY contact_name
HAVING COUNT(*) > 1
ORDER BY count DESC;
```

### 8.2 Find duplicate contacts by phone number within a user
```sql
SELECT 
  phone_number,
  COUNT(*) as count,
  STRING_AGG(id::text, ', ') as ids
FROM public.contacts
WHERE user_id = '${userId}' 
AND phone_number IS NOT NULL
GROUP BY phone_number
HAVING COUNT(*) > 1;
```

### 8.3 Find contacts with empty or whitespace-only data
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND (
  TRIM(contact_name) = '' 
  OR (phone_number IS NULL AND email IS NULL)
);
```

---

## 9. UPDATE QUERIES

### 9.1 Update a single contact
```sql
UPDATE public.contacts 
SET 
  contact_name = '${newName}',
  phone_number = '${newPhone}',
  email = '${newEmail}'
WHERE id = '${contactId}' 
AND user_id = '${userId}';
```

### 9.2 Update contact phone number
```sql
UPDATE public.contacts 
SET phone_number = '${newPhone}'
WHERE id = '${contactId}' 
AND user_id = '${userId}';
```

### 9.3 Update contact email
```sql
UPDATE public.contacts 
SET email = '${newEmail}'
WHERE id = '${contactId}' 
AND user_id = '${userId}';
```

---

## 10. DELETE QUERIES

### 10.1 Delete a single contact
```sql
DELETE FROM public.contacts 
WHERE id = '${contactId}' 
AND user_id = '${userId}';
```

### 10.2 Delete all contacts for a user
```sql
DELETE FROM public.contacts 
WHERE user_id = '${userId}';
```

### 10.3 Delete duplicate contacts (keep oldest)
```sql
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
    WHERE user_id = '${userId}'
  ) t
  WHERE rn > 1
);
```

### 10.4 Delete contacts without phone or email
```sql
DELETE FROM public.contacts 
WHERE user_id = '${userId}' 
AND phone_number IS NULL 
AND email IS NULL;
```

---

## 11. ADVANCED QUERIES

### 11.1 Get contacts with metadata (sorted by sync date)
```sql
SELECT 
  c.id,
  c.contact_name,
  c.phone_number,
  c.email,
  c.synced_at,
  c.created_at,
  c.updated_at,
  u.email as user_email
FROM public.contacts c
JOIN auth.users u ON c.user_id = u.id
WHERE c.user_id = '${userId}'
ORDER BY c.synced_at DESC;
```

### 11.2 Get contacts paginated (with offset)
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}'
ORDER BY contact_name ASC
LIMIT 50 
OFFSET ${offset};
```

### 11.3 Get contacts by sync date range
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND synced_at BETWEEN '${startDate}' AND '${endDate}'
ORDER BY synced_at DESC;
```

### 11.4 Search and filter combined
```sql
SELECT * FROM public.contacts 
WHERE user_id = '${userId}' 
AND (
  contact_name ILIKE '%${searchTerm}%' 
  OR phone_number ILIKE '%${searchTerm}%' 
  OR email ILIKE '%${searchTerm}%'
)
AND (
  phone_number IS NOT NULL OR email IS NOT NULL
)
ORDER BY contact_name ASC;
```

---

## 12. BATCH OPERATIONS

### 12.1 Batch insert contacts
```sql
INSERT INTO public.contacts (user_id, contact_name, phone_number, email, raw_contact_id)
VALUES 
  ('${userId}', 'Contact 1', '+1234567890', 'contact1@example.com', 'raw_1'),
  ('${userId}', 'Contact 2', '+0987654321', 'contact2@example.com', 'raw_2'),
  ('${userId}', 'Contact 3', NULL, 'contact3@example.com', 'raw_3')
ON CONFLICT (user_id, raw_contact_id) DO NOTHING;
```

### 12.2 Batch delete multiple contacts
```sql
DELETE FROM public.contacts 
WHERE id IN ('${id1}', '${id2}', '${id3}')
AND user_id = '${userId}';
```

---

## 13. MAINTENANCE QUERIES

### 13.1 Get database size for contacts table
```sql
SELECT 
  pg_size_pretty(pg_total_relation_size('public.contacts')) as size;
```

### 13.2 Get last 10 synced contacts per user
```sql
SELECT DISTINCT ON (user_id) 
  user_id,
  contact_name,
  synced_at
FROM public.contacts
ORDER BY user_id, synced_at DESC;
```

### 13.3 Identify inactive users (no contacts synced in 30 days)
```sql
SELECT DISTINCT u.id, u.email
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.contacts c
  WHERE c.user_id = u.id
  AND c.synced_at >= NOW() - INTERVAL '30 days'
);
```

---

## 14. RLS BYPASS (Admin Operations)

To perform admin operations that bypass RLS, use the Supabase dashboard SQL editor with an admin role, or use the service role key (server-side only).

### Example: Admin view all contacts with user details
```sql
SELECT 
  c.id,
  c.user_id,
  u.email as user_email,
  c.contact_name,
  c.phone_number,
  c.email,
  c.synced_at,
  c.created_at
FROM public.contacts c
JOIN auth.users u ON c.user_id = u.id
ORDER BY c.synced_at DESC;
```

---

## 15. TESTING QUERIES

### Insert test data
```sql
INSERT INTO public.contacts (user_id, contact_name, phone_number, email, raw_contact_id)
SELECT 
  u.id,
  'Test Contact ' || i,
  '+1' || LPAD(i::text, 10, '0'),
  'contact' || i || '@example.com',
  'test_' || i
FROM auth.users u,
GENERATE_SERIES(1, 10) as i
LIMIT 10;
```

### Verify data
```sql
SELECT COUNT(*) FROM public.contacts;
SELECT * FROM public.contacts ORDER BY created_at DESC LIMIT 5;
```

### Clean up test data
```sql
DELETE FROM public.contacts 
WHERE contact_name LIKE 'Test Contact%';
```

---

## NOTES

- Replace `${userId}`, `${searchTerm}`, etc. with actual values
- All queries use ILIKE for case-insensitive searches
- Indexes are created for better query performance
- RLS policies ensure users can only access their own data
- Use the Supabase SQL editor to execute these queries
- For production, consider adding more robust error handling in your application code
