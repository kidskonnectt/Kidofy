# Contacts Feature - Quick Reference

## What Was Added?

### 1. **Database Layer** 
- Contacts table in Supabase with RLS protection
- Automatic duplicate prevention
- Automatic timestamp management
- Performance indexes

### 2. **Flutter App**
- Contact permission handling
- Sync service for syncing device contacts to backend
- UI screen showing all synced contacts
- Search and filter functionality
- Delete contact capability

### 3. **Admin Panel**
- New "Contacts" menu item
- View all contacts from all users
- Search by name, phone, email
- Filter by contact type (has phone/email)
- Filter by user
- Delete contacts
- Statistics dashboard

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/services/contacts_sync_service.dart` | Handles all contact operations |
| `lib/screens/contacts_screen.dart` | UI for showing contacts |
| `contacts_schema.sql` | Database schema and RLS |
| `admin/index.html` | Admin panel HTML |
| `admin/script.js` | Admin panel JavaScript |
| `CONTACTS_SQL_QUERIES.md` | All SQL queries reference |

---

## API Quick Reference

### Sync Contacts
```dart
final success = await ContactsSyncService.syncContactsWithPermission();
```

### Get All Contacts
```dart
List<ContactsModel> contacts = await ContactsSyncService.getContactsForUser(userId);
```

### Search
```dart
// By name
await ContactsSyncService.searchContactsByName(userId, "John");

// By phone
await ContactsSyncService.searchContactsByPhone(userId, "+1234");

// By email
await ContactsSyncService.searchContactsByEmail(userId, "john@");
```

### Recent Contacts
```dart
await ContactsSyncService.getContactsSyncedInDays(userId, 7);
```

### Delete
```dart
await ContactsSyncService.deleteContact(contactId);
```

### Statistics
```dart
Map<String, dynamic> stats = await ContactsSyncService.getContactsStatistics(userId);
// Returns: {total_contacts, with_phone, with_email}
```

---

## Admin Panel Endpoints

### View Contacts
- Navigate to "Contacts" in sidebar
- See all contacts from all users

### Search
- Type in search box (searches name, phone, email)

### Filter
- Select filter type: All, Has Phone, Has Email
- Select specific user

### Statistics
- Bottom of page shows:
  - Total contacts synced
  - With phone number
  - With email
  - Unique users

### Delete
- Click "Delete" button in Actions column

---

## Database Quick Commands

### Check if contacts exist
```sql
SELECT COUNT(*) FROM public.contacts;
```

### View user's contacts
```sql
SELECT * FROM public.contacts WHERE user_id = '${userId}';
```

### Clear test data
```sql
DELETE FROM public.contacts WHERE created_at < NOW() - INTERVAL '1 hour';
```

### Get stats
```sql
SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) as with_phone,
  COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as with_email
FROM public.contacts;
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Contacts not syncing | Check permission, verify user logged in, check network |
| Duplicate contacts | Run duplicate removal query or re-sync |
| Admin can't see contacts | Verify admin policy exists, check RLS settings |
| Search not working | Check indexes created, verify column names |
| Slow queries | Check indexes, try pagination for large datasets |

---

## Integration Steps

1. **Execute SQL schema** in Supabase
2. **Import services** in Flutter app
3. **Add provider** to app initialization
4. **Add button** to sync contacts
5. **Navigate** to contacts screen
6. **Test** admin panel

---

## Data Model

### ContactsModel
```dart
class ContactsModel {
  String id;                    // UUID
  String userId;                // User ID (foreign key)
  String contactName;           // Contact name
  String? phoneNumber;          // Phone (optional)
  String? email;                // Email (optional)
  String? rawContactId;         // Device contact ID
  DateTime syncedAt;            // When synced
  DateTime createdAt;           // Record created
  DateTime updatedAt;           // Last update
}
```

---

## Filters Available

### In App
- All contacts
- With phone number
- With email
- Search by name/phone/email

### In Admin Panel
- All contacts
- With phone number
- With email
- By user
- Search across all fields
- Sort by sync date

---

## Performance Notes

- **Indexes**: All search columns indexed for fast queries
- **RLS**: Row-level security ensures data privacy
- **Pagination**: Use limit/offset for large datasets
- **Caching**: Consider local caching for repeated queries
- **Duplicate Prevention**: Unique constraint on (user_id, raw_contact_id)

---

## Security

- **RLS Policies**: Users can only access their own contacts
- **Admin Access**: Separate policy for admin viewing all contacts
- **Data Privacy**: Contact data is encrypted at rest in Supabase
- **Permissions**: App requests device permission before syncing

---

## Testing Checklist

- [ ] Permission request works
- [ ] Contacts sync successfully
- [ ] Duplicates prevented
- [ ] Search works (name, phone, email)
- [ ] Filters work correctly
- [ ] Delete button works
- [ ] Statistics calculate correctly
- [ ] Admin panel shows all users' contacts
- [ ] Admin filters work
- [ ] No sensitive data leaks

---

## Related Documentation

- `CONTACTS_IMPLEMENTATION_GUIDE.md` - Detailed setup guide
- `CONTACTS_SQL_QUERIES.md` - All SQL queries
- `contacts_schema.sql` - Database schema

---

**Last Updated:** February 1, 2026
