import 'package:flutter/material.dart';

void main() => runApp(const NoteEditorApp());

class NoteEditorApp extends StatelessWidget {
  const NoteEditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const NoteHome(),
    );
  }
}

class Note {
  String title;
  String body;
  String category;
  Color color;
  bool pinned;
  bool archived;
  Note({
    required this.title,
    required this.body,
    required this.category,
    this.color = Colors.white,
    this.pinned = false,
    this.archived = false,
  });
}

class NoteHome extends StatefulWidget {
  const NoteHome({super.key});
  @override
  State<NoteHome> createState() => _NoteHomeState();
}

class _NoteHomeState extends State<NoteHome> {
  String _filter = 'All';
  final List<Note> _notes = [
    Note(title: 'Meeting Notes', body: 'Discuss Q1 roadmap and priorities', category: 'Work', color: Colors.blue),
    Note(title: 'Grocery List', body: 'Milk, eggs, bread, avocados', category: 'Personal', pinned: true),
    Note(title: 'Flutter Ideas', body: 'Try Riverpod with clean architecture', category: 'Tech', color: Colors.purple),
    Note(title: 'Book List', body: 'Atomic Habits, Deep Work, The Lean Startup', category: 'Personal'),
    Note(title: 'Sprint Retro', body: 'Improve CI pipeline speed', category: 'Work', color: Colors.blue),
    Note(title: 'Workout Plan', body: 'Mon: Chest, Wed: Back, Fri: Legs', category: 'Health', color: Colors.green),
    Note(title: 'API Design', body: 'REST endpoints for user service', category: 'Tech', color: Colors.purple, archived: true),
    Note(title: 'Vacation Ideas', body: 'Japan, Iceland, New Zealand', category: 'Personal', archived: true),
  ];

  List<Note> get _activeNotes => _notes.where((n) => !n.archived).toList();

  List<Note> get _filtered {
    final active = _activeNotes;
    final list = _filter == 'All' ? active : active.where((n) => n.category == _filter).toList();
    list.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...{..._notes.map((n) => n.category)}..remove('All')];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Archive',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ArchivePage(
                  notes: _notes.where((n) => n.archived).toList(),
                  onRestore: (note) => setState(() => note.archived = false),
                ))),
          ),
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: 'Categories',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CategoriesPage(notes: _notes))),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: categories.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(c),
                  selected: _filter == c,
                  onSelected: (_) => setState(() => _filter = c),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No notes found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final note = _filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        color: note.color == Colors.white ? null : note.color.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: note.pinned
                              ? const Icon(Icons.push_pin, color: Colors.orange)
                              : const Icon(Icons.note),
                          title: Text(note.title),
                          subtitle: Text(note.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Options',
                            onSelected: (action) {
                              setState(() {
                                switch (action) {
                                  case 'pin':
                                    note.pinned = !note.pinned;
                                    break;
                                  case 'archive':
                                    note.archived = true;
                                    break;
                                }
                              });
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(note.pinned ? 'Unpin' : 'Pin'),
                              ),
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive'),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => EditNotePage(note: note)));
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Note',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddNotePage()));
          if (result != null) {
            setState(() => _notes.insert(0, Note(
              title: result['title']!,
              body: result['body']!,
              category: result['category']!,
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});
  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'Personal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Work', 'Personal', 'Tech', 'Health'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'title': _titleCtrl.text,
                      'body': _bodyCtrl.text,
                      'category': _category,
                    });
                  }
                },
                child: const Text('Save Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});
  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _bodyCtrl = TextEditingController(text: widget.note.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: () {
              widget.note.title = _titleCtrl.text;
              widget.note.body = _bodyCtrl.text;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArchivePage extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onRestore;
  const ArchivePage({super.key, required this.notes, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No archived notes'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final note = notes[i];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.unarchive),
                    tooltip: 'Restore',
                    onPressed: () {
                      onRestore(note);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class CategoriesPage extends StatelessWidget {
  final List<Note> notes;
  const CategoriesPage({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final categories = <String, int>{};
    for (final n in notes) {
      categories[n.category] = (categories[n.category] ?? 0) + 1;
    }
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
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
