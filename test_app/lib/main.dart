import 'package:flutter/material.dart';

void main() => runApp(const ExpandablePanelApp());

class ExpandablePanelApp extends StatelessWidget {
  const ExpandablePanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expandable Panel Test',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const FAQPage(),
    );
  }
}

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});
  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final _faqs = [
    _FAQ('What is Flutter?', 'Flutter is a UI toolkit for building natively compiled applications.'),
    _FAQ('How do I install Flutter?', 'Download the SDK from flutter.dev and add it to your PATH.'),
    _FAQ('What is Dart?', 'Dart is a client-optimized programming language for apps on multiple platforms.'),
    _FAQ('Is Flutter free?', 'Yes, Flutter is free and open source.'),
    _FAQ('What platforms does Flutter support?', 'Flutter supports iOS, Android, Web, Windows, macOS, and Linux.'),
  ];

  String _searchQuery = '';

  List<_FAQ> get _filtered =>
    _searchQuery.isEmpty ? _faqs : _faqs.where((f) =>
      f.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      f.answer.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search FAQ...',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${_filtered.length} questions'),
          ),
          Expanded(
            child: ListView(
              children: _filtered.map((faq) => ExpansionTile(
                title: Text(faq.question),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq.answer),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => faq.helpful = !faq.helpful),
                          icon: Icon(faq.helpful ? Icons.thumb_up : Icons.thumb_up_outlined),
                          label: Text(faq.helpful ? 'Helpful' : 'Was this helpful?'),
                        ),
                      ],
                    ),
                  ),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) {
              final qCtrl = TextEditingController();
              return AlertDialog(
                title: const Text('Ask a Question'),
                content: TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(labelText: 'Your question'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () {
                      if (qCtrl.text.isNotEmpty) {
                        setState(() => _faqs.add(_FAQ(qCtrl.text, 'Answer pending...')));
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
    );
  }
}

class _FAQ {
  String question;
  String answer;
  bool helpful;
  _FAQ(this.question, this.answer, {this.helpful = false});
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('FAQ App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Version 1.0.0'),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.code),
              title: Text('Built with Flutter'),
              subtitle: Text('Material Design 3'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
