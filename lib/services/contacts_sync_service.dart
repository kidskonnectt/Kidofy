import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:kidsapp/services/supabase_service.dart';

class ContactsModel {
  final String id;
  final String userId;
  final String contactName;
  final String? phoneNumber;
  final String? email;
  final String? rawContactId;
  final DateTime syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactsModel({
    required this.id,
    required this.userId,
    required this.contactName,
    this.phoneNumber,
    this.email,
    this.rawContactId,
    required this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactsModel.fromMap(Map<String, dynamic> map) {
    return ContactsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      contactName: map['contact_name'] as String,
      phoneNumber: map['phone_number'] as String?,
      email: map['email'] as String?,
      rawContactId: map['raw_contact_id'] as String?,
      syncedAt: DateTime.parse(map['synced_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'email': email,
      'raw_contact_id': rawContactId,
      'synced_at': syncedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ContactsSyncService {
  static final client = SupabaseService.client;

  /// Request contacts permission and sync contacts to Supabase
  static Future<bool> syncContactsWithPermission() async {
    try {
      debugPrint('📱 Requesting contacts permission...');

      // Request contacts permission
      if (await FlutterContacts.requestPermission()) {
        debugPrint('✅ Contacts permission granted');
        return await syncAllContacts();
      } else {
        debugPrint('❌ Contacts permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Sync all contacts from device to Supabase
  static Future<bool> syncAllContacts() async {
    try {
      debugPrint('🔄 Starting contacts sync...');

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ User not authenticated');
        return false;
      }

      // Get all contacts from device
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (contacts.isEmpty) {
        debugPrint('⚠️ No contacts found on device');
        return true;
      }

      debugPrint('📋 Found ${contacts.length} contacts on device');

      // Validate user authentication
      if (client.auth.currentSession == null) {
        debugPrint('❌ No active session - user not authenticated');
        return false;
      }

      debugPrint('✅ User authenticated: $userId');

      // Get existing contacts from Supabase to avoid duplicates
      final existingContacts = await getContactsForUser(userId);
      final existingRawIds = {for (var c in existingContacts) c.rawContactId};

      // Prepare contacts for batch insert
      List<Map<String, dynamic>> contactsToInsert = [];
      final now = DateTime.now().toUtc();
      final nowIso = now.toIso8601String();

      for (final contact in contacts) {
        // Skip contacts without names
        final displayName = contact.displayName?.trim();
        if (displayName == null || displayName.isEmpty) {
          debugPrint('⏭️  Skipping contact without name');
          continue;
        }

        final phones = contact.phones.isNotEmpty
            ? contact.phones[0].number?.trim()
            : null;
        final emails = contact.emails.isNotEmpty
            ? contact.emails[0].address?.trim().toLowerCase()
            : null;

        // Skip if already synced
        if (existingRawIds.contains(contact.id)) {
          debugPrint('⏭️  Skipping duplicate: $displayName');
          continue;
        }

        // Validate contact has at least name (required field)
        if (displayName.isEmpty) {
          debugPrint('⏭️  Skipping: contact name is empty');
          continue;
        }

        contactsToInsert.add({
          'user_id': userId,
          'contact_name': displayName,
          'phone_number': phones,
          'email': emails,
          'raw_contact_id': contact.id,
          'synced_at': nowIso,
        });

        debugPrint('📌 Adding: $displayName | Phone: $phones | Email: $emails');
      }

      if (contactsToInsert.isEmpty) {
        debugPrint('✅ No new contacts to sync');
        return true;
      }

      debugPrint(
        '📤 Inserting ${contactsToInsert.length} contacts to Supabase...',
      );

      try {
        await client.from('contacts').insert(contactsToInsert);
        debugPrint('✅ Successfully synced ${contactsToInsert.length} contacts');
        return true;
      } catch (insertError) {
        debugPrint('❌ Error inserting contacts: $insertError');
        debugPrint(
          '📝 Attempted to insert: ${contactsToInsert.length} contacts',
        );
        debugPrint('📝 Contact data: ${contactsToInsert.toString()}');

        // Provide detailed error diagnosis
        final errorStr = insertError.toString().toLowerCase();
        if (errorStr.contains('rls') || errorStr.contains('policy')) {
          debugPrint('⚠️  RLS Policy Error - Possible causes:');
          debugPrint('   1. User ID mismatch: $userId');
          debugPrint('   2. User not authenticated');
          debugPrint('   3. RLS policies not configured correctly');
        } else if (errorStr.contains('not found') ||
            errorStr.contains('does not exist')) {
          debugPrint(
            '⚠️  Table not found - contacts table may not exist in Supabase',
          );
        } else if (errorStr.contains('foreign key')) {
          debugPrint(
            '⚠️  Foreign key error - user_id does not exist in auth.users',
          );
        } else if (errorStr.contains('unique')) {
          debugPrint(
            '⚠️  Unique constraint error - duplicate contact entry detected',
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Unexpected error syncing contacts: $e');
      debugPrint('📝 Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Get all contacts for current user
  static Future<List<ContactsModel>> getContactsForUser(String userId) async {
    try {
      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .order('contact_name', ascending: true);

      return (response as List)
          .map((e) => ContactsModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching contacts: $e');
      return [];
    }
  }

  /// Search contacts by name
  static Future<List<ContactsModel>> searchContactsByName(
    String userId,
    String searchTerm,
  ) async {
    try {
      if (searchTerm.isEmpty) {
        return getContactsForUser(userId);
      }

      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .ilike('contact_name', '%$searchTerm%')
          .order('contact_name', ascending: true);

      return (response as List)
          .map((e) => ContactsModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching contacts by name: $e');
      return [];
    }
  }

  /// Search contacts by phone number
  static Future<List<ContactsModel>> searchContactsByPhone(
    String userId,
    String searchTerm,
  ) async {
    try {
      if (searchTerm.isEmpty) {
        return getContactsForUser(userId);
      }

      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .ilike('phone_number', '%$searchTerm%')
          .order('contact_name', ascending: true);

      return (response as List)
          .map((e) => ContactsModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching contacts by phone: $e');
      return [];
    }
  }

  /// Search contacts by email
  static Future<List<ContactsModel>> searchContactsByEmail(
    String userId,
    String searchTerm,
  ) async {
    try {
      if (searchTerm.isEmpty) {
        return getContactsForUser(userId);
      }

      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .ilike('email', '%$searchTerm%')
          .order('contact_name', ascending: true);

      return (response as List)
          .map((e) => ContactsModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching contacts by email: $e');
      return [];
    }
  }

  /// Get contacts synced in last N days
  static Future<List<ContactsModel>> getContactsSyncedInDays(
    String userId,
    int days,
  ) async {
    try {
      final now = DateTime.now().toUtc();
      final daysAgo = now.subtract(Duration(days: days));

      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .gte('synced_at', daysAgo.toIso8601String())
          .order('synced_at', ascending: false);

      return (response as List)
          .map((e) => ContactsModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching recent contacts: $e');
      return [];
    }
  }

  /// Delete a contact
  static Future<bool> deleteContact(String contactId) async {
    try {
      await client.from('contacts').delete().eq('id', contactId);
      debugPrint('✅ Contact deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting contact: $e');
      return false;
    }
  }

  /// Delete all contacts for user
  static Future<bool> deleteAllContactsForUser(String userId) async {
    try {
      await client.from('contacts').delete().eq('user_id', userId);
      debugPrint('✅ All contacts deleted for user');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting all contacts: $e');
      return false;
    }
  }

  /// Get contact statistics
  static Future<Map<String, dynamic>> getContactsStatistics(
    String userId,
  ) async {
    try {
      final response = await client.rpc(
        'get_user_contacts_stats',
        params: {'p_user_id': userId},
      );

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }

      // Fallback: calculate manually
      final contacts = await getContactsForUser(userId);
      return {
        'total_contacts': contacts.length,
        'with_phone': contacts.where((c) => c.phoneNumber != null).length,
        'with_email': contacts.where((c) => c.email != null).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting contacts statistics: $e');
      return {'total_contacts': 0, 'with_phone': 0, 'with_email': 0};
    }
  }

  /// Update contact
  static Future<bool> updateContact(
    String contactId, {
    required String contactName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      await client
          .from('contacts')
          .update({
            'contact_name': contactName,
            'phone_number': phoneNumber,
            'email': email,
          })
          .eq('id', contactId);

      debugPrint('✅ Contact updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating contact: $e');
      return false;
    }
  }
}
