import 'package:flutter/material.dart';

void main() => runApp(const ContactDirectoryApp());

class ContactDirectoryApp extends StatelessWidget {
  const ContactDirectoryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Directory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const ContactHome(),
    );
  }
}

class Contact {
  final String name;
  final String email;
  final String phone;
  final String group;
  final String role;
  Contact({
    required this.name,
    required this.email,
    required this.phone,
    required this.group,
    required this.role,
  });
}

final _contacts = [
  Contact(name: 'Alice Johnson', email: 'alice@example.com', phone: '555-0101', group: 'Engineering', role: 'Lead Developer'),
  Contact(name: 'Bob Smith', email: 'bob@example.com', phone: '555-0102', group: 'Engineering', role: 'Backend Dev'),
  Contact(name: 'Carol White', email: 'carol@example.com', phone: '555-0103', group: 'Design', role: 'UI Designer'),
  Contact(name: 'David Brown', email: 'david@example.com', phone: '555-0104', group: 'Product', role: 'Product Manager'),
  Contact(name: 'Eva Garcia', email: 'eva@example.com', phone: '555-0105', group: 'Design', role: 'UX Researcher'),
  Contact(name: 'Frank Lee', email: 'frank@example.com', phone: '555-0106', group: 'Engineering', role: 'DevOps'),
  Contact(name: 'Grace Kim', email: 'grace@example.com', phone: '555-0107', group: 'Product', role: 'Data Analyst'),
  Contact(name: 'Henry Chen', email: 'henry@example.com', phone: '555-0108', group: 'Engineering', role: 'Mobile Dev'),
];

class ContactHome extends StatefulWidget {
  const ContactHome({super.key});
  @override
  State<ContactHome> createState() => _ContactHomeState();
}

class _ContactHomeState extends State<ContactHome> {
  String _searchQuery = '';
  String _groupFilter = 'All';

  List<Contact> get _filtered {
    return _contacts.where((c) {
      final matchSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchGroup = _groupFilter == 'All' || c.group == _groupFilter;
      return matchSearch && matchGroup;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ['All', ...{..._contacts.map((c) => c.group)}..remove('All')];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Groups',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GroupsPage(contacts: _contacts))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: groups.map((g) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(g),
                  selected: _groupFilter == g,
                  onSelected: (_) => setState(() => _groupFilter = g),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final contact = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(contact.name[0])),
                        title: Text(contact.name),
                        subtitle: Text('${contact.role} · ${contact.group}'),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ContactDetailPage(contact: contact))),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Contact',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddContactPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contact.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(contact.name[0], style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text(contact.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Center(child: Text(contact.role, style: TextStyle(fontSize: 16, color: Colors.grey[600]))),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(contact.email),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(contact.phone),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Group'),
              subtitle: Text(contact.group),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupsPage extends StatelessWidget {
  final List<Contact> contacts;
  const GroupsPage({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    final groups = <String, int>{};
    for (final c in contacts) {
      groups[c.group] = (groups[c.group] ?? 0) + 1;
    }
    final sorted = groups.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final entry = sorted[i];
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(entry.key),
            trailing: Chip(label: Text('${entry.value}')),
          );
        },
      ),
    );
  }
}

class AddContactPage extends StatelessWidget {
  const AddContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'Engineering',
              decoration: const InputDecoration(labelText: 'Group', border: OutlineInputBorder()),
              items: ['Engineering', 'Design', 'Product'].map((g) =>
                  DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
