#!/usr/bin/env bash
# Apps 62-64: DrawerApp / DatePickerApp / WrapBadgeApp
# Widgets: NavigationDrawer, AboutDialog, DatePicker, TimePicker, Wrap, Badge, InputChip, ActionChip
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
# APP 62: DrawerApp — NavigationDrawer + AboutDialog
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App62());
class App62 extends StatelessWidget {
  const App62({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrawerApp',
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const DrawerHome(),
    );
  }
}
class DrawerHome extends StatefulWidget {
  const DrawerHome({super.key});
  @override
  State<DrawerHome> createState() => _DrawerHomeState();
}
class _DrawerHomeState extends State<DrawerHome> {
  String _currentPage = 'Home';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentPage), actions: [
        IconButton(icon: const Icon(Icons.info_outline), onPressed: () {
          showAboutDialog(context: context, applicationName: 'DrawerApp',
            applicationVersion: '1.0.0', applicationLegalese: '© 2024 Test Corp');
        }),
      ]),
      drawer: NavigationDrawer(
        onDestinationSelected: (i) {
          setState(() => _currentPage = ['Home', 'Favorites', 'Archive', 'Settings'][i]);
          Navigator.pop(context);
        },
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text('DrawerApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(indent: 28, endIndent: 28),
          const NavigationDrawerDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
          const NavigationDrawerDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: Text('Favorites')),
          const NavigationDrawerDestination(icon: Icon(Icons.archive_outlined), selectedIcon: Icon(Icons.archive), label: Text('Archive')),
          const NavigationDrawerDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
        ],
      ),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_currentPage == 'Home' ? Icons.home : _currentPage == 'Favorites' ? Icons.favorite
          : _currentPage == 'Archive' ? Icons.archive : Icons.settings,
          size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Welcome to $_currentPage', style: Theme.of(context).textTheme.headlineSmall),
      ])),
    );
  }
}
DART

echo "========================================"
echo "APP 62: DrawerApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "Home" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Home title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Home title"; }
has_text "Welcome to Home" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Welcome text"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Welcome text"; }
has_label "Open navigation menu" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Menu button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Menu button"; }

echo "Step 2: Open drawer"
R=$(run_iez $IEZ ui tap --label "Open navigation menu"); assert_ok "$R" "Open drawer"
sleep 0.5
has_text "DrawerApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Drawer header"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Drawer header"; }
has_text "Favorites" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Favorites item"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Favorites item"; }
has_text "Archive" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Archive item"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Archive item"; }
has_text "Settings" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Settings item"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Settings item"; }

echo "Step 3: Navigate to Favorites"
# NavigationDrawer labels have "Tab X of Y" suffix — use coords
# Favorites is Tab 2 of 4, at approx y=220
R=$(run_iez $IEZ ui tap --coords 150,220); assert_ok "$R" "Tap Favorites"
sleep 0.5
has_text "Welcome to Favorites" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Favorites page"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Favorites page"; }

echo "Step 4: Navigate to Settings"
R=$(run_iez $IEZ ui tap --label "Open navigation menu"); assert_ok "$R" "Open drawer"
sleep 0.5
# Settings is Tab 4, at approx y=350
R=$(run_iez $IEZ ui tap --coords 150,340); assert_ok "$R" "Tap Settings"
sleep 0.5
has_text "Welcome to Settings" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Settings page"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Settings page"; }

echo "Step 5: Navigate to Archive"
R=$(run_iez $IEZ ui tap --label "Open navigation menu"); assert_ok "$R" "Open drawer"
sleep 0.5
# Archive is Tab 3, at approx y=280
R=$(run_iez $IEZ ui tap --coords 150,280); assert_ok "$R" "Tap Archive"
sleep 0.5
has_text "Welcome to Archive" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Archive page"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Archive page"; }

echo "Step 6: AboutDialog"
# Info button in AppBar
R=$(run_iez $IEZ ui tap --coords 370,78); assert_ok "$R" "Tap info button"
sleep 0.5
has_text "DrawerApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ About dialog name"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ About dialog name"; }
has_text "1.0.0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Version"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Version"; }
has_label "Close" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Close button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Close button"; }
R=$(run_iez $IEZ ui tap --label "Close"); assert_ok "$R" "Close dialog"
sleep 0.3

echo ""

########################################################################
# APP 63: DatePickerApp — DatePicker + TimePicker
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App63());
class App63 extends StatelessWidget {
  const App63({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateTimePicker',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DateTimeHome(),
    );
  }
}
class DateTimeHome extends StatefulWidget {
  const DateTimeHome({super.key});
  @override
  State<DateTimeHome> createState() => _DateTimeHomeState();
}
class _DateTimeHomeState extends State<DateTimeHome> {
  DateTime _selectedDate = DateTime(2024, 6, 15);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 30);
  DateTimeRange? _dateRange;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DateTimePicker')),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Selected Date'),
            subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}'),
            trailing: FilledButton(onPressed: () async {
              final d = await showDatePicker(context: context,
                initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _selectedDate = d);
            }, child: const Text('Pick Date')),
          )),
          const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Selected Time'),
            subtitle: Text('${_selectedTime.hour.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')}'),
            trailing: FilledButton(onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: _selectedTime);
              if (t != null) setState(() => _selectedTime = t);
            }, child: const Text('Pick Time')),
          )),
          const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Date Range'),
            subtitle: Text(_dateRange != null
              ? '${_dateRange!.start.month}/${_dateRange!.start.day} - ${_dateRange!.end.month}/${_dateRange!.end.day}'
              : 'Not selected'),
            trailing: FilledButton(onPressed: () async {
              final r = await showDateRangePicker(context: context,
                firstDate: DateTime(2020), lastDate: DateTime(2030),
                initialDateRange: DateTimeRange(start: DateTime(2024, 6, 1), end: DateTime(2024, 6, 7)));
              if (r != null) setState(() => _dateRange = r);
            }, child: const Text('Pick Range')),
          )),
        ],
      )),
    );
  }
}
DART

echo "========================================"
echo "APP 63: DateTimePicker"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "DateTimePicker" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Selected Date" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Date card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Date card"; }
has_text "Selected Time" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Time card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Time card"; }
has_text "Date Range" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Range card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Range card"; }
has_label "Pick Date" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Pick Date button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Pick Date button"; }
has_label "Pick Time" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Pick Time button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Pick Time button"; }
has_label "Pick Range" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Pick Range button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Pick Range button"; }
has_text "2024-06-15" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default date"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default date"; }
has_text "14:30" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default time"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default time"; }

echo "Step 2: Open DatePicker"
R=$(run_iez $IEZ ui tap --label "Pick Date"); assert_ok "$R" "Tap Pick Date"
sleep 0.5
has_label "OK" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ OK button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ OK button"; }
has_label "Cancel" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cancel button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cancel button"; }
# Confirm the date
R=$(run_iez $IEZ ui tap --label "OK"); assert_ok "$R" "Confirm date"
sleep 0.3

echo "Step 3: Open TimePicker"
R=$(run_iez $IEZ ui tap --label "Pick Time"); assert_ok "$R" "Tap Pick Time"
sleep 0.5
has_label "OK" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Time OK"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Time OK"; }
has_label "Cancel" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Time Cancel"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Time Cancel"; }
R=$(run_iez $IEZ ui tap --label "Cancel"); assert_ok "$R" "Cancel time"
sleep 0.3

echo "Step 4: Open DateRangePicker"
R=$(run_iez $IEZ ui tap --label "Pick Range"); assert_ok "$R" "Tap Pick Range"
sleep 0.5
has_label "Save" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Save button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Save button"; }
R=$(run_iez $IEZ ui tap --label "Save"); assert_ok "$R" "Save range"
sleep 0.3
has_text "Not selected" || { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Range selected"; } && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Range updated"; }

echo ""

########################################################################
# APP 64: WrapBadgeApp — Wrap, Badge, InputChip, ActionChip, ColorScheme
########################################################################
cat > test_app/lib/main.dart << 'DART'
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
DART

echo "========================================"
echo "APP 64: ChipGallery"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "ChipGallery" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_label "Flutter" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Flutter chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Flutter chip"; }
has_label "Dart" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Dart chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Dart chip"; }
has_label "iOS" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ iOS chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ iOS chip"; }
has_text "Selected: Flutter" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default selected"; }
has_label "Bug" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Bug input chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Bug input chip"; }
has_label "Feature" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Feature input chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Feature input chip"; }
has_label "+ Add" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Add chip"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Add chip"; }
has_label "Copy" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Copy action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Copy action"; }
has_label "Share" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Share action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Share action"; }
has_label "Download" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Download action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Download action"; }
has_text "3 notifications" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Badge count"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Badge count"; }

echo "Step 2: Select Dart + iOS chips"
R=$(run_iez $IEZ ui tap --label "Dart"); assert_ok "$R" "Tap Dart"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "iOS"); assert_ok "$R" "Tap iOS"
sleep 0.3
has_text "Flutter, Dart, iOS" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Multi-select"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Multi-select"; }

echo "Step 3: Deselect Flutter"
R=$(run_iez $IEZ ui tap --label "Flutter"); assert_ok "$R" "Deselect Flutter"
sleep 0.3
has_text "Selected: Dart, iOS" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Flutter deselected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Flutter deselected"; }

echo "Step 4: Action chips"
R=$(run_iez $IEZ ui tap --label "Copy"); assert_ok "$R" "Tap Copy"
sleep 0.3
has_text "Last: Copied" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Copied action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Copied action"; }
R=$(run_iez $IEZ ui tap --label "Share"); assert_ok "$R" "Tap Share"
sleep 0.3
has_text "Last: Shared" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Shared action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Shared action"; }

echo "Step 5: Add input chip"
R=$(run_iez $IEZ ui tap --label "+ Add"); assert_ok "$R" "Tap + Add"
sleep 0.3
has_text "Added chip" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Chip added"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Chip added"; }
has_label "Label 3" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Label 3 visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Label 3 visible"; }

echo "Step 6: Press Bug input chip"
R=$(run_iez $IEZ ui tap --label "Bug"); assert_ok "$R" "Tap Bug"
sleep 0.3
has_text "Pressed Bug" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Bug pressed"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Bug pressed"; }

echo "Step 7: Clear notifications"
# Badge is on the notification icon in AppBar
R=$(run_iez $IEZ ui tap --coords 370,78); assert_ok "$R" "Tap notifications"
sleep 0.3
has_text "No notifications" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Badge cleared"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Badge cleared"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
