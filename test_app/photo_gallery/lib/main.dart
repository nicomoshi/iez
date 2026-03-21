import 'package:flutter/material.dart';

void main() {
  runApp(const PhotoGalleryApp());
}

class PhotoGalleryApp extends StatelessWidget {
  const PhotoGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const MainShell(),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class Photo {
  final int id;
  final String name;
  final String category;
  final Color color;

  const Photo({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
  });
}

const List<Photo> kPhotos = [
  Photo(id: 1,  name: 'Photo 1',  category: 'Nature', color: Color(0xFF4CAF50)),
  Photo(id: 2,  name: 'Photo 2',  category: 'Urban',  color: Color(0xFF2196F3)),
  Photo(id: 3,  name: 'Photo 3',  category: 'People', color: Color(0xFFE91E63)),
  Photo(id: 4,  name: 'Photo 4',  category: 'Nature', color: Color(0xFF8BC34A)),
  Photo(id: 5,  name: 'Photo 5',  category: 'Urban',  color: Color(0xFF9C27B0)),
  Photo(id: 6,  name: 'Photo 6',  category: 'People', color: Color(0xFFFF5722)),
  Photo(id: 7,  name: 'Photo 7',  category: 'Nature', color: Color(0xFF00BCD4)),
  Photo(id: 8,  name: 'Photo 8',  category: 'Urban',  color: Color(0xFFFF9800)),
  Photo(id: 9,  name: 'Photo 9',  category: 'People', color: Color(0xFF607D8B)),
  Photo(id: 10, name: 'Photo 10', category: 'Nature', color: Color(0xFF795548)),
  Photo(id: 11, name: 'Photo 11', category: 'Urban',  color: Color(0xFF3F51B5)),
  Photo(id: 12, name: 'Photo 12', category: 'Nature', color: Color(0xFF009688)),
];

// ─── Main Shell ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    PhotosTab(),
    AlbumsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library), label: 'Photos'),
          NavigationDestination(icon: Icon(Icons.photo_album),   label: 'Albums'),
        ],
      ),
    );
  }
}

// ─── Photos Tab ───────────────────────────────────────────────────────────────

class PhotosTab extends StatefulWidget {
  const PhotosTab({super.key});

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> {
  String _selectedFilter = 'All';

  static const List<String> _filters = ['All', 'Nature', 'Urban', 'People'];

  List<Photo> get _filtered => _selectedFilter == 'All'
      ? kPhotos
      : kPhotos.where((p) => p.category == _selectedFilter).toList();

  void _showAddPhotoDialog() {
    final titleController = TextEditingController();
    String selectedCategory = 'Nature';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Photo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Nature', 'Urban', 'People']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCategory = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Photo',
        onPressed: _showAddPhotoDialog,
        child: const Icon(Icons.camera_alt),
      ),
      body: Column(
        children: [
          // Filter chips row
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          // Photo grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final photo = _filtered[index];
                return PhotoGridTile(photo: photo);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo Grid Tile ──────────────────────────────────────────────────────────

class PhotoGridTile extends StatelessWidget {
  final Photo photo;
  const PhotoGridTile({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoDetailScreen(photo: photo),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: photo.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            photo.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─── Photo Detail Screen ──────────────────────────────────────────────────────

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  const PhotoDetailScreen({super.key, required this.photo});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  bool _liked = false;

  void _showOverflowMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Details'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photo.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: _showOverflowMenu,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: widget.photo.color,
        child: Center(
          child: Text(
            widget.photo.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.red : null,
              ),
              tooltip: 'Like',
              onPressed: () => setState(() => _liked = !_liked),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sharing ${widget.photo.name}...')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Photo'),
                    content: Text('Delete ${widget.photo.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Albums Tab ───────────────────────────────────────────────────────────────

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  static const List<Map<String, dynamic>> _albums = [
    {'name': 'Nature', 'count': 5, 'color': Color(0xFF4CAF50)},
    {'name': 'Urban',  'count': 4, 'color': Color(0xFF2196F3)},
    {'name': 'People', 'count': 3, 'color': Color(0xFFE91E63)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _albums.map((album) {
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: album['color'] as Color,
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album['name'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${album['count']} photos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
