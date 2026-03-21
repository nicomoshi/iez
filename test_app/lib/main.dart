import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Widgets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          CounterAnimScreen(),
          TooltipBadgeScreen(),
          ListSeparatedScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.touch_app), label: 'Counter'),
          NavigationDestination(icon: Icon(Icons.info), label: 'Badges'),
          NavigationDestination(icon: Icon(Icons.list), label: 'List'),
        ],
      ),
    );
  }
}

// Screen 1: AnimatedSwitcher + AnimatedScale + AnimatedOpacity + AnimatedRotation
class CounterAnimScreen extends StatefulWidget {
  const CounterAnimScreen({super.key});

  @override
  State<CounterAnimScreen> createState() => _CounterAnimScreenState();
}

class _CounterAnimScreenState extends State<CounterAnimScreen> {
  int _count = 0;
  bool _visible = true;
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Animations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 300),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '$_count',
                    key: ValueKey<int>(_count),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _count--),
                  icon: const Icon(Icons.remove),
                  label: const Text('Decrease'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => setState(() => _count++),
                  icon: const Icon(Icons.add),
                  label: const Text('Increase'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _visible = !_visible),
                  child: Text(_visible ? 'Fade Out' : 'Fade In'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _scale = _scale == 1.0 ? 2.0 : 1.0),
                  child: Text(_scale == 1.0 ? 'Scale Up' : 'Scale Down'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Count: $_count'),
            Text('Visible: $_visible'),
            Text('Scale: ${_scale.toStringAsFixed(1)}x'),
          ],
        ),
      ),
    );
  }
}

// Screen 2: Tooltip, Badge, CircleAvatar, Chip, ListWheelScrollView
class TooltipBadgeScreen extends StatefulWidget {
  const TooltipBadgeScreen({super.key});

  @override
  State<TooltipBadgeScreen> createState() => _TooltipBadgeScreenState();
}

class _TooltipBadgeScreenState extends State<TooltipBadgeScreen> {
  int _notifCount = 3;
  int _selectedColor = 0;

  final _colors = ['Red', 'Blue', 'Green', 'Yellow', 'Purple'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Tooltips'),
        actions: [
          Badge(
            label: Text('$_notifCount'),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: () {
                setState(() => _notifCount = 0);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tooltips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Tooltip(
                  message: 'Home tooltip',
                  child: IconButton(
                    icon: const Icon(Icons.home, size: 36),
                    onPressed: () {},
                    tooltip: 'Home',
                  ),
                ),
                Tooltip(
                  message: 'Settings tooltip',
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 36),
                    onPressed: () {},
                    tooltip: 'Settings',
                  ),
                ),
                Tooltip(
                  message: 'Profile tooltip',
                  child: IconButton(
                    icon: const Icon(Icons.person, size: 36),
                    onPressed: () {},
                    tooltip: 'Profile',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Badges', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Notification count: $_notifCount'),
            const SizedBox(height: 16),
            Text('Circle Avatars', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                CircleAvatar(radius: 30, child: Text('AB')),
                CircleAvatar(radius: 30, backgroundColor: Colors.teal, child: Text('CD')),
                CircleAvatar(radius: 30, backgroundColor: Colors.purple, child: Text('EF')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Color Picker (Wheel)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Selected: ${_colors[_selectedColor]}'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListWheelScrollView(
                itemExtent: 40,
                onSelectedItemChanged: (i) => setState(() => _selectedColor = i),
                children: _colors.map((c) => Center(
                  child: Text(c, style: Theme.of(context).textTheme.titleMedium),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 3: ListView.separated + Dismissible + SnackBar
class ListSeparatedScreen extends StatefulWidget {
  const ListSeparatedScreen({super.key});

  @override
  State<ListSeparatedScreen> createState() => _ListSeparatedScreenState();
}

class _ListSeparatedScreenState extends State<ListSeparatedScreen> {
  final List<String> _items = List.generate(10, (i) => 'Item ${i + 1}');
  String _lastDismissed = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe to Dismiss'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _items.clear();
                _items.addAll(List.generate(10, (i) => 'Item ${i + 1}'));
                _lastDismissed = 'None';
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items: ${_items.length}'),
                Text('Last dismissed: $_lastDismissed'),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('All items dismissed!'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: ValueKey(item),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.archive, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _items.removeAt(index);
                            _lastDismissed = item;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$item dismissed'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(item),
                          subtitle: const Text('Swipe left or right'),
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
