#!/usr/bin/env bash
# Apps 71-73: SearchDelegate / PageViewIndicator / BottomAppBarScaffold
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
# APP 71: SearchDelegate — showSearch with suggestions and results
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App71());
class App71 extends StatelessWidget {
  const App71({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SearchApp',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const SearchHome());
  }
}
class SearchHome extends StatefulWidget {
  const SearchHome({super.key});
  @override
  State<SearchHome> createState() => _SearchHomeState();
}
class _SearchHomeState extends State<SearchHome> {
  String _selected = 'None';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SearchApp'), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () async {
          final result = await showSearch(context: context, delegate: _ItemSearchDelegate());
          if (result != null) setState(() => _selected = result);
        }),
      ]),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Selected: $_selected', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const Text('Tap search icon to find items'),
      ])),
    );
  }
}
class _ItemSearchDelegate extends SearchDelegate<String> {
  final items = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape', 'Honeydew'];
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget buildLeading(BuildContext context) =>
    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(children: results.map((r) => ListTile(
      title: Text(r), onTap: () => close(context, r),
    )).toList());
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty ? items.take(4).toList()
      : items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(children: suggestions.map((s) => ListTile(
      key: ValueKey(s),
      leading: const Icon(Icons.search),
      title: Text(s),
      onTap: () => close(context, s),
    )).toList());
  }
}
DART

echo "========================================"
echo "APP 71: SearchApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "SearchApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Selected: None" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Default"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Default"; }

echo "Step 2: Open search"
# Search icon in AppBar — use coords (right side of AppBar)
R=$(run_iez $IEZ ui tap --coords 370,78); assert_ok "$R" "Tap Search"
sleep 0.5
has_text "Apple" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Apple suggestion"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Apple suggestion"; }
has_text "Banana" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Banana suggestion"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Banana suggestion"; }

echo "Step 3: Select Apple directly"
R=$(run_iez $IEZ ui tap --label "Apple"); assert_ok "$R" "Tap Apple"
sleep 0.5
has_text "Selected: Apple" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Apple selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Apple selected"; }

echo "Step 4: Search again and select Cherry"
R=$(run_iez $IEZ ui tap --coords 370,78); assert_ok "$R" "Open search again"
sleep 0.5
R=$(run_iez $IEZ ui tap --label "Cherry"); assert_ok "$R" "Tap Cherry"
sleep 0.5
has_text "Selected: Cherry" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cherry selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cherry selected"; }

echo "Step 5: Search again and select Banana"
R=$(run_iez $IEZ ui tap --coords 370,78); assert_ok "$R" "Open search"
sleep 0.5
R=$(run_iez $IEZ ui tap --label "Banana"); assert_ok "$R" "Tap Banana"
sleep 0.5
has_text "Selected: Banana" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Banana selected"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Banana selected"; }

echo ""

########################################################################
# APP 72: PageViewIndicator — PageView with dots indicator
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App72());
class App72 extends StatelessWidget {
  const App72({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'PageViewApp',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const PageViewHome());
  }
}
class PageViewHome extends StatefulWidget {
  const PageViewHome({super.key});
  @override
  State<PageViewHome> createState() => _PageViewHomeState();
}
class _PageViewHomeState extends State<PageViewHome> {
  final _controller = PageController();
  int _currentPage = 0;
  final pages = [
    {'title': 'Welcome', 'subtitle': 'Get started with our app', 'color': Colors.blue},
    {'title': 'Discover', 'subtitle': 'Find amazing content', 'color': Colors.green},
    {'title': 'Connect', 'subtitle': 'Join the community', 'color': Colors.orange},
    {'title': 'Create', 'subtitle': 'Build something great', 'color': Colors.purple},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page ${_currentPage + 1} of ${pages.length}')),
      body: Column(children: [
        Expanded(child: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (ctx, i) {
            final p = pages[i];
            return Container(
              color: (p['color'] as Color).withValues(alpha: 0.1),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(p['title'] as String, style: Theme.of(ctx).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(p['subtitle'] as String, style: Theme.of(ctx).textTheme.bodyLarge),
              ])),
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(16), child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) => Container(
            width: i == _currentPage ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == _currentPage
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            ),
          )),
        )),
        Padding(padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: _currentPage > 0 ? () => _controller.previousPage(
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
              child: const Text('Previous'),
            ),
            FilledButton(
              onPressed: _currentPage < pages.length - 1 ? () => _controller.nextPage(
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
              child: Text(_currentPage < pages.length - 1 ? 'Next' : 'Done'),
            ),
          ]),
        ),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 72: PageViewApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state (page 1)"
has_text "Page 1 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Page counter"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Page counter"; }
has_text "Welcome" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Welcome title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Welcome title"; }
has_text "Get started" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Welcome subtitle"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Welcome subtitle"; }
has_label "Next" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Next button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Next button"; }
has_label "Previous" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Previous button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Previous button"; }

echo "Step 2: Next page"
R=$(run_iez $IEZ ui tap --label "Next"); assert_ok "$R" "Tap Next"
sleep 0.5
has_text "Page 2 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Page 2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Page 2"; }
has_text "Discover" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Discover"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Discover"; }

echo "Step 3: Swipe to page 3"
R=$(run_iez $IEZ ui swipe --from 350,400 --to 50,400); assert_ok "$R" "Swipe to page 3"
sleep 0.5
has_text "Page 3 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Page 3"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Page 3"; }
has_text "Connect" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Connect"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Connect"; }

echo "Step 4: Next to page 4"
R=$(run_iez $IEZ ui tap --label "Next"); assert_ok "$R" "Tap Next"
sleep 0.5
has_text "Page 4 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Page 4"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Page 4"; }
has_text "Create" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Create"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Create"; }
has_label "Done" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Done button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Done button"; }

echo "Step 5: Go back with Previous"
R=$(run_iez $IEZ ui tap --label "Previous"); assert_ok "$R" "Tap Previous"
sleep 0.5
has_text "Page 3 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back to 3"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back to 3"; }

echo "Step 6: Swipe back"
R=$(run_iez $IEZ ui swipe --from 50,400 --to 350,400); assert_ok "$R" "Swipe back"
sleep 0.5
has_text "Page 2 of 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Back to 2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Back to 2"; }

echo ""

########################################################################
# APP 73: BottomAppBarScaffold — BottomAppBar with notched FAB + menus
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App73());
class App73 extends StatelessWidget {
  const App73({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'BottomBarApp',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: const BottomBarHome());
  }
}
class BottomBarHome extends StatefulWidget {
  const BottomBarHome({super.key});
  @override
  State<BottomBarHome> createState() => _BottomBarHomeState();
}
class _BottomBarHomeState extends State<BottomBarHome> {
  int _count = 0;
  String _lastAction = 'None';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BottomBarApp')),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Count: $_count', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 16),
        Text('Last action: $_lastAction', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton(onPressed: () => setState(() { _count++; _lastAction = 'Incremented'; }),
            child: const Text('Increment')),
          const SizedBox(width: 16),
          OutlinedButton(onPressed: () => setState(() { _count--; _lastAction = 'Decremented'; }),
            child: const Text('Decrement')),
        ]),
        const SizedBox(height: 16),
        TextButton(onPressed: () => setState(() { _count = 0; _lastAction = 'Reset'; }),
          child: const Text('Reset')),
      ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() { _count += 10; _lastAction = 'Added 10'; }),
        tooltip: 'Add 10',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.menu), tooltip: 'Menu', onPressed: () {
            showModalBottomSheet(context: context, builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(leading: const Icon(Icons.share), title: const Text('Share Count'),
                  onTap: () { Navigator.pop(ctx); setState(() => _lastAction = 'Shared: $_count'); }),
                ListTile(leading: const Icon(Icons.copy), title: const Text('Copy Count'),
                  onTap: () { Navigator.pop(ctx); setState(() => _lastAction = 'Copied: $_count'); }),
              ],
            ));
          }),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), tooltip: 'Search', onPressed: () =>
            setState(() => _lastAction = 'Search pressed')),
        ]),
      ),
    );
  }
}
DART

echo "========================================"
echo "APP 73: BottomBarApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "BottomBarApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Count: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Count 0"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Count 0"; }
has_text "Last action: None" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Action None"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Action None"; }
has_label "Increment" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Increment btn"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Increment btn"; }
has_label "Decrement" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Decrement btn"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Decrement btn"; }
has_label "Reset" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reset btn"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reset btn"; }

echo "Step 2: Increment"
R=$(run_iez $IEZ ui tap --label "Increment"); assert_ok "$R" "Tap Increment"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Increment"); assert_ok "$R" "Tap Increment"
sleep 0.3
R=$(run_iez $IEZ ui tap --label "Increment"); assert_ok "$R" "Tap Increment"
sleep 0.3
has_text "Count: 3" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Count 3"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Count 3"; }

echo "Step 3: Decrement"
R=$(run_iez $IEZ ui tap --label "Decrement"); assert_ok "$R" "Decrement"
sleep 0.3
has_text "Count: 2" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Count 2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Count 2"; }

echo "Step 4: FAB (+10)"
R=$(run_iez $IEZ ui tap --label "Add 10"); assert_ok "$R" "Tap FAB"
sleep 0.3
has_text "Count: 12" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Count 12"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Count 12"; }
has_text "Added 10" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Added 10 action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Added 10 action"; }

echo "Step 5: Reset"
R=$(run_iez $IEZ ui tap --label "Reset"); assert_ok "$R" "Reset"
sleep 0.3
has_text "Count: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Count reset"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Count reset"; }

echo "Step 6: Bottom bar menu"
R=$(run_iez $IEZ ui tap --label "Menu"); assert_ok "$R" "Tap menu"
sleep 0.5
has_text "Share Count" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Share option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Share option"; }
has_text "Copy Count" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Copy option"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Copy option"; }
R=$(run_iez $IEZ ui tap --label "Share Count"); assert_ok "$R" "Share"
sleep 0.3
has_text "Shared: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Shared result"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Shared result"; }

echo "Step 7: Search icon"
R=$(run_iez $IEZ ui tap --label "Search"); assert_ok "$R" "Tap search"
sleep 0.3
has_text "Search pressed" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Search action"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Search action"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
