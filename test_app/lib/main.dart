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
