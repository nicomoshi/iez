import 'package:flutter/material.dart';

void main() {
  runApp(const Material3ShowcaseApp());
}

class Material3ShowcaseApp extends StatefulWidget {
  const Material3ShowcaseApp({super.key});

  @override
  State<Material3ShowcaseApp> createState() => _Material3ShowcaseAppState();
}

class _Material3ShowcaseAppState extends State<Material3ShowcaseApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M3 Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ShowcaseHome(
        darkMode: _darkMode,
        onDarkModeChanged: (v) => setState(() => _darkMode = v),
      ),
    );
  }
}

class ShowcaseHome extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const ShowcaseHome({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3 Showcase'),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () => widget.onDarkModeChanged(!widget.darkMode),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buttons'),
            Tab(text: 'Inputs'),
            Tab(text: 'Selection'),
            Tab(text: 'Indicators'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ButtonsTab(),
          InputsTab(),
          SelectionTab(),
          IndicatorsTab(),
        ],
      ),
    );
  }
}

class ButtonsTab extends StatelessWidget {
  const ButtonsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Elevated Buttons',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('With Icon'),
            ),
            const ElevatedButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Filled Buttons',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () {},
              child: const Text('Filled'),
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Tonal'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Outlined & Text',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text'),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.info),
              label: const Text('Info'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Icon Buttons',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite),
              tooltip: 'Favorite',
            ),
            IconButton.filled(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.share),
              tooltip: 'Share',
            ),
            IconButton.outlined(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('FABs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            FloatingActionButton.small(
              heroTag: 'small',
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            FloatingActionButton(
              heroTag: 'regular',
              onPressed: () {},
              child: const Icon(Icons.navigation),
            ),
            FloatingActionButton.extended(
              heroTag: 'extended',
              onPressed: () {},
              icon: const Icon(Icons.map),
              label: const Text('Navigate'),
            ),
          ],
        ),
      ],
    );
  }
}

class InputsTab extends StatefulWidget {
  const InputsTab({super.key});

  @override
  State<InputsTab> createState() => _InputsTabState();
}

class _InputsTabState extends State<InputsTab> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  double _sliderValue = 0.5;
  RangeValues _rangeValues = const RangeValues(20, 80);

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Text Fields',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Standard Input',
            border: OutlineInputBorder(),
            helperText: 'Enter some text',
          ),
        ),
        const SizedBox(height: 16),
        SearchBar(
          controller: _searchController,
          hintText: 'Search items...',
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _searchController.clear(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Slider',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          value: _sliderValue,
          onChanged: (v) => setState(() => _sliderValue = v),
          divisions: 10,
          label: '${(_sliderValue * 100).round()}%',
        ),
        Text('Value: ${(_sliderValue * 100).round()}%',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text('Range Slider',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        RangeSlider(
          values: _rangeValues,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            _rangeValues.start.round().toString(),
            _rangeValues.end.round().toString(),
          ),
          onChanged: (v) => setState(() => _rangeValues = v),
        ),
        Text(
          'Range: ${_rangeValues.start.round()} - ${_rangeValues.end.round()}',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class SelectionTab extends StatefulWidget {
  const SelectionTab({super.key});

  @override
  State<SelectionTab> createState() => _SelectionTabState();
}

enum CalendarView { day, week, month, year }

class _SelectionTabState extends State<SelectionTab> {
  CalendarView _calendarView = CalendarView.week;
  bool _switch1 = true;
  bool _switch2 = false;
  bool _check1 = true;
  bool _check2 = false;
  bool _check3 = true;
  final Set<String> _selectedFilters = {'Recent'};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Segmented Button',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<CalendarView>(
          segments: const [
            ButtonSegment(value: CalendarView.day, label: Text('Day')),
            ButtonSegment(value: CalendarView.week, label: Text('Week')),
            ButtonSegment(value: CalendarView.month, label: Text('Month')),
            ButtonSegment(value: CalendarView.year, label: Text('Year')),
          ],
          selected: {_calendarView},
          onSelectionChanged: (v) =>
              setState(() => _calendarView = v.first),
        ),
        const SizedBox(height: 24),
        const Text('Filter Chips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Recent', 'Popular', 'Trending', 'New'].map((filter) {
            return FilterChip(
              label: Text(filter),
              selected: _selectedFilters.contains(filter),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedFilters.add(filter);
                  } else {
                    _selectedFilters.remove(filter);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Switches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Wi-Fi'),
          subtitle: const Text('Connect to wireless network'),
          value: _switch1,
          onChanged: (v) => setState(() => _switch1 = v),
        ),
        SwitchListTile(
          title: const Text('Bluetooth'),
          subtitle: const Text('Enable Bluetooth'),
          value: _switch2,
          onChanged: (v) => setState(() => _switch2 = v),
        ),
        const SizedBox(height: 24),
        const Text('Checkboxes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Option A'),
          subtitle: const Text('First option'),
          value: _check1,
          onChanged: (v) => setState(() => _check1 = v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Option B'),
          subtitle: const Text('Second option'),
          value: _check2,
          onChanged: (v) => setState(() => _check2 = v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Option C'),
          subtitle: const Text('Third option'),
          value: _check3,
          onChanged: (v) => setState(() => _check3 = v ?? false),
        ),
      ],
    );
  }
}

class IndicatorsTab extends StatefulWidget {
  const IndicatorsTab({super.key});

  @override
  State<IndicatorsTab> createState() => _IndicatorsTabState();
}

class _IndicatorsTabState extends State<IndicatorsTab> {
  double _progressValue = 0.6;
  bool _showBadge = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Linear Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _progressValue),
        const SizedBox(height: 8),
        Slider(
          value: _progressValue,
          onChanged: (v) => setState(() => _progressValue = v),
        ),
        Text('${(_progressValue * 100).round()}% complete',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text('Circular Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                CircularProgressIndicator(value: _progressValue),
                const SizedBox(height: 8),
                const Text('Determinate'),
              ],
            ),
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Indeterminate'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Badges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Show Badge'),
          value: _showBadge,
          onChanged: (v) => setState(() => _showBadge = v),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Badge(
              isLabelVisible: _showBadge,
              label: const Text('3'),
              child: const Icon(Icons.mail, size: 32),
            ),
            Badge(
              isLabelVisible: _showBadge,
              label: const Text('99+'),
              child: const Icon(Icons.notifications, size: 32),
            ),
            Badge(
              isLabelVisible: _showBadge,
              child: const Icon(Icons.shopping_cart, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Snackbar & Dialog',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('This is a snackbar'),
                    action: SnackBarAction(
                      label: 'Dismiss',
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: const Text('Show Snackbar'),
            ),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Alert'),
                    content: const Text('This is a Material 3 dialog.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ],
        ),
      ],
    );
  }
}
