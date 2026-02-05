import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kidsapp/services/contacts_sync_service.dart';

class ContactsSyncProvider extends ChangeNotifier {
  List<ContactsModel> contacts = [];
  List<ContactsModel> filteredContacts = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String filterType = 'all'; // all, phone, email

  Future<void> loadContacts(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      contacts = await ContactsSyncService.getContactsForUser(userId);
      applyFilters();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error loading contacts: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  void setFilterType(String type) {
    filterType = type;
    applyFilters();
  }

  void applyFilters() {
    filteredContacts = contacts.where((contact) {
      final matchesSearch =
          searchQuery.isEmpty ||
          contact.contactName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          (contact.phoneNumber?.contains(searchQuery) ?? false) ||
          (contact.email?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

      final matchesFilter =
          filterType == 'all' ||
          (filterType == 'phone' && contact.phoneNumber != null) ||
          (filterType == 'email' && contact.email != null);

      return matchesSearch && matchesFilter;
    }).toList();

    notifyListeners();
  }

  Future<void> refreshContacts(String userId) async {
    await loadContacts(userId);
  }
}

class ContactsScreen extends StatefulWidget {
  final String userId;

  const ContactsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late ContactsSyncProvider _provider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContactsSyncProvider>();
    _provider.loadContacts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contacts'),
        backgroundColor: Colors.purple[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final success =
                  await ContactsSyncService.syncContactsWithPermission();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Contacts synced successfully'
                          : 'Failed to sync contacts',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                _provider.refreshContacts(widget.userId);
              }
            },
          ),
        ],
      ),
      body: Consumer<ContactsSyncProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshContacts(widget.userId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        provider.setSearchQuery(value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: provider.filterType == 'all',
                          onSelected: (selected) {
                            if (selected) provider.setFilterType('all');
                          },
                        ),
                        FilterChip(
                          label: const Text('Has Phone'),
                          selected: provider.filterType == 'phone',
                          onSelected: (selected) {
                            if (selected) provider.setFilterType('phone');
                          },
                        ),
                        FilterChip(
                          label: const Text('Has Email'),
                          selected: provider.filterType == 'email',
                          onSelected: (selected) {
                            if (selected) provider.setFilterType('email');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Contacts List
              Expanded(
                child: provider.filteredContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.contacts.isEmpty
                                  ? 'No contacts synced yet'
                                  : 'No contacts match your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (provider.contacts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final success =
                                        await ContactsSyncService.syncContactsWithPermission();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Contacts synced successfully'
                                                : 'Failed to sync contacts',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                      provider.refreshContacts(widget.userId);
                                    }
                                  },
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Sync Contacts from Phone'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = provider.filteredContacts[index];
                          return ContactCard(contact: contact);
                        },
                      ),
              ),
              // Stats Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${provider.contacts.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Total'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${provider.contacts.where((c) => c.phoneNumber != null).length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('With Phone'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${provider.contacts.where((c) => c.email != null).length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('With Email'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ContactCard extends StatelessWidget {
  final ContactsModel contact;

  const ContactCard({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[600],
          child: Text(
            contact.contactName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(contact.contactName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phoneNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(contact.phoneNumber ?? '')),
                  ],
                ),
              ),
            if (contact.email != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(contact.email ?? '')),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Synced: ${contact.syncedAt.toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Contact'),
                    content: Text(
                      'Are you sure you want to delete ${contact.contactName}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final success = await ContactsSyncService.deleteContact(
                    contact.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Contact deleted'
                              : 'Failed to delete contact',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
