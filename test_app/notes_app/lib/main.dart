import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

// ─── Data Model ──────────────────────────────────────────────────────────────

enum NoteCategory { all, work, personal, ideas }

extension NoteCategoryLabel on NoteCategory {
  String get label {
    switch (this) {
      case NoteCategory.all:
        return 'All';
      case NoteCategory.work:
        return 'Work';
      case NoteCategory.personal:
        return 'Personal';
      case NoteCategory.ideas:
        return 'Ideas';
    }
  }
}

class Note {
  final String id;
  String title;
  String body;
  NoteCategory category;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.updatedAt,
  });
}

// ─── App State ────────────────────────────────────────────────────────────────

class NotesStore extends ChangeNotifier {
  final List<Note> _notes = [
    Note(
      id: '1',
      title: 'Buy groceries',
      body: 'Milk, eggs, bread, butter, apples',
      category: NoteCategory.personal,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Note(
      id: '2',
      title: 'Q2 roadmap',
      body: 'Plan the feature rollout for Q2. Include API redesign and new dashboard.',
      category: NoteCategory.work,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      id: '3',
      title: 'App idea: habit tracker',
      body: 'Build a minimal habit tracker with streaks and push notifications.',
      category: NoteCategory.ideas,
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Note(
      id: '4',
      title: 'Call dentist',
      body: 'Schedule cleaning appointment for next month.',
      category: NoteCategory.personal,
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  NoteCategory _filter = NoteCategory.all;

  NoteCategory get filter => _filter;

  List<Note> get filteredNotes {
    if (_filter == NoteCategory.all) return List.unmodifiable(_notes);
    return _notes.where((n) => n.category == _filter).toList();
  }

  List<Note> get allNotes => List.unmodifiable(_notes);

  void setFilter(NoteCategory category) {
    _filter = category;
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    notifyListeners();
  }

  void updateNote(String id, String title, String body, NoteCategory category) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx].title = title;
      _notes[idx].body = body;
      _notes[idx].category = category;
      _notes[idx].updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Note? findById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── App Root ─────────────────────────────────────────────────────────────────

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final NotesStore _store = NotesStore();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(store: _store),
    );
  }
}

// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final NotesStore store;

  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NotesStore get store => widget.store;

  void _onStoreChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _openAddNote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(store: store, existingNote: null),
      ),
    );
  }

  void _openDetail(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(store: store, noteId: note.id),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Color _categoryColor(NoteCategory cat) {
    switch (cat) {
      case NoteCategory.work:
        return Colors.blue;
      case NoteCategory.personal:
        return Colors.green;
      case NoteCategory.ideas:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = store.filteredNotes;
    final currentFilter = store.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(store: store, onTap: _openDetail),
              );
            },
          ),
          // Category filter popup menu
          PopupMenuButton<NoteCategory>(
            tooltip: 'Filter by category',
            icon: const Icon(Icons.filter_list),
            onSelected: (cat) => store.setFilter(cat),
            itemBuilder: (_) => NoteCategory.values
                .map(
                  (cat) => PopupMenuItem<NoteCategory>(
                    value: cat,
                    child: Row(
                      children: [
                        if (currentFilter == cat)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(cat.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    currentFilter == NoteCategory.all
                        ? 'No notes yet.\nTap + to add one.'
                        : 'No ${currentFilter.label} notes.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = notes[index];
                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await _confirmDelete(context, note.title);
                  },
                  onDismissed: (_) {
                    store.deleteNote(note.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${note.title}" deleted'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatDate(note.updatedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _categoryColor(note.category),
                      child: Text(
                        note.category.label[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit note',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditNoteScreen(
                              store: store,
                              existingNote: note,
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () => _openDetail(note),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddNote,
        tooltip: 'Add note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Add / Edit Note Screen ───────────────────────────────────────────────────

class EditNoteScreen extends StatefulWidget {
  final NotesStore store;
  final Note? existingNote;

  const EditNoteScreen({
    super.key,
    required this.store,
    required this.existingNote,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late NoteCategory _selectedCategory;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleCtrl = TextEditingController(text: note?.title ?? '');
    _bodyCtrl = TextEditingController(text: note?.body ?? '');
    _selectedCategory = note?.category ?? NoteCategory.personal;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (_isEditing) {
      widget.store.updateNote(
        widget.existingNote!.id,
        title,
        body,
        _selectedCategory,
      );
    } else {
      widget.store.addNote(
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          category: _selectedCategory,
          updatedAt: DateTime.now(),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter note title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Body field (multiline)
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Body',
                hintText: 'Write your note here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),
            // Category selector
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: NoteCategory.values
                  .where((c) => c != NoteCategory.all)
                  .map(
                    (cat) => ChoiceChip(
                      label: Text(cat.label),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Note Detail Screen ───────────────────────────────────────────────────────

class NoteDetailScreen extends StatefulWidget {
  final NotesStore store;
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.store,
    required this.noteId,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  void _onStoreChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _editNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(store: widget.store, existingNote: note),
      ),
    );
  }

  Future<void> _confirmDeleteAndPop(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Permanently delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.store.deleteNote(note.id);
      Navigator.of(context).pop();
    }
  }

  String _formatFull(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final note = widget.store.findById(widget.noteId);

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const Center(child: Text('Note not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _editNote(note),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Chip(
              label: Text(note.category.label),
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatFull(note.updatedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 24),
            // Note body
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  note.body.isEmpty ? '(No content)' : note.body,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Note'),
                onPressed: () => _confirmDeleteAndPop(note),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Delegate ──────────────────────────────────────────────────────────

class NotesSearchDelegate extends SearchDelegate<Note?> {
  final NotesStore store;
  final void Function(Note note) onTap;

  NotesSearchDelegate({required this.store, required this.onTap});

  @override
  String get searchFieldLabel => 'Search notes...';

  List<Note> _results() {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return store.allNotes;
    return store.allNotes
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _results();
    if (results.isEmpty) {
      return const Center(child: Text('No matching notes.'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final note = results[i];
        return ListTile(
          leading: const Icon(Icons.note),
          title: Text(note.title),
          subtitle: Text(
            note.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, note);
            onTap(note);
          },
        );
      },
    );
  }
}
