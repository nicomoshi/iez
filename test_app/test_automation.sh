#!/usr/bin/env bash
# Apps 59-61: StepperTable / WidgetMix / TaskBoard
# Widgets: Stepper, DataTable, RangeSlider, PopupMenu, SegmentedButton, Slider,
#          Switch, Tooltip, Snackbar, SearchBar, FilterChip, BottomSheet,
#          ExpansionTile, Dismissible, Checkbox, FAB
set -euo pipefail
IEZ="./bin/iez"
PASS=0; FAIL=0; TOTAL=0
START=$(date +%s)
BUNDLE_ID="com.example.bottomNavNested"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  TOTAL=$((TOTAL+1))
  if [ "$ok" = "true" ]; then PASS=$((PASS+1)); echo "  ✓ $2"
  else FAIL=$((FAIL+1)); echo "  ✗ $2"; fi
}
has_label() { run_iez $IEZ ui exists --label "$1" | jq -r '.ok' | grep -q true; }
has_text() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[]?.label // empty' | grep -qF "$1"
}
rebuild_and_launch() {
  xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.3
  cd /Users/rudy/Developer/i_ez/test_app && flutter build ios --simulator --no-codesign 2>&1 | tail -1
  xcrun simctl install booted build/ios/iphonesimulator/Runner.app
  xcrun simctl launch booted "$BUNDLE_ID" 2>/dev/null
  cd /Users/rudy/Developer/i_ez
  sleep 1.5
}

########################################################################
# APP 59: StepperTable — Stepper, TextField, RadioListTile, DataTable
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App59());
class App59 extends StatelessWidget {
  const App59({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepperTable',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const StepperTableHome(),
    );
  }
}
class StepperTableHome extends StatefulWidget {
  const StepperTableHome({super.key});
  @override
  State<StepperTableHome> createState() => _StepperTableHomeState();
}
class _StepperTableHomeState extends State<StepperTableHome> {
  int _currentStep = 0;
  String _name = '';
  String _email = '';
  String _plan = 'Basic';
  bool _submitted = false;
  final List<Map<String, String>> _orders = [
    {'item': 'Widget A', 'qty': '2', 'price': '\$10'},
    {'item': 'Widget B', 'qty': '1', 'price': '\$25'},
    {'item': 'Widget C', 'qty': '5', 'price': '\$5'},
  ];
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StepperTable')),
      body: _submitted ? _buildConfirmation() : _buildContent(),
    );
  }
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(children: [
        Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) setState(() => _currentStep++);
            else setState(() => _submitted = true);
          },
          onStepCancel: () { if (_currentStep > 0) setState(() => _currentStep--); },
          onStepTapped: (step) => setState(() => _currentStep = step),
          steps: [
            Step(title: const Text('Personal Info'), content: Column(children: [
              TextField(decoration: const InputDecoration(labelText: 'Name'), onChanged: (v) => _name = v),
              const SizedBox(height: 8),
              TextField(decoration: const InputDecoration(labelText: 'Email'), onChanged: (v) => _email = v),
            ]), isActive: _currentStep >= 0),
            Step(title: const Text('Select Plan'), content: Column(children: [
              RadioListTile<String>(title: const Text('Basic'), value: 'Basic', groupValue: _plan, onChanged: (v) => setState(() => _plan = v!)),
              RadioListTile<String>(title: const Text('Premium'), value: 'Premium', groupValue: _plan, onChanged: (v) => setState(() => _plan = v!)),
              RadioListTile<String>(title: const Text('Enterprise'), value: 'Enterprise', groupValue: _plan, onChanged: (v) => setState(() => _plan = v!)),
            ]), isActive: _currentStep >= 1),
            Step(title: const Text('Review Orders'), content: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex, sortAscending: _sortAscending,
                columns: [
                  DataColumn(label: const Text('Item'), onSort: (i, asc) => setState(() {
                    _sortColumnIndex = i; _sortAscending = asc;
                    _orders.sort((a, b) => asc ? a['item']!.compareTo(b['item']!) : b['item']!.compareTo(a['item']!));
                  })),
                  const DataColumn(label: Text('Qty')),
                  const DataColumn(label: Text('Price')),
                ],
                rows: _orders.map((o) => DataRow(cells: [
                  DataCell(Text(o['item']!)), DataCell(Text(o['qty']!)), DataCell(Text(o['price']!)),
                ])).toList(),
              ),
            ), isActive: _currentStep >= 2),
          ],
        ),
      ]),
    );
  }
  Widget _buildConfirmation() {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle, size: 64, color: Colors.green),
      const SizedBox(height: 16),
      Text('Thank you, $_name!', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Email: $_email'), Text('Plan: $_plan'),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => setState(() { _submitted = false; _currentStep = 0; }), child: const Text('Start Over')),
    ])));
  }
}
DART

echo "========================================"
echo "APP 59: StepperTable"
echo "========================================"
rebuild_and_launch

# Step 1: Verify initial state
echo "Step 1: Initial state"
has_label "StepperTable" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ AppBar title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ AppBar title"; }
has_label "Name" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Name field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Name field"; }
has_label "Email" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Email field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Email field"; }
has_label "Continue" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Continue button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Continue button"; }
has_label "Cancel" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cancel button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cancel button"; }

# Step 2: Fill Personal Info
echo "Step 2: Fill personal info"
R=$(run_iez $IEZ ui type "Alice" --label "Name"); assert_ok "$R" "Type name"
sleep 0.3
R=$(run_iez $IEZ ui type "alice@test.com" --label "Email"); assert_ok "$R" "Type email"
sleep 0.3

# Step 3: Continue to Plan
echo "Step 3: Continue to Plan"
R=$(run_iez $IEZ ui tap --label "Continue"); assert_ok "$R" "Tap Continue"
sleep 0.5
has_label "Basic" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Basic radio"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Basic radio"; }
has_label "Premium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Premium radio"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Premium radio"; }
has_label "Enterprise" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Enterprise radio"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Enterprise radio"; }

# Step 4: Select Premium
echo "Step 4: Select Premium"
R=$(run_iez $IEZ ui tap --label "Premium"); assert_ok "$R" "Tap Premium"
sleep 0.3

# Step 5: Continue to DataTable
echo "Step 5: DataTable"
R=$(run_iez $IEZ ui tap --label "Continue"); assert_ok "$R" "Tap Continue"
sleep 0.5
has_text "Widget A" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Widget A"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Widget A"; }
has_text "Widget B" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Widget B"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Widget B"; }
has_text "Widget C" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Widget C"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Widget C"; }

# Step 6: Sort
echo "Step 6: Sort"
R=$(run_iez $IEZ ui tap --label "Item"); assert_ok "$R" "Sort by Item"
sleep 0.3

# Step 7: Cancel back
echo "Step 7: Cancel back"
R=$(run_iez $IEZ ui tap --label "Cancel"); assert_ok "$R" "Cancel to Plan"
sleep 0.3
has_label "Premium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back at Plan"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back at Plan"; }
R=$(run_iez $IEZ ui tap --label "Cancel"); assert_ok "$R" "Cancel to Info"
sleep 0.3
has_label "Name" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back at Info"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back at Info"; }

# Step 8: Submit
echo "Step 8: Submit"
R=$(run_iez $IEZ ui tap --label "Continue"); assert_ok "$R" "Continue 1"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Continue"); assert_ok "$R" "Continue 2"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Continue"); assert_ok "$R" "Submit"
sleep 0.5
has_text "Alice" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Name shown"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Name shown"; }
has_text "Premium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Plan shown"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Plan shown"; }

# Step 9: Start Over
echo "Step 9: Start Over"
R=$(run_iez $IEZ ui tap --label "Start Over"); assert_ok "$R" "Start Over"
sleep 0.5
has_label "Name" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reset"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reset"; }

echo ""

########################################################################
# APP 60: WidgetMix — RangeSlider, PopupMenu, SegmentedButton, Slider, Switch, Snackbar
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App60());
enum SizeOption { small, medium, large }
class App60 extends StatelessWidget {
  const App60({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WidgetMix',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const WidgetMixHome(),
    );
  }
}
class WidgetMixHome extends StatefulWidget {
  const WidgetMixHome({super.key});
  @override
  State<WidgetMixHome> createState() => _WidgetMixHomeState();
}
class _WidgetMixHomeState extends State<WidgetMixHome> {
  RangeValues _range = const RangeValues(20, 80);
  SizeOption _size = SizeOption.medium;
  String _selectedAction = 'None';
  double _sliderValue = 50;
  bool _switchValue = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WidgetMix'), actions: [
        PopupMenuButton<String>(
          onSelected: (v) => setState(() => _selectedAction = v),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Edit', child: Text('Edit')),
            const PopupMenuItem(value: 'Share', child: Text('Share')),
            const PopupMenuItem(value: 'Delete', child: Text('Delete')),
          ],
        ),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Action: $_selectedAction', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Text('Size', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<SizeOption>(
            segments: const [
              ButtonSegment(value: SizeOption.small, label: Text('Small')),
              ButtonSegment(value: SizeOption.medium, label: Text('Medium')),
              ButtonSegment(value: SizeOption.large, label: Text('Large')),
            ],
            selected: {_size},
            onSelectionChanged: (v) => setState(() => _size = v.first),
          ),
          const SizedBox(height: 8),
          Text('Selected: ${_size.name}'),
          const SizedBox(height: 24),
          Text('Price Range', style: Theme.of(context).textTheme.labelLarge),
          RangeSlider(values: _range, min: 0, max: 100, divisions: 10,
            labels: RangeLabels('\$${_range.start.round()}', '\$${_range.end.round()}'),
            onChanged: (v) => setState(() => _range = v)),
          Text('Range: \$${_range.start.round()} - \$${_range.end.round()}'),
          const SizedBox(height: 24),
          Text('Volume', style: Theme.of(context).textTheme.labelLarge),
          Slider(value: _sliderValue, min: 0, max: 100, divisions: 20,
            label: _sliderValue.round().toString(),
            onChanged: (v) => setState(() => _sliderValue = v)),
          Text('Volume: ${_sliderValue.round()}%'),
          const SizedBox(height: 24),
          SwitchListTile(title: const Text('Dark Mode'),
            subtitle: Text(_switchValue ? 'Enabled' : 'Disabled'),
            value: _switchValue, onChanged: (v) => setState(() => _switchValue = v)),
          const SizedBox(height: 24),
          Center(child: Tooltip(message: 'This applies all settings',
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Applied: ${_size.name}, \$${_range.start.round()}-\$${_range.end.round()}, vol ${_sliderValue.round()}%'),
                  action: SnackBarAction(label: 'Undo', onPressed: () {}),
                ));
              },
              icon: const Icon(Icons.check), label: const Text('Apply'),
            ),
          )),
        ],
      )),
    );
  }
}
DART

echo "========================================"
echo "APP 60: WidgetMix"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "WidgetMix" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ AppBar title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ AppBar title"; }
has_text "Action: None" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Action: None"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Action: None"; }
has_label "Small" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Small segment"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Small segment"; }
has_label "Medium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Medium segment"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Medium segment"; }
has_label "Large" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Large segment"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Large segment"; }
has_text "Selected: medium" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default medium"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default medium"; }
has_text "Range: \$20 - \$80" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default range"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default range"; }
has_text "Volume: 50%" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default volume"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default volume"; }
has_label "Apply" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Apply button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Apply button"; }

echo "Step 2: PopupMenu"
R=$(run_iez $IEZ ui tap --label "Show menu"); assert_ok "$R" "Tap menu"
sleep 0.5
has_label "Edit" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Edit option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Edit option"; }
has_label "Share" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Share option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Share option"; }
has_label "Delete" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Delete option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Delete option"; }
R=$(run_iez $IEZ ui tap --label "Share"); assert_ok "$R" "Select Share"
sleep 0.3
has_text "Action: Share" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Action: Share"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Action: Share"; }

echo "Step 3: SegmentedButton"
R=$(run_iez $IEZ ui tap --label "Large"); assert_ok "$R" "Tap Large"
sleep 0.3
has_text "Selected: large" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Large selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Large selected"; }
R=$(run_iez $IEZ ui tap --label "Small"); assert_ok "$R" "Tap Small"
sleep 0.3
has_text "Selected: small" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Small selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Small selected"; }

echo "Step 4: Switch"
R=$(run_iez $IEZ ui tap --coords 370,590); assert_ok "$R" "Toggle on"
sleep 0.3
has_text "Enabled" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Switch enabled"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Switch enabled"; }

echo "Step 5: Apply + Snackbar"
R=$(run_iez $IEZ ui tap --label "Apply"); assert_ok "$R" "Tap Apply"
sleep 0.5
has_text "Applied:" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Snackbar"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Snackbar"; }
has_label "Undo" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Undo action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Undo action"; }
R=$(run_iez $IEZ ui tap --label "Undo"); assert_ok "$R" "Tap Undo"
sleep 0.3

echo "Step 6: PopupMenu Delete"
R=$(run_iez $IEZ ui tap --label "Show menu"); assert_ok "$R" "Tap menu"
sleep 0.5
R=$(run_iez $IEZ ui tap --label "Delete"); assert_ok "$R" "Select Delete"
sleep 0.3
has_text "Action: Delete" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Action: Delete"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Action: Delete"; }

echo "Step 7: Toggle off"
R=$(run_iez $IEZ ui tap --coords 370,590); assert_ok "$R" "Toggle off"
sleep 0.3
has_text "Disabled" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Switch disabled"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Switch disabled"; }

echo ""

########################################################################
# APP 61: TaskBoard — Search, FilterChip, BottomSheet, ExpansionTile, Dismissible
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App61());
class App61 extends StatelessWidget {
  const App61({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskBoard',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const TaskBoardHome(),
    );
  }
}
class TaskBoardHome extends StatefulWidget {
  const TaskBoardHome({super.key});
  @override
  State<TaskBoardHome> createState() => _TaskBoardHomeState();
}
class _TaskBoardHomeState extends State<TaskBoardHome> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Buy groceries', 'category': 'Personal', 'done': false},
    {'title': 'Fix login bug', 'category': 'Work', 'done': false},
    {'title': 'Write tests', 'category': 'Work', 'done': true},
    {'title': 'Call dentist', 'category': 'Personal', 'done': false},
    {'title': 'Deploy v2', 'category': 'Work', 'done': false},
  ];
  final Set<String> _selectedFilters = {};
  String _searchQuery = '';
  List<Map<String, dynamic>> get _filteredTasks {
    return _tasks.where((t) {
      final matchesFilter = _selectedFilters.isEmpty || _selectedFilters.contains(t['category']);
      final matchesSearch = _searchQuery.isEmpty || (t['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }
  void _addTask(String title, String category) {
    setState(() => _tasks.add({'title': title, 'category': category, 'done': false}));
  }
  void _showAddSheet() {
    String newTitle = '';
    String newCategory = 'Personal';
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(builder: (ctx, setSheetState) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Task', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(labelText: 'Task Title'), onChanged: (v) => newTitle = v),
          const SizedBox(height: 12),
          Row(children: [
            ChoiceChip(label: const Text('Personal'), selected: newCategory == 'Personal',
              onSelected: (_) => setSheetState(() => newCategory = 'Personal')),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Work'), selected: newCategory == 'Work',
              onSelected: (_) => setSheetState(() => newCategory = 'Work')),
          ]),
          const SizedBox(height: 16),
          FilledButton(onPressed: () { if (newTitle.isNotEmpty) { _addTask(newTitle, newCategory); Navigator.pop(ctx); } },
            child: const Text('Add')),
          const SizedBox(height: 16),
        ])),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final workCount = _tasks.where((t) => t['category'] == 'Work').length;
    final personalCount = _tasks.where((t) => t['category'] == 'Personal').length;
    return Scaffold(
      appBar: AppBar(title: const Text('TaskBoard')),
      floatingActionButton: FloatingActionButton(onPressed: _showAddSheet, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(labelText: 'Search', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          FilterChip(label: Text('Work ($workCount)'), selected: _selectedFilters.contains('Work'),
            onSelected: (v) => setState(() { v ? _selectedFilters.add('Work') : _selectedFilters.remove('Work'); })),
          const SizedBox(width: 8),
          FilterChip(label: Text('Personal ($personalCount)'), selected: _selectedFilters.contains('Personal'),
            onSelected: (v) => setState(() { v ? _selectedFilters.add('Personal') : _selectedFilters.remove('Personal'); })),
        ])),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('${filtered.length} tasks', style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (ctx, i) {
          final task = filtered[i];
          return Dismissible(
            key: ValueKey(task['title']),
            background: Container(color: Colors.red, alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              setState(() => _tasks.remove(task));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${task['title']}"')));
            },
            child: ExpansionTile(
              leading: Checkbox(value: task['done'] as bool, onChanged: (v) => setState(() => task['done'] = v)),
              title: Text(task['title'] as String,
                style: TextStyle(decoration: (task['done'] as bool) ? TextDecoration.lineThrough : null)),
              subtitle: Text(task['category'] as String),
              children: [Padding(padding: const EdgeInsets.all(16),
                child: Text('Category: ${task['category']}\nStatus: ${task['done'] ? "Done" : "Pending"}'))],
            ),
          );
        })),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 61: TaskBoard"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "TaskBoard" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ AppBar title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ AppBar title"; }
has_label "Search" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Search field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Search field"; }
has_label "Work (3)" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Work chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Work chip"; }
has_label "Personal (2)" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Personal chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Personal chip"; }
has_text "5 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 5 tasks"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 5 tasks"; }
has_text "Buy groceries" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Buy groceries"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Buy groceries"; }

echo "Step 2: Filter Work"
R=$(run_iez $IEZ ui tap --label "Work (3)"); assert_ok "$R" "Tap Work"
sleep 0.5
has_text "3 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 3 tasks"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 3 tasks"; }
has_text "Fix login bug" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Fix login bug"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Fix login bug"; }
has_text "Deploy v2" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Deploy v2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Deploy v2"; }

echo "Step 3: Deselect"
R=$(run_iez $IEZ ui tap --label "Work (3)"); assert_ok "$R" "Deselect Work"
sleep 0.3
has_text "5 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back to 5"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back to 5"; }

echo "Step 4: Search"
R=$(run_iez $IEZ ui type "bug" --label "Search"); assert_ok "$R" "Search bug"
sleep 0.5
has_text "1 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 1 task found"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 1 task found"; }

echo "Step 5: Reset"
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null; sleep 0.3
xcrun simctl launch booted "$BUNDLE_ID" 2>/dev/null; sleep 1.5
has_text "5 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reset to 5"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reset to 5"; }

echo "Step 6: ExpansionTile"
R=$(run_iez $IEZ ui tap --coords 370,285); assert_ok "$R" "Expand"
sleep 0.5
has_text "Category: Personal" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Expanded"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Expanded"; }
R=$(run_iez $IEZ ui tap --coords 370,285); assert_ok "$R" "Collapse"
sleep 0.3

echo "Step 7: Dismiss"
R=$(run_iez $IEZ ui swipe --from 350,510 --to 50,510); assert_ok "$R" "Swipe dismiss"
sleep 0.5
has_text "4 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 4 tasks"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 4 tasks"; }
has_text "Deleted" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Snackbar"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Snackbar"; }
sleep 4

echo "Step 8: BottomSheet"
R=$(run_iez $IEZ ui tap --coords 358,808); assert_ok "$R" "Tap FAB"
sleep 1.0
has_text "Add Task" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Sheet title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Sheet title"; }
has_label "Task Title" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title field"; }
R=$(run_iez $IEZ ui type "New task" --label "Task Title"); assert_ok "$R" "Type title"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Work"); assert_ok "$R" "Select Work"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Add"); assert_ok "$R" "Tap Add"
sleep 0.5
has_text "New task" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Task added"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Task added"; }
has_text "5 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 5 tasks again"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 5 tasks again"; }

echo "Step 9: Filter Personal"
R=$(run_iez $IEZ ui tap --label "Personal (1)"); assert_ok "$R" "Tap Personal"
sleep 0.3
has_text "1 tasks" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 1 personal"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 1 personal"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
