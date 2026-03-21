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
