import 'package:flutter/material.dart';

void main() {
  runApp(const BookmarkManagerApp());
}

// ─── Data model ───────────────────────────────────────────────────────────────

class Bookmark {
  final String id;
  String title;
  String url;
  String category;
  bool isFavorite;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    this.isFavorite = false,
    required this.createdAt,
  });
}

// ─── Singleton app state ──────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final List<Bookmark> _bookmarks = [
    Bookmark(
      id: '1',
      title: 'Flutter Docs',
      url: 'https://docs.flutter.dev',
      category: 'Learning',
      createdAt: DateTime(2024, 1, 10),
    ),
    Bookmark(
      id: '2',
      title: 'GitHub',
      url: 'https://github.com',
      category: 'Work',
      isFavorite: true,
      createdAt: DateTime(2024, 2, 5),
    ),
    Bookmark(
      id: '3',
      title: 'YouTube',
      url: 'https://youtube.com',
      category: 'Personal',
      createdAt: DateTime(2024, 3, 1),
    ),
    Bookmark(
      id: '4',
      title: 'Stack Overflow',
      url: 'https://stackoverflow.com',
      category: 'Work',
      isFavorite: true,
      createdAt: DateTime(2024, 3, 15),
    ),
    Bookmark(
      id: '5',
      title: 'Coursera',
      url: 'https://coursera.org',
      category: 'Learning',
      createdAt: DateTime(2024, 4, 20),
    ),
  ];

  String _selectedCategory = 'All';
  String _sortBy = 'Date';
  bool _showUrls = true;
  bool _compactView = false;
  bool _showFavoritesOnly = false;

  List<Bookmark> get bookmarks => _bookmarks;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get showUrls => _showUrls;
  bool get compactView => _compactView;
  bool get showFavoritesOnly => _showFavoritesOnly;

  List<Bookmark> get filteredBookmarks {
    var list = _bookmarks.where((b) {
      if (_showFavoritesOnly && !b.isFavorite) return false;
      if (_selectedCategory != 'All' && b.category != _selectedCategory) return false;
      return true;
    }).toList();

    if (_sortBy == 'Date') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Title') {
      list.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortBy == 'Category') {
      list.sort((a, b) => a.category.compareTo(b.category));
    }
    return list;
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setSortBy(String s) {
    _sortBy = s;
    notifyListeners();
  }

  void setShowUrls(bool v) {
    _showUrls = v;
    notifyListeners();
  }

  void setCompactView(bool v) {
    _compactView = v;
    notifyListeners();
  }

  void setShowFavoritesOnly(bool v) {
    _showFavoritesOnly = v;
    notifyListeners();
  }

  void resetToAll() {
    _selectedCategory = 'All';
    _showFavoritesOnly = false;
    notifyListeners();
  }

  void addBookmark(String title, String url, String category) {
    _bookmarks.add(Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      url: url,
      category: category,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final b = _bookmarks.firstWhere((b) => b.id == id);
    b.isFavorite = !b.isFavorite;
    notifyListeners();
  }

  void updateBookmark(String id, String title, String url, String category) {
    final b = _bookmarks.firstWhere((b) => b.id == id);
    b.title = title;
    b.url = url;
    b.category = category;
    notifyListeners();
  }

  void deleteBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}

// ─── App root ─────────────────────────────────────────────────────────────────

class BookmarkManagerApp extends StatelessWidget {
  const BookmarkManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookmark Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final bookmarks = state.filteredBookmarks;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bookmarks'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          drawer: AppDrawer(state: state),
          body: Column(
            children: [
              _CategoryFilterRow(state: state),
              Expanded(
                child: bookmarks.isEmpty
                    ? const Center(child: Text('No bookmarks found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) => BookmarkCard(
                          bookmark: bookmarks[index],
                          state: state,
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: '+',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddBookmarkDialog(state: state),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// ─── Category filter row ──────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  final AppState state;
  const _CategoryFilterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    const categories = ['All', 'Work', 'Personal', 'Learning'];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: state.selectedCategory == cat,
              onSelected: (_) => state.setCategory(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Bookmark card ────────────────────────────────────────────────────────────

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final AppState state;

  const BookmarkCard({super.key, required this.bookmark, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(bookmark: bookmark, state: state),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (state.showUrls) ...[
                      const SizedBox(height: 4),
                      Text(
                        bookmark.url,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(bookmark.category),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: bookmark.isFavorite ? 'Unfavorite' : 'Favorite',
                icon: Icon(
                  bookmark.isFavorite ? Icons.star : Icons.star_border,
                  color: bookmark.isFavorite ? Colors.amber : null,
                ),
                onPressed: () => state.toggleFavorite(bookmark.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add bookmark dialog ──────────────────────────────────────────────────────

class AddBookmarkDialog extends StatefulWidget {
  final AppState state;
  const AddBookmarkDialog({super.key, required this.state});

  @override
  State<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends State<AddBookmarkDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _category = 'Work';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bookmark'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Work', 'Personal', 'Learning']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleCtrl.text.isNotEmpty) {
              widget.state.addBookmark(_titleCtrl.text, _urlCtrl.text, _category);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ─── Detail screen ────────────────────────────────────────────────────────────

class DetailScreen extends StatelessWidget {
  final Bookmark bookmark;
  final AppState state;

  const DetailScreen({super.key, required this.bookmark, required this.state});

  String get _dateStr {
    final d = bookmark.createdAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SelectableText(
              bookmark.url,
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Category: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(label: Text(bookmark.category)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Created: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_dateStr),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) =>
                        EditBookmarkDialog(bookmark: bookmark, state: state),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Bookmark'),
                      content: Text('Delete "${bookmark.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            state.deleteBookmark(bookmark.id);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit bookmark dialog ─────────────────────────────────────────────────────

class EditBookmarkDialog extends StatefulWidget {
  final Bookmark bookmark;
  final AppState state;

  const EditBookmarkDialog({super.key, required this.bookmark, required this.state});

  @override
  State<EditBookmarkDialog> createState() => _EditBookmarkDialogState();
}

class _EditBookmarkDialogState extends State<EditBookmarkDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _urlCtrl;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.bookmark.title);
    _urlCtrl = TextEditingController(text: widget.bookmark.url);
    _category = widget.bookmark.category;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Bookmark'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Work', 'Personal', 'Learning']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.state.updateBookmark(
              widget.bookmark.id,
              _titleCtrl.text,
              _urlCtrl.text,
              _category,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  final AppState state;
  const AppDrawer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: const Text(
              'Bookmark Manager',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bookmarks),
            title: const Text('All Bookmarks'),
            onTap: () {
              state.resetToAll();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Favorites'),
            onTap: () {
              state.setShowFavoritesOnly(true);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(state: state),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Settings screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: state.sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Date', 'Title', 'Category']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => state.setSortBy(v!),
                ),
              ),
              SwitchListTile(
                title: const Text('Show URLs'),
                value: state.showUrls,
                onChanged: state.setShowUrls,
              ),
              SwitchListTile(
                title: const Text('Compact View'),
                value: state.compactView,
                onChanged: state.setCompactView,
              ),
            ],
          ),
        );
      },
    );
  }
}
