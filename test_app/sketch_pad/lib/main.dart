import 'package:flutter/material.dart';

void main() {
  runApp(const SketchPadApp());
}

class SketchPadApp extends StatelessWidget {
  const SketchPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SketchPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class SketchData {
  final String title;
  final String date;
  final List<String> tags;
  final List<Color> colors;
  final IconData icon;

  const SketchData({
    required this.title,
    required this.date,
    required this.tags,
    required this.colors,
    required this.icon,
  });
}

final List<SketchData> seedSketches = [
  SketchData(
    title: 'Sunset',
    date: 'March 20',
    tags: ['Nature', 'Landscape'],
    colors: [Colors.orange, Colors.red, Colors.purple],
    icon: Icons.wb_sunny,
  ),
  SketchData(
    title: 'Mountain',
    date: 'March 18',
    tags: ['Nature', 'Landscape'],
    colors: [Colors.green, Colors.brown, Colors.blue],
    icon: Icons.landscape,
  ),
  SketchData(
    title: 'Cat Portrait',
    date: 'March 15',
    tags: ['Animals', 'Portrait'],
    colors: [Colors.orange, Colors.black, Colors.white],
    icon: Icons.pets,
  ),
  SketchData(
    title: 'City Skyline',
    date: 'March 12',
    tags: ['Urban', 'Architecture'],
    colors: [Colors.grey, Colors.blue, Colors.amber],
    icon: Icons.location_city,
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<SketchData> sketches = List.from(seedSketches);

  void _deleteSketch(SketchData sketch) {
    setState(() {
      sketches.remove(sketch);
    });
  }

  void _addSketch(SketchData sketch) {
    setState(() {
      sketches.insert(0, sketch);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _SketchesTab(
        sketches: sketches,
        onDelete: _deleteSketch,
        onAdd: _addSketch,
      ),
      _GalleryTab(sketches: sketches),
      const _ToolsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchPad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(sketches: sketches),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.draw),
            label: 'Sketches',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}

// --- Sketches Tab ---

class _SketchesTab extends StatelessWidget {
  final List<SketchData> sketches;
  final void Function(SketchData) onDelete;
  final void Function(SketchData) onAdd;

  const _SketchesTab({
    required this.sketches,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: sketches.length,
        itemBuilder: (context, index) {
          final sketch = sketches[index];
          return ListTile(
            leading: Icon(sketch.icon, color: Theme.of(context).colorScheme.primary),
            title: Text(sketch.title),
            subtitle: Text(sketch.date),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SketchDetailPage(
                    sketch: sketch,
                    onDelete: () {
                      onDelete(sketch);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<SketchData>(
            context,
            MaterialPageRoute(builder: (_) => const NewSketchPage()),
          );
          if (result != null) {
            onAdd(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Sketch'),
      ),
    );
  }
}

// --- Sketch Detail Page ---

class SketchDetailPage extends StatelessWidget {
  final SketchData sketch;
  final VoidCallback onDelete;

  const SketchDetailPage({
    super.key,
    required this.sketch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sketch Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                sketch.icon,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            sketch.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Created',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(sketch.date, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sketch.tags
                .map((tag) => Chip(label: Text(tag)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Colors Used',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: sketch.colors
                .map(
                  (color) => Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Sketch'),
          ),
        ],
      ),
    );
  }
}

// --- Gallery Tab ---

class _GalleryTab extends StatelessWidget {
  final List<SketchData> sketches;

  const _GalleryTab({required this.sketches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gallery',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sketches.length,
              itemBuilder: (context, index) {
                final sketch = sketches[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              sketch.icon,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          sketch.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tools Tab ---

class _ToolsTab extends StatefulWidget {
  const _ToolsTab();

  @override
  State<_ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<_ToolsTab> {
  double _brushSize = 5.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tools',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Pencil'),
          subtitle: const Text('Fine lines and details'),
        ),
        ListTile(
          leading: const Icon(Icons.brush),
          title: const Text('Brush'),
          subtitle: const Text('Smooth strokes'),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('Eraser'),
          subtitle: const Text('Remove strokes'),
        ),
        ListTile(
          leading: const Icon(Icons.format_color_fill),
          title: const Text('Fill'),
          subtitle: const Text('Fill closed areas'),
        ),
        const SizedBox(height: 24),
        Text(
          'Brush Size',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _brushSize,
          min: 1,
          max: 20,
          divisions: 19,
          label: _brushSize.round().toString(),
          onChanged: (value) {
            setState(() => _brushSize = value);
          },
        ),
      ],
    );
  }
}

// --- New Sketch Page ---

class NewSketchPage extends StatefulWidget {
  const NewSketchPage({super.key});

  @override
  State<NewSketchPage> createState() => _NewSketchPageState();
}

class _NewSketchPageState extends State<NewSketchPage> {
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  String _canvasSize = 'Medium';

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sketch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Sketch Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              border: OutlineInputBorder(),
              hintText: 'Comma-separated tags',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _canvasSize,
            decoration: const InputDecoration(
              labelText: 'Canvas Size',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Small', child: Text('Small')),
              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
              DropdownMenuItem(value: 'Large', child: Text('Large')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _canvasSize = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              final tags = _tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              final sketch = SketchData(
                title: name,
                date: 'March 22',
                tags: tags,
                colors: [Colors.black],
                icon: Icons.draw,
              );
              Navigator.pop(context, sketch);
            },
            child: const Text('Start Drawing'),
          ),
        ],
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final List<SketchData> sketches;

  const SearchPage({super.key, required this.sketches});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<SketchData> _results = [];

  final List<String> _filters = ['All', 'Nature', 'Urban', 'Animals'];

  @override
  void initState() {
    super.initState();
    _results = widget.sketches;
  }

  void _search() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _results = widget.sketches.where((s) {
        final matchesQuery =
            query.isEmpty || s.title.toLowerCase().contains(query);
        final matchesFilter = _selectedFilter == 'All' ||
            s.tags.any((t) => t.toLowerCase() == _selectedFilter.toLowerCase());
        return matchesQuery && matchesFilter;
      }).toList();
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
      appBar: AppBar(title: const Text('Search Sketches')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Sketches',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _search(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _filters.map((filter) {
                return FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = filter);
                    _search();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final sketch = _results[index];
                  return ListTile(
                    leading: Icon(sketch.icon),
                    title: Text(sketch.title),
                    subtitle: Text(sketch.date),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
