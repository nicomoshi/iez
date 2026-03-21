import 'package:flutter/material.dart';
void main() => runApp(const App64());
class App64 extends StatelessWidget {
  const App64({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChipGallery',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const ChipGalleryHome(),
    );
  }
}
class ChipGalleryHome extends StatefulWidget {
  const ChipGalleryHome({super.key});
  @override
  State<ChipGalleryHome> createState() => _ChipGalleryHomeState();
}
class _ChipGalleryHomeState extends State<ChipGalleryHome> {
  final Set<String> _selectedTags = {'Flutter'};
  final List<String> _allTags = ['Flutter', 'Dart', 'iOS', 'Android', 'Web', 'Desktop', 'Firebase', 'Riverpod'];
  final List<String> _inputChips = ['Bug', 'Feature'];
  String _lastAction = 'None';
  int _notificationCount = 3;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChipGallery'), actions: [
        Badge(label: Text('$_notificationCount'), child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => setState(() => _notificationCount = 0),
        )),
        const SizedBox(width: 8),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Chips', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: _allTags.map((tag) =>
            FilterChip(
              label: Text(tag),
              selected: _selectedTags.contains(tag),
              onSelected: (v) => setState(() { v ? _selectedTags.add(tag) : _selectedTags.remove(tag); }),
            ),
          ).toList()),
          const SizedBox(height: 8),
          Text('Selected: ${_selectedTags.join(", ")}'),
          const SizedBox(height: 24),
          Text('Input Chips', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            ..._inputChips.map((c) => InputChip(
              label: Text(c),
              onDeleted: () => setState(() => _inputChips.remove(c)),
              onPressed: () => setState(() => _lastAction = 'Pressed $c'),
            )),
            ActionChip(label: const Text('+ Add'), onPressed: () {
              setState(() { _inputChips.add('Label ${_inputChips.length + 1}'); _lastAction = 'Added chip'; });
            }),
          ]),
          const SizedBox(height: 8),
          Text('Last: $_lastAction'),
          const SizedBox(height: 24),
          Text('Action Chips', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(avatar: const Icon(Icons.copy, size: 18), label: const Text('Copy'),
              onPressed: () => setState(() => _lastAction = 'Copied')),
            ActionChip(avatar: const Icon(Icons.share, size: 18), label: const Text('Share'),
              onPressed: () => setState(() => _lastAction = 'Shared')),
            ActionChip(avatar: const Icon(Icons.download, size: 18), label: const Text('Download'),
              onPressed: () => setState(() => _lastAction = 'Downloaded')),
          ]),
          const SizedBox(height: 24),
          Text('Badge: ${_notificationCount > 0 ? "$_notificationCount notifications" : "No notifications"}'),
        ],
      )),
    );
  }
}
