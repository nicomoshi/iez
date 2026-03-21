#!/usr/bin/env bash
# Apps 65-67: GridDashboard / TabFormValidator / DragDropList
# Widgets: GridView, Card, LinearProgressIndicator, CircularProgressIndicator,
#          TabBar, Form, TextFormField validation, DropdownButton,
#          LongPressDraggable, DragTarget, ReorderableListView
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
# APP 65: GridDashboard — GridView, Card, ProgressIndicators
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App65());
class App65 extends StatelessWidget {
  const App65({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridDashboard',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const GridDashboardHome(),
    );
  }
}
class GridDashboardHome extends StatefulWidget {
  const GridDashboardHome({super.key});
  @override
  State<GridDashboardHome> createState() => _GridDashboardHomeState();
}
class _GridDashboardHomeState extends State<GridDashboardHome> {
  final List<Map<String, dynamic>> _stats = [
    {'title': 'Users', 'value': 1234, 'progress': 0.75, 'icon': Icons.people},
    {'title': 'Sales', 'value': 567, 'progress': 0.45, 'icon': Icons.shopping_cart},
    {'title': 'Revenue', 'value': 8901, 'progress': 0.9, 'icon': Icons.attach_money},
    {'title': 'Orders', 'value': 342, 'progress': 0.6, 'icon': Icons.receipt},
    {'title': 'Returns', 'value': 23, 'progress': 0.15, 'icon': Icons.undo},
    {'title': 'Reviews', 'value': 456, 'progress': 0.8, 'icon': Icons.star},
  ];
  String? _selectedCard;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GridDashboard')),
      body: Column(children: [
        if (_selectedCard != null) Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('Selected: $_selectedCard', textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
        ),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3),
          itemCount: _stats.length,
          itemBuilder: (ctx, i) {
            final s = _stats[i];
            return Card(
              child: InkWell(
                onTap: () => setState(() => _selectedCard = s['title']),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(s['icon'] as IconData, size: 20),
                      const SizedBox(width: 8),
                      Text(s['title'] as String, style: Theme.of(ctx).textTheme.labelLarge),
                    ]),
                    const Spacer(),
                    Text('${s['value']}', style: Theme.of(ctx).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: s['progress'] as double),
                    const SizedBox(height: 4),
                    Text('${((s['progress'] as double) * 100).round()}%',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                )),
              ),
            );
          },
        )),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 65: GridDashboard"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "GridDashboard" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Users" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Users card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Users card"; }
has_text "Sales" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Sales card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Sales card"; }
has_text "Revenue" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Revenue card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Revenue card"; }
has_text "Orders" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Orders card"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Orders card"; }
has_text "1234" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Users value"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Users value"; }
has_text "75%" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Users progress"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Users progress"; }

echo "Step 2: Tap Users card"
R=$(run_iez $IEZ ui tap --coords 103,170); assert_ok "$R" "Tap Users"
sleep 0.3
has_text "Selected: Users" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Users selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Users selected"; }

echo "Step 3: Tap Revenue card"
R=$(run_iez $IEZ ui tap --coords 103,345); assert_ok "$R" "Tap Revenue"
sleep 0.3
has_text "Selected: Revenue" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Revenue selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Revenue selected"; }

echo "Step 4: Scroll down to see more"
R=$(run_iez $IEZ ui swipe up); assert_ok "$R" "Scroll down"
sleep 0.3
has_text "Reviews" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reviews visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reviews visible"; }

echo ""

########################################################################
# APP 66: TabFormValidator — TabBar, Form with validation, DropdownButton
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App66());
class App66 extends StatelessWidget {
  const App66({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TabForm',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const TabFormHome(),
    );
  }
}
class TabFormHome extends StatefulWidget {
  const TabFormHome({super.key});
  @override
  State<TabFormHome> createState() => _TabFormHomeState();
}
class _TabFormHomeState extends State<TabFormHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _role = 'Developer';
  bool _submitted = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TabForm'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Settings'),
          Tab(text: 'About'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        // Tab 1: Form
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_submitted) Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('Saved: $_name ($_email) as $_role', style: const TextStyle(color: Colors.green)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
              onSaved: (v) => _email = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: ['Developer', 'Designer', 'Manager', 'QA'].map((r) =>
                DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => _role = v!,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                setState(() => _submitted = true);
              }
            }, child: const Text('Save')),
          ]),
        )),
        // Tab 2: Settings
        const Center(child: Text('Settings Page')),
        // Tab 3: About
        const Center(child: Text('About Page')),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 66: TabForm"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "TabForm" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
# Tab labels have "\nTab X of Y" suffix — use has_text (substring match)
has_text "Profile" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Profile tab"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Profile tab"; }
has_text "Settings" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Settings tab"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Settings tab"; }
has_text "About" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ About tab"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ About tab"; }
has_label "Full Name" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Name field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Name field"; }
has_label "Email" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Email field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Email field"; }
has_label "Save" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Save button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Save button"; }

echo "Step 2: Submit empty form (validation)"
R=$(run_iez $IEZ ui tap --label "Save"); assert_ok "$R" "Tap Save (empty)"
sleep 0.3
has_text "Name is required" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Name validation"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Name validation"; }
has_text "Email is required" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Email validation"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Email validation"; }

echo "Step 3: Fill form"
R=$(run_iez $IEZ ui type "Bob Smith" --label "Full Name"); assert_ok "$R" "Type name"
sleep 0.3
R=$(run_iez $IEZ ui type "bob@test.com" --label "Email"); assert_ok "$R" "Type email"
sleep 0.3

echo "Step 4: Submit valid form"
R=$(run_iez $IEZ ui tap --label "Save"); assert_ok "$R" "Save form"
sleep 0.5
has_text "Saved:" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Save confirmation"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Save confirmation"; }
has_text "Bob Smith" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Name saved"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Name saved"; }

echo "Step 5: Switch tabs (use coords — tab labels have multiline suffixes)"
# Settings tab is middle (~200,120), About is right (~335,120), Profile is left (~67,120)
R=$(run_iez $IEZ ui tap --coords 200,120); assert_ok "$R" "Tap Settings tab"
sleep 0.5
has_text "Settings Page" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Settings content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Settings content"; }
R=$(run_iez $IEZ ui tap --coords 335,120); assert_ok "$R" "Tap About tab"
sleep 0.5
has_text "About Page" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ About content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ About content"; }
R=$(run_iez $IEZ ui tap --coords 67,120); assert_ok "$R" "Back to Profile"
sleep 0.3
has_text "Saved:" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Form state preserved"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Form state preserved"; }

echo ""

########################################################################
# APP 67: BottomSheetTypes — Modal + Persistent BottomSheet, ShowDialog variants
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App67());
class App67 extends StatelessWidget {
  const App67({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DialogShowcase',
      theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true),
      home: const DialogShowcaseHome(),
    );
  }
}
class DialogShowcaseHome extends StatefulWidget {
  const DialogShowcaseHome({super.key});
  @override
  State<DialogShowcaseHome> createState() => _DialogShowcaseHomeState();
}
class _DialogShowcaseHomeState extends State<DialogShowcaseHome> {
  String _lastResult = 'None';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DialogShowcase')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Last result: $_lastResult', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.warning),
          label: const Text('Alert Dialog'),
          onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _lastResult = 'Cancelled'); },
                child: const Text('Cancel')),
              FilledButton(onPressed: () { Navigator.pop(ctx); setState(() => _lastResult = 'Deleted'); },
                child: const Text('Delete')),
            ],
          )),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.list),
          label: const Text('Simple Dialog'),
          onPressed: () => showDialog(context: context, builder: (ctx) => SimpleDialog(
            title: const Text('Choose Color'),
            children: ['Red', 'Green', 'Blue'].map((c) => SimpleDialogOption(
              onPressed: () { Navigator.pop(ctx); setState(() => _lastResult = 'Color: $c'); },
              child: Text(c),
            )).toList(),
          )),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.fullscreen),
          label: const Text('Full Screen Dialog'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Full Screen'), actions: [
                TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _lastResult = 'Full screen done'); },
                  child: const Text('Done')),
              ]),
              body: const Center(child: Text('Full screen dialog content')),
            ),
          )),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.vertical_align_bottom),
          label: const Text('Modal Bottom Sheet'),
          onPressed: () => showModalBottomSheet(context: context, builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Modal Sheet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.photo), title: const Text('Photo'),
                onTap: () { Navigator.pop(ctx); setState(() => _lastResult = 'Photo'); }),
              ListTile(leading: const Icon(Icons.camera), title: const Text('Camera'),
                onTap: () { Navigator.pop(ctx); setState(() => _lastResult = 'Camera'); }),
              ListTile(leading: const Icon(Icons.file_copy), title: const Text('File'),
                onTap: () { Navigator.pop(ctx); setState(() => _lastResult = 'File'); }),
            ]),
          )),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.info),
          label: const Text('Snackbar'),
          onPressed: () {
            setState(() => _lastResult = 'Snackbar shown');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('This is a snackbar message'),
              duration: Duration(seconds: 2),
            ));
          },
        ),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 67: DialogShowcase"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "DialogShowcase" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Last result: None" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default result"; }
has_label "Alert Dialog" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Alert button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Alert button"; }
has_label "Simple Dialog" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Simple button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Simple button"; }
has_label "Full Screen Dialog" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Full screen button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Full screen button"; }
has_label "Modal Bottom Sheet" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Modal button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Modal button"; }
has_label "Snackbar" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Snackbar button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Snackbar button"; }

echo "Step 2: AlertDialog"
R=$(run_iez $IEZ ui tap --label "Alert Dialog"); assert_ok "$R" "Open alert"
sleep 0.5
has_text "Confirm Delete" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Alert title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Alert title"; }
has_text "Are you sure" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Alert content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Alert content"; }
R=$(run_iez $IEZ ui tap --label "Delete"); assert_ok "$R" "Tap Delete"
sleep 0.3
has_text "Last result: Deleted" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Deleted result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Deleted result"; }

echo "Step 3: AlertDialog Cancel"
R=$(run_iez $IEZ ui tap --label "Alert Dialog"); assert_ok "$R" "Open alert again"
sleep 0.5
R=$(run_iez $IEZ ui tap --label "Cancel"); assert_ok "$R" "Tap Cancel"
sleep 0.3
has_text "Last result: Cancelled" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cancelled result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cancelled result"; }

echo "Step 4: SimpleDialog"
R=$(run_iez $IEZ ui tap --label "Simple Dialog"); assert_ok "$R" "Open simple dialog"
sleep 0.5
has_text "Choose Color" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Simple title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Simple title"; }
has_text "Red" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Red option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Red option"; }
has_text "Green" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Green option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Green option"; }
R=$(run_iez $IEZ ui tap --label "Blue"); assert_ok "$R" "Select Blue"
sleep 0.3
has_text "Color: Blue" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Blue result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Blue result"; }

echo "Step 5: Full Screen Dialog"
R=$(run_iez $IEZ ui tap --label "Full Screen Dialog"); assert_ok "$R" "Open full screen"
sleep 0.5
has_text "Full screen dialog content" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ FS content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ FS content"; }
has_label "Done" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Done button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Done button"; }
R=$(run_iez $IEZ ui tap --label "Done"); assert_ok "$R" "Tap Done"
sleep 0.3
has_text "Full screen done" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ FS result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ FS result"; }

echo "Step 6: Modal Bottom Sheet"
R=$(run_iez $IEZ ui tap --label "Modal Bottom Sheet"); assert_ok "$R" "Open modal sheet"
sleep 0.5
has_text "Modal Sheet" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Sheet title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Sheet title"; }
has_text "Photo" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Photo option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Photo option"; }
has_text "Camera" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Camera option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Camera option"; }
R=$(run_iez $IEZ ui tap --label "Camera"); assert_ok "$R" "Select Camera"
sleep 0.3
has_text "Last result: Camera" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Camera result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Camera result"; }

echo "Step 7: Snackbar"
R=$(run_iez $IEZ ui tap --label "Snackbar"); assert_ok "$R" "Show snackbar"
sleep 0.5
has_text "snackbar message" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Snackbar text"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Snackbar text"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
