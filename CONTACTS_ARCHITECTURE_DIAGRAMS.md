# Contacts System - Architecture & Flow Diagrams

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         KIDSAPP SYSTEM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────────────┐    │
│  │   FLUTTER APP    │         │    ADMIN PANEL (WEB)     │    │
│  ├──────────────────┤         ├──────────────────────────┤    │
│  │ • Contacts UI    │         │ • Contact Dashboard      │    │
│  │ • Sync Service   │         │ • Search & Filter        │    │
│  │ • Permission     │         │ • Statistics             │    │
│  │ • Search/Filter  │         │ • Management             │    │
│  └────────┬─────────┘         └────────┬─────────────────┘    │
│           │                           │                       │
│           └───────────────┬───────────┘                       │
│                           │                                   │
│                 ┌─────────▼──────────┐                        │
│                 │  SUPABASE (CLOUD)  │                        │
│                 ├────────────────────┤                        │
│                 │ • PostgreSQL DB    │                        │
│                 │ • Auth System      │                        │
│                 │ • RLS Policies     │                        │
│                 │ • Contacts Table   │                        │
│                 │ • Indexes & Views  │                        │
│                 └────────────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Mobile Device ←→ Cloud Backend ←→ Web Admin
```

---

## 2. Contact Sync Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTACT SYNC FLOW                            │
├─────────────────────────────────────────────────────────────────┤

1. USER INITIATES SYNC
   │
   ▼
   User taps "Sync Contacts" button
   │
   ▼

2. REQUEST PERMISSION
   │
   ├─► FlutterContacts.requestPermission()
   │
   ├─► User grants/denies
   │
   └─► IF DENIED: Show error, stop
   
   └─► IF GRANTED: Continue
       │
       ▼

3. FETCH DEVICE CONTACTS
   │
   ├─► FlutterContacts.getContacts()
   │
   ├─► Get all contacts from device
   │
   ├─► Extract: name, phone, email
   │
   └─► Store raw_contact_id for dedup
       │
       ▼

4. PREPARE FOR SYNC
   │
   ├─► Get existing contacts from DB
   │
   ├─► Check for duplicates (raw_contact_id)
   │
   ├─► Create batch for new contacts
   │
   └─► Format data for insertion
       │
       ▼

5. BATCH INSERT TO SUPABASE
   │
   ├─► Contacts.insert(batch)
   │
   ├─► ON CONFLICT DO NOTHING
   │
   ├─► RLS CHECK: user_id = auth.uid()
   │
   └─► RLS CHECK: Raw contact ID unique
       │
       ▼

6. DATABASE OPERATIONS
   │
   ├─► Insert records
   │
   ├─► Trigger: set created_at
   │
   ├─► Trigger: set synced_at
   │
   ├─► Index: update indexes
   │
   └─► Return success count
       │
       ▼

7. USER FEEDBACK
   │
   ├─► Show success message
   │
   ├─► Display sync count
   │
   ├─► Refresh contacts list
   │
   └─► Show statistics
```

---

## 3. Search & Filter Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   SEARCH & FILTER FLOW                          │
├─────────────────────────────────────────────────────────────────┤

FLUTTER APP
───────────

User types in search box
│
▼
SearchContactsByName/Phone/Email()
│
├─► SELECT * FROM contacts
│
├─► WHERE user_id = ${userId}
│
├─► WHERE field ILIKE '%term%'
│
├─► ORDER BY contact_name
│
▼
Results returned to UI
│
▼
User applies filter (All/Phone/Email)
│
▼
Filter applied in-memory (JavaScript/Dart)
│
▼
Filtered list displayed


ADMIN PANEL
───────────

Admin types in search box
│
▼
filterContacts() called
│
├─► Get search term
│
├─► Get filter type (All/Phone/Email)
│
├─► Get filter user
│
▼
Filter allContacts array
│
├─► For each contact:
│   ├─► Check name match
│   ├─► Check phone match
│   ├─► Check email match
│   ├─► Check type filter
│   ├─► Check user filter
│   └─► Include if all pass
│
▼
renderContacts(filtered)
│
├─► Clear table
│
├─► Add rows for filtered contacts
│
└─► Update statistics
```

---

## 4. Admin Panel Load Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              ADMIN PANEL CONTACTS LOAD FLOW                     │
├─────────────────────────────────────────────────────────────────┤

Admin clicks "Contacts" in sidebar
│
▼
showSection('contacts')
│
├─► Hide other sections
│
├─► Show contacts section
│
├─► Update title
│
└─► Call loadDashboardData('contacts')
    │
    ▼
    loadDashboardData('contacts') called
    │
    ├─► Query: SELECT contacts WITH auth.users JOIN
    │
    ├─► Order by synced_at DESC
    │
    ▼
    Response received
    │
    ├─► Store in allContacts
    │
    ├─► Call renderContacts(data)
    │   │
    │   ├─► Populate table rows
    │   │
    │   ├─► Make phone clickable (tel:)
    │   │
    │   ├─► Make email clickable (mailto:)
    │   │
    │   └─► Add delete buttons
    │
    ├─► Call calculateContactsStats(data)
    │   │
    │   ├─► Count total
    │   │
    │   ├─► Count with phone
    │   │
    │   ├─► Count with email
    │   │
    │   └─► Update statistics display
    │
    └─► Call populateContactsUserFilter()
        │
        ├─► Get unique users
        │
        ├─► Populate user dropdown
        │
        └─► Ready for filtering
            │
            ▼
    Page fully loaded and interactive
```

---

## 5. Database Schema Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      CONTACTS TABLE                             │
├─────────────────────────────────────────────────────────────────┤

┌──────────────────────────────────────────┐
│ contacts                                 │
├──────────────────────────────────────────┤
│ id (UUID) ⭐ PRIMARY KEY                │
├──────────────────────────────────────────┤
│ user_id (UUID) 🔗 FOREIGN KEY           │
│           ↓                              │
│      auth.users(id)                      │
├──────────────────────────────────────────┤
│ contact_name (TEXT) NOT NULL             │
│ phone_number (TEXT)                      │
│ email (TEXT)                             │
│ raw_contact_id (TEXT)                    │
├──────────────────────────────────────────┤
│ synced_at (TIMESTAMP)                    │
│ created_at (TIMESTAMP)                   │
│ updated_at (TIMESTAMP)                   │
├──────────────────────────────────────────┤
│ UNIQUE(user_id, raw_contact_id)          │
│ CONSTRAINT: RLS ENABLED                  │
└──────────────────────────────────────────┘

📊 INDEXES
─────────
│ idx_contacts_user_id
│ idx_contacts_phone_number
│ idx_contacts_email
│ idx_contacts_synced_at
│ idx_contacts_contact_name

🔒 RLS POLICIES
───────────────
│ Users can view own contacts
│ Users can insert own contacts
│ Users can update own contacts
│ Users can delete own contacts

⚙️ TRIGGERS
──────────
│ trigger_contacts_updated_at (auto-update updated_at)
```

---

## 6. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      COMPLETE DATA FLOW                         │
├─────────────────────────────────────────────────────────────────┤

DEVICE CONTACTS
      ↓
      │ (FlutterContacts.getContacts)
      ↓
EXTRACT DATA (name, phone, email)
      ↓
      │ (Check for duplicates)
      ↓
PREPARE BATCH
      ↓
      │ (ContactsSyncService.syncAllContacts)
      ↓
SEND TO SUPABASE
      ↓
      │ (HTTPS POST)
      ↓
DATABASE RECEIVED
      ↓
      │ (RLS Policy Check)
      │ ├─► user_id = auth.uid()? ✓
      │ ├─► raw_contact_id unique? ✓
      │ └─► Proceed
      ↓
TRANSACTION STARTED
      ↓
      │ (Insert records)
      ↓
TRIGGERS FIRED
      ├─► created_at = NOW()
      ├─► synced_at = NOW()
      └─► updated_at = NOW()
      ↓
INDEXES UPDATED
      ├─► idx_contacts_user_id
      ├─► idx_contacts_phone_number
      ├─► idx_contacts_email
      ├─► idx_contacts_synced_at
      └─► idx_contacts_contact_name
      ↓
TRANSACTION COMMITTED
      ↓
SUCCESS RETURNED
      ↓
      │ (App receives success)
      ↓
UI UPDATED
      ├─► Show success message
      ├─► Refresh contacts list
      └─► Update statistics
      ↓
      │ (User sees data)
      │
      ├─► In Flutter App
      │   ├─► View all contacts
      │   ├─► Search contacts
      │   ├─► Filter contacts
      │   └─► See statistics
      │
      └─► In Admin Panel
          ├─► View all users' contacts
          ├─► Search across all
          ├─► Filter by type/user
          └─► See system statistics
```

---

## 7. Security Model

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECURITY MODEL                             │
├─────────────────────────────────────────────────────────────────┤

DEVICE LEVEL
────────────
User
  ↓
  ├─► [PERMISSION CHECK]
  │   ├─► Request permission
  │   ├─► User grants/denies
  │   └─► Only proceed if granted
  ↓

NETWORK LEVEL
─────────────
App ←──HTTPS/SSL───→ Supabase
  │                    │
  └─── Encrypted in transit ───┘

AUTHENTICATION LEVEL
────────────────────
User Login
  ↓
  ├─► Email + Password
  │
  ├─► Firebase/Supabase Auth
  │
  └─► JWT Token obtained
      │
      ▼
  All requests include token
      │
      ├─► Token verified server-side
      │
      └─► auth.uid() extracted from token

DATABASE LEVEL
──────────────
RLS POLICIES CHECK
  │
  ├─► Policy 1: user_id = auth.uid()?
  │   └─► IF NO: DENY
  │
  ├─► Policy 2: raw_contact_id unique?
  │   └─► IF NO: DENY (CONFLICT)
  │
  ├─► Policy 3: Is admin?
  │   └─► IF YES: Allow all access
  │
  └─► IF YES: Allow operation

ENCRYPTION LEVEL
────────────────
Data at Rest
  ├─► PostgreSQL encryption
  │
  ├─► Supabase managed keys
  │
  └─► Automatic backups encrypted

Data in Transit
  ├─► HTTPS/TLS
  │
  ├─► Certificate validation
  │
  └─► No unencrypted transmission
```

---

## 8. Search Query Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│              SEARCH QUERY OPTIMIZATION                          │
├─────────────────────────────────────────────────────────────────┤

WITHOUT INDEXES (SLOW)
──────────────────────
SELECT * FROM contacts
  ↓
  Full table scan
  ├─► Scan row 1 ... NO
  ├─► Scan row 2 ... NO
  ├─► Scan row 3 ... NO
  ├─► ... (millions of rows)
  └─► Time: SECONDS ⚠️

WITH INDEXES (FAST)
───────────────────
SELECT * FROM contacts
WHERE contact_name ILIKE '%john%'
  ↓
  B-tree index lookup
  ├─► Jump to 'john' entries
  ├─► Return matching rows
  └─► Time: MILLISECONDS ✓

INDEX STRATEGY
──────────────
┌─────────────────────────┐
│ contact_name INDEX      │
├─────────────────────────┤
│ A → names starting A    │
│ B → names starting B    │
│ ...                     │
│ Z → names starting Z    │
└─────────────────────────┘

┌─────────────────────────┐
│ phone_number INDEX      │
├─────────────────────────┤
│ +1 → US numbers        │
│ +44 → UK numbers       │
│ +91 → India numbers    │
│ ...                     │
└─────────────────────────┘

Results: ~1000x faster queries!
```

---

## 9. Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   ERROR HANDLING FLOW                           │
├─────────────────────────────────────────────────────────────────┤

SYNC ERROR
──────────
Sync fails
  ↓
  ├─► Permission denied?
  │   └─► Show: "Grant permission to sync"
  │
  ├─► Network error?
  │   └─► Show: "Check internet connection"
  │
  ├─► Authentication failed?
  │   └─► Show: "Please login again"
  │
  ├─► Database error?
  │   └─► Show: "Sync failed, try again"
  │
  └─► Unknown error?
      └─► Show: "An error occurred"
          └─► Log: Full error details


SEARCH ERROR
────────────
Search fails
  ↓
  ├─► Invalid search term?
  │   └─► Show: Empty results
  │
  ├─► Database timeout?
  │   └─► Show: "Search taking too long"
  │
  └─► User not authenticated?
      └─► Show: "Please login"


FILTER ERROR
────────────
Filter fails
  ↓
  ├─► Invalid filter value?
  │   └─► Show: "Invalid filter"
  │
  └─► No results for filter?
      └─► Show: "No contacts match"
```

---

## 10. Performance Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│              PERFORMANCE TIMELINE                               │
├─────────────────────────────────────────────────────────────────┤

CONTACT SYNC (100 CONTACTS)
────────────────────────────
0ms    ├─► Start sync
100ms  ├─► Permission granted
500ms  ├─► Contacts fetched from device
1000ms ├─► Duplicates checked (in memory)
1500ms ├─► Batch prepared
2000ms ├─► Sent to Supabase
3000ms ├─► Database: RLS check ✓
3200ms ├─► Database: Insert transactions
3500ms ├─► Database: Indexes updated
3800ms ├─► Database: Triggers fired
4000ms ├─► Response received
4200ms ├─► UI updated
4500ms └─► User sees results ✓

Total: ~4.5 seconds (acceptable)


SEARCH (1000 CONTACTS)
──────────────────────
0ms    ├─► User types "john"
50ms   ├─► Search triggered
100ms  ├─► Index lookup begins
200ms  ├─► Results filtered
250ms  ├─► UI updated
300ms  └─► User sees results ✓

Total: ~300ms (fast!)


ADMIN PANEL LOAD
────────────────
0ms    ├─► Click "Contacts"
50ms   ├─► Query to database
300ms  ├─► Results received
350ms  ├─► Table rendered
400ms  ├─► Filters populated
450ms  ├─► Statistics calculated
500ms  └─► Page interactive ✓

Total: ~500ms (quick!)
```

---

## 11. State Management

```
┌─────────────────────────────────────────────────────────────────┐
│               STATE MANAGEMENT ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────┤

FLUTTER APP
───────────

ContactsSyncProvider
├─► contacts: List<ContactsModel>
├─► filteredContacts: List<ContactsModel>
├─► isLoading: bool
├─► errorMessage: String?
├─► searchQuery: String
├─► filterType: String
│
├─► Methods:
│   ├─► loadContacts(userId)
│   ├─► setSearchQuery(query)
│   ├─► setFilterType(type)
│   ├─► applyFilters()
│   └─► refreshContacts(userId)
│
└─► Notifies UI on changes


ADMIN PANEL
───────────

Global Variables
├─► allContacts: []
├─► allUsers: []
├─► allVideos: []
├─► allReports: []
├─► allCategories: []
├─► currentUser: null
│
└─► Updated by:
    ├─► loadDashboardData()
    ├─► renderContacts()
    ├─► filterContacts()
    └─► deleteContact()
```

---

This document provides a comprehensive visual representation of the entire contacts management system architecture, data flows, and processes.

**Last Updated:** February 1, 2026
