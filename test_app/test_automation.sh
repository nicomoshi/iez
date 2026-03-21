#!/usr/bin/env bash
# Apps 68-70: SliverAppBar / NestedNav / AnimatedWidgets
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
# APP 68: SliverAppBar — CollapsibleAppBar + SliverList + FloatingActionButton
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App68());
class App68 extends StatelessWidget {
  const App68({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SliverApp',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const SliverHome(),
    );
  }
}
class SliverHome extends StatefulWidget {
  const SliverHome({super.key});
  @override
  State<SliverHome> createState() => _SliverHomeState();
}
class _SliverHomeState extends State<SliverHome> {
  final List<String> _items = List.generate(20, (i) => 'Item ${i + 1}');
  String _selected = 'None';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('SliverApp'),
            background: Container(color: Theme.of(context).colorScheme.primaryContainer),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {
              setState(() => _selected = 'Search tapped');
            }),
          ],
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Selected: $_selected', style: Theme.of(context).textTheme.titleMedium),
        )),
        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) => ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(_items[i]),
            subtitle: Text('Description for item ${i + 1}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selected = _items[i]),
          ),
          childCount: _items.length,
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _selected = 'FAB tapped'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
DART

echo "========================================"
echo "APP 68: SliverApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_text "SliverApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Selected: None" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default selected"; }
has_text "Item 1" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Item 1"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Item 1"; }
has_text "Item 2" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Item 2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Item 2"; }
has_label "Add" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ FAB"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ FAB"; }

echo "Step 2: Tap Item 1"
# ListTile labels are multiline "1\nItem 1\nDescription..." — use coords
R=$(run_iez $IEZ ui tap --coords 200,354); assert_ok "$R" "Tap Item 1"
sleep 0.3
has_text "Selected: Item 1" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Item 1 selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Item 1 selected"; }

echo "Step 3: Tap FAB"
R=$(run_iez $IEZ ui tap --label "Add"); assert_ok "$R" "Tap Add FAB"
sleep 0.3
has_text "FAB tapped" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ FAB result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ FAB result"; }

echo "Step 4: Scroll down"
R=$(run_iez $IEZ ui swipe up); assert_ok "$R" "Scroll down"
sleep 0.5
R=$(run_iez $IEZ ui swipe up); assert_ok "$R" "Scroll more"
sleep 0.3
has_text "Item 10" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Item 10 visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Item 10 visible"; }

echo "Step 5: Scroll back up"
R=$(run_iez $IEZ ui swipe down); assert_ok "$R" "Scroll up"
sleep 0.3
R=$(run_iez $IEZ ui swipe down); assert_ok "$R" "Scroll up more"
sleep 0.3
has_text "Item 1" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back to top"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back to top"; }

echo ""

########################################################################
# APP 69: NestedNav — Bottom tabs + push navigation within tabs
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App69());
class App69 extends StatelessWidget {
  const App69({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NestedNav',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const NestedNavHome(),
    );
  }
}
class NestedNavHome extends StatefulWidget {
  const NestedNavHome({super.key});
  @override
  State<NestedNavHome> createState() => _NestedNavHomeState();
}
class _NestedNavHomeState extends State<NestedNavHome> {
  int _tabIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: [
        Navigator(onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => _TabPage(tabName: 'Feed', onPush: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => const _DetailPage(title: 'Post Detail', content: 'Full post content here')));
          }),
        )),
        Navigator(onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => _TabPage(tabName: 'Explore', onPush: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => const _DetailPage(title: 'Category Detail', content: 'Category items here')));
          }),
        )),
        Navigator(onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => _TabPage(tabName: 'Profile', onPush: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(
              builder: (_) => const _DetailPage(title: 'Edit Profile', content: 'Profile edit form')));
          }),
        )),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.feed), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
class _TabPage extends StatelessWidget {
  final String tabName;
  final void Function(BuildContext) onPush;
  const _TabPage({required this.tabName, required this.onPush});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tabName)),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$tabName Screen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => onPush(context), child: Text('Open $tabName Detail')),
      ])),
    );
  }
}
class _DetailPage extends StatelessWidget {
  final String title;
  final String content;
  const _DetailPage({required this.title, required this.content});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
      ])),
    );
  }
}
DART

echo "========================================"
echo "APP 69: NestedNav"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state (Feed tab)"
has_label "Feed" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Feed title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Feed title"; }
has_text "Feed Screen" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Feed content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Feed content"; }
has_label "Open Feed Detail" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Detail button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Detail button"; }

echo "Step 2: Push detail within Feed tab"
R=$(run_iez $IEZ ui tap --label "Open Feed Detail"); assert_ok "$R" "Push detail"
sleep 0.5
has_text "Post Detail" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Detail title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Detail title"; }
has_text "Full post content" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Detail content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Detail content"; }
has_label "Go Back" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Go Back button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Go Back button"; }

echo "Step 3: Go back"
R=$(run_iez $IEZ ui tap --label "Go Back"); assert_ok "$R" "Go back"
sleep 0.3
has_text "Feed Screen" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back to Feed"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back to Feed"; }

echo "Step 4: Switch to Explore tab"
# Bottom nav labels have "\nTab X of Y" — use coords
# Feed ~67,850, Explore ~201,850, Profile ~335,850
R=$(run_iez $IEZ ui tap --coords 201,790); assert_ok "$R" "Tap Explore"
sleep 0.5
has_text "Explore Screen" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Explore content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Explore content"; }

echo "Step 5: Push Explore detail"
R=$(run_iez $IEZ ui tap --label "Open Explore Detail"); assert_ok "$R" "Push explore detail"
sleep 0.5
has_text "Category Detail" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Category title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Category title"; }
R=$(run_iez $IEZ ui tap --label "Go Back"); assert_ok "$R" "Go back"
sleep 0.3

echo "Step 6: Switch to Profile"
R=$(run_iez $IEZ ui tap --coords 335,790); assert_ok "$R" "Tap Profile"
sleep 0.5
has_text "Profile Screen" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Profile content"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Profile content"; }

echo "Step 7: Profile detail + back to Feed"
R=$(run_iez $IEZ ui tap --label "Open Profile Detail"); assert_ok "$R" "Push profile detail"
sleep 0.5
has_text "Edit Profile" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Edit Profile title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Edit Profile title"; }
R=$(run_iez $IEZ ui tap --label "Go Back"); assert_ok "$R" "Go back"
sleep 0.3
R=$(run_iez $IEZ ui tap --coords 67,790); assert_ok "$R" "Back to Feed tab"
sleep 0.3
has_text "Feed Screen" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Feed preserved"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Feed preserved"; }

echo ""

########################################################################
# APP 70: AnimatedWidgets — AnimatedOpacity, AnimatedAlign, AnimatedCrossFade
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App70());
class App70 extends StatelessWidget {
  const App70({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimWidgets',
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
      home: const AnimWidgetsHome(),
    );
  }
}
class AnimWidgetsHome extends StatefulWidget {
  const AnimWidgetsHome({super.key});
  @override
  State<AnimWidgetsHome> createState() => _AnimWidgetsHomeState();
}
class _AnimWidgetsHomeState extends State<AnimWidgetsHome> {
  bool _visible = true;
  bool _showFirst = true;
  bool _aligned = false;
  double _containerWidth = 100;
  Color _containerColor = Colors.blue;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AnimWidgets')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AnimatedOpacity
          Text('Opacity: ${_visible ? "Visible" : "Hidden"}',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 200, height: 50,
              decoration: BoxDecoration(color: Colors.blue.shade200, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('Fade Box'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() => _visible = !_visible),
            child: Text(_visible ? 'Hide' : 'Show'),
          ),
          const SizedBox(height: 24),

          // AnimatedCrossFade
          Text('CrossFade: ${_showFirst ? "First" : "Second"}',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Container(
              width: 200, height: 50, alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.green.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Text('Widget A'),
            ),
            secondChild: Container(
              width: 200, height: 80, alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.orange.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Text('Widget B'),
            ),
            crossFadeState: _showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() => _showFirst = !_showFirst),
            child: const Text('Toggle CrossFade'),
          ),
          const SizedBox(height: 24),

          // AnimatedContainer
          Text('Container: ${_containerWidth.round()}w',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AnimatedContainer(
            width: _containerWidth, height: 50,
            decoration: BoxDecoration(color: _containerColor, borderRadius: BorderRadius.circular(8)),
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.center,
            child: const Text('Animated', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() {
              _containerWidth = _containerWidth == 100 ? 300 : 100;
              _containerColor = _containerColor == Colors.blue ? Colors.purple : Colors.blue;
            }),
            child: const Text('Animate Container'),
          ),
        ],
      )),
    );
  }
}
DART

echo "========================================"
echo "APP 70: AnimWidgets"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "AnimWidgets" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Opacity: Visible" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Opacity visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Opacity visible"; }
has_text "Fade Box" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Fade box"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Fade box"; }
has_text "CrossFade: First" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ CrossFade first"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ CrossFade first"; }
has_text "Widget A" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Widget A visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Widget A visible"; }
has_text "Container: 100w" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Container 100w"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Container 100w"; }

echo "Step 2: Hide opacity"
R=$(run_iez $IEZ ui tap --label "Hide"); assert_ok "$R" "Tap Hide"
sleep 0.5
has_text "Opacity: Hidden" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Hidden"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Hidden"; }
has_label "Show" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Show button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Show button"; }

echo "Step 3: Show opacity"
R=$(run_iez $IEZ ui tap --label "Show"); assert_ok "$R" "Tap Show"
sleep 0.5
has_text "Opacity: Visible" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Visible again"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Visible again"; }

echo "Step 4: Toggle CrossFade"
R=$(run_iez $IEZ ui tap --label "Toggle CrossFade"); assert_ok "$R" "Toggle CF"
sleep 0.5
has_text "CrossFade: Second" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Second shown"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Second shown"; }
has_text "Widget B" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Widget B visible"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Widget B visible"; }

echo "Step 5: Toggle back"
R=$(run_iez $IEZ ui tap --label "Toggle CrossFade"); assert_ok "$R" "Toggle CF back"
sleep 0.5
has_text "CrossFade: First" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ First again"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ First again"; }

echo "Step 6: Animate container"
R=$(run_iez $IEZ ui tap --label "Animate Container"); assert_ok "$R" "Animate"
sleep 0.5
has_text "Container: 300w" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 300w"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 300w"; }

echo "Step 7: Animate back"
R=$(run_iez $IEZ ui tap --label "Animate Container"); assert_ok "$R" "Animate back"
sleep 0.5
has_text "Container: 100w" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ 100w"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ 100w"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
