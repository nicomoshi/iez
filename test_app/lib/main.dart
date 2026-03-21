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
