import 'package:flutter/material.dart';

void main() {
  runApp(const ContactsApp());
}

// ── Data Model ──────────────────────────────────────────────────────────────

enum Group { family, friends, work }

class Contact {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final Group group;

  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.group,
  });

  String get initials => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Contact copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    Group? group,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      group: group ?? this.group,
    );
  }
}

// ── Sample Data ──────────────────────────────────────────────────────────────

const List<Contact> _sampleContacts = [
  Contact(
    id: 1,
    name: 'Alice Johnson',
    phone: '+1 (555) 100-0001',
    email: 'alice@example.com',
    address: '12 Maple St, Springfield, IL 62701',
    group: Group.friends,
  ),
  Contact(
    id: 2,
    name: 'Bob Martinez',
    phone: '+1 (555) 100-0002',
    email: 'bob@example.com',
    address: '34 Oak Ave, Portland, OR 97201',
    group: Group.work,
  ),
  Contact(
    id: 3,
    name: 'Carol Williams',
    phone: '+1 (555) 100-0003',
    email: 'carol@example.com',
    address: '56 Pine Rd, Austin, TX 78701',
    group: Group.family,
  ),
  Contact(
    id: 4,
    name: 'David Lee',
    phone: '+1 (555) 100-0004',
    email: 'david@example.com',
    address: '78 Elm Blvd, Denver, CO 80201',
    group: Group.work,
  ),
  Contact(
    id: 5,
    name: 'Emma Garcia',
    phone: '+1 (555) 100-0005',
    email: 'emma@example.com',
    address: '90 Birch Ln, Seattle, WA 98101',
    group: Group.friends,
  ),
  Contact(
    id: 6,
    name: 'Frank Chen',
    phone: '+1 (555) 100-0006',
    email: 'frank@example.com',
    address: '11 Cedar Dr, Boston, MA 02101',
    group: Group.family,
  ),
  Contact(
    id: 7,
    name: 'Grace Kim',
    phone: '+1 (555) 100-0007',
    email: 'grace@example.com',
    address: '22 Walnut Way, Chicago, IL 60601',
    group: Group.work,
  ),
  Contact(
    id: 8,
    name: 'Henry Brown',
    phone: '+1 (555) 100-0008',
    email: 'henry@example.com',
    address: '33 Spruce St, Miami, FL 33101',
    group: Group.friends,
  ),
  Contact(
    id: 9,
    name: 'Isla Davis',
    phone: '+1 (555) 100-0009',
    email: 'isla@example.com',
    address: '44 Ash Ct, Phoenix, AZ 85001',
    group: Group.family,
  ),
  Contact(
    id: 10,
    name: 'James Wilson',
    phone: '+1 (555) 100-0010',
    email: 'james@example.com',
    address: '55 Hickory Pl, Nashville, TN 37201',
    group: Group.work,
  ),
];

// ── App ──────────────────────────────────────────────────────────────────────

class ContactsApp extends StatefulWidget {
  const ContactsApp({super.key});

  @override
  State<ContactsApp> createState() => _ContactsAppState();
}

class _ContactsAppState extends State<ContactsApp> {
  final _state = ContactsState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContactsProvider(
      state: _state,
      child: MaterialApp(
        title: 'Contacts',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const _HomeScaffold(),
      ),
    );
  }
}

// ── App State (lifted) ────────────────────────────────────────────────────────

class ContactsState extends ChangeNotifier {
  final List<Contact> _contacts = List<Contact>.from(_sampleContacts);
  Group? _activeGroup; // null = show all
  int _nextId = _sampleContacts.length + 1;

  List<Contact> get filtered {
    final list = _activeGroup == null
        ? List<Contact>.from(_contacts)
        : _contacts.where((c) => c.group == _activeGroup).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Group? get activeGroup => _activeGroup;

  void setGroup(Group? g) {
    _activeGroup = g;
    notifyListeners();
  }

  void addContact(Contact c) {
    _contacts.add(c);
    notifyListeners();
  }

  void deleteContact(int id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Contact makeContact({
    required String name,
    required String phone,
    required String email,
  }) {
    return Contact(
      id: _nextId++,
      name: name,
      phone: phone,
      email: email,
      address: '',
      group: Group.friends,
    );
  }
}

// Singleton-ish state kept above the widget tree via InheritedWidget.
class ContactsProvider extends InheritedNotifier<ContactsState> {
  const ContactsProvider({
    super.key,
    required ContactsState state,
    required super.child,
  }) : super(notifier: state);

  static ContactsState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ContactsProvider>()!
        .notifier!;
  }
}

// ── Home Page ─────────────────────────────────────────────────────────────────

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  String _groupLabel(Group? g) {
    if (g == null) return 'Contacts';
    switch (g) {
      case Group.family:
        return 'Family';
      case Group.friends:
        return 'Friends';
      case Group.work:
        return 'Work';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ContactsProvider.of(context);
    final contacts = state.filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupLabel(state.activeGroup)),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'Contacts',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Example Corp',
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'A simple contacts manager built with Flutter.',
                    ),
                  ],
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'about', child: Text('About')),
            ],
          ),
        ],
      ),
      drawer: const ContactsDrawer(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add contact',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: contacts.isEmpty
          ? const Center(child: Text('No contacts'))
          : ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.initials),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.phone),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactDetailPage(contact: contact),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class ContactsDrawer extends StatelessWidget {
  const ContactsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ContactsProvider.of(context);

    void select(Group? g) {
      state.setGroup(g);
      Navigator.pop(context); // close drawer
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Groups',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('All Contacts'),
            selected: state.activeGroup == null,
            onTap: () => select(null),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Family'),
            selected: state.activeGroup == Group.family,
            onTap: () => select(Group.family),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text('Friends'),
            selected: state.activeGroup == Group.friends,
            onTap: () => select(Group.friends),
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('Work'),
            selected: state.activeGroup == Group.work,
            onTap: () => select(Group.work),
          ),
        ],
      ),
    );
  }
}

// ── Contact Detail Page ───────────────────────────────────────────────────────

class ContactDetailPage extends StatelessWidget {
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final state = ContactsProvider.of(context);

    void confirmDelete() {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Remove ${contact.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          state.deleteContact(contact.id);
          Navigator.pop(context); // go back to list
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              child: Text(
                contact.initials,
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Action icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionButton(
                  icon: Icons.call,
                  label: 'Call',
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                ActionButton(
                  icon: Icons.message,
                  label: 'Message',
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                ActionButton(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            InfoRow(icon: Icons.phone, label: 'Phone', value: contact.phone),
            InfoRow(icon: Icons.email_outlined, label: 'Email', value: contact.email),
            if (contact.address.isNotEmpty)
              InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: contact.address),

            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: confirmDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          tooltip: label,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Contact Page ──────────────────────────────────────────────────────────

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = ContactsProvider.of(context);
    final contact = state.makeContact(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    state.addContact(contact);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+1 (555) 000-0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
