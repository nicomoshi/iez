import 'package:flutter/material.dart';

void main() {
  runApp(const ContactBookApp());
}

class Contact {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String address;
  final String group;
  final bool isFavorite;

  const Contact({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.address = '',
    this.group = 'All',
    this.isFavorite = false,
  });

  String get fullName => '$firstName $lastName';
}

final List<Contact> seedContacts = [
  const Contact(
    firstName: 'Alice',
    lastName: 'Johnson',
    phone: '555-0101',
    email: 'alice@example.com',
    address: '123 Maple St',
    group: 'Family',
    isFavorite: true,
  ),
  const Contact(
    firstName: 'Bob',
    lastName: 'Smith',
    phone: '555-0102',
    email: 'bob@example.com',
    address: '456 Oak Ave',
    group: 'Work',
  ),
  const Contact(
    firstName: 'Carol',
    lastName: 'White',
    phone: '555-0103',
    email: 'carol@example.com',
    address: '789 Pine Rd',
    group: 'Friends',
    isFavorite: true,
  ),
  const Contact(
    firstName: 'David',
    lastName: 'Brown',
    phone: '555-0104',
    email: 'david@example.com',
    address: '321 Elm Dr',
    group: 'Work',
  ),
  const Contact(
    firstName: 'Eve',
    lastName: 'Davis',
    phone: '555-0105',
    email: 'eve@example.com',
    address: '654 Birch Ln',
    group: 'Family',
  ),
];

class ContactBookApp extends StatelessWidget {
  const ContactBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Contact> _contacts;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _contacts = List.from(seedContacts);
  }

  void _addContact(Contact contact) {
    setState(() {
      _contacts.add(contact);
    });
  }

  void _deleteContact(Contact contact) {
    setState(() {
      _contacts.removeWhere(
          (c) => c.firstName == contact.firstName && c.lastName == contact.lastName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ContactsTab(
        contacts: _contacts,
        selectedFilter: _selectedFilter,
        onFilterChanged: (f) => setState(() => _selectedFilter = f),
        onAddContact: _addContact,
        onDeleteContact: _deleteContact,
      ),
      const GroupsTab(),
      FavoritesTab(contacts: _contacts),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.star),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}

// --- Contacts Tab ---

class ContactsTab extends StatelessWidget {
  final List<Contact> contacts;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<Contact> onAddContact;
  final ValueChanged<Contact> onDeleteContact;

  const ContactsTab({
    super.key,
    required this.contacts,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onAddContact,
    required this.onDeleteContact,
  });

  List<Contact> get _filtered {
    if (selectedFilter == 'All') return contacts;
    return contacts.where((c) => c.group == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(contacts: contacts),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['All', 'Family', 'Work', 'Friends'].map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selectedFilter == label,
                    onSelected: (_) => onFilterChanged(label),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final contact = filtered[index];
                return ListTile(
                  title: Text(contact.fullName),
                  subtitle: Text(contact.phone),
                  leading: CircleAvatar(
                    child: Text(contact.firstName[0]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactDetailPage(
                          contact: contact,
                          onDelete: () {
                            onDeleteContact(contact);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Contact>(
            context,
            MaterialPageRoute(builder: (_) => const AddContactPage()),
          );
          if (result != null) {
            onAddContact(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}

// --- Contact Detail Page ---

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  final VoidCallback onDelete;

  const ContactDetailPage({
    super.key,
    required this.contact,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              child: Text(
                contact.firstName[0],
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              contact.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTile(label: 'Phone', value: contact.phone),
          _SectionTile(label: 'Email', value: contact.email),
          _SectionTile(label: 'Address', value: contact.address),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            label: const Text('Delete Contact'),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String label;
  final String value;

  const _SectionTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          const Divider(),
        ],
      ),
    );
  }
}

// --- Add Contact Page ---

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final contact = Contact(
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    email: _emailController.text.trim(),
                  );
                  Navigator.pop(context, contact);
                }
              },
              child: const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Groups Tab ---

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {'name': 'Family', 'count': 2},
      {'name': 'Work', 'count': 2},
      {'name': 'Friends', 'count': 1},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(group['name'] as String),
            subtitle: Text('${group['count']} members'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}

// --- Favorites Tab ---

class FavoritesTab extends StatelessWidget {
  final List<Contact> contacts;

  const FavoritesTab({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    final favorites = contacts.where((c) => c.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final contact = favorites[index];
          return ListTile(
            leading: CircleAvatar(child: Text(contact.firstName[0])),
            title: Text(contact.fullName),
            subtitle: Text(contact.phone),
            trailing: const Icon(Icons.star, color: Colors.amber),
          );
        },
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final List<Contact> contacts;

  const SearchPage({super.key, required this.contacts});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Contact> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.contacts;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = widget.contacts;
      } else {
        final q = query.toLowerCase();
        _results = widget.contacts
            .where((c) =>
                c.fullName.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                c.email.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final contact = _results[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(contact.firstName[0])),
                  title: Text(contact.fullName),
                  subtitle: Text(contact.phone),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
