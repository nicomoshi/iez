import 'package:flutter/material.dart';

void main() => runApp(const ColorMixerApp());

class ColorMixerApp extends StatelessWidget {
  const ColorMixerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Mixer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ColorMixerHome(),
    );
  }
}

class ColorMixerHome extends StatefulWidget {
  const ColorMixerHome({super.key});
  @override
  State<ColorMixerHome> createState() => _ColorMixerHomeState();
}

class _ColorMixerHomeState extends State<ColorMixerHome> {
  double _red = 128;
  double _green = 128;
  double _blue = 128;
  final List<Color> _savedColors = [];

  Color get _currentColor => Color.fromARGB(255, _red.toInt(), _green.toInt(), _blue.toInt());
  String get _hexCode => '#${_currentColor.toHexString().substring(2).toUpperCase()}';

  void _saveColor() {
    setState(() => _savedColors.add(_currentColor));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Color $_hexCode saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Mixer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Saved Colors',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SavedColorsPage(colors: _savedColors))),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('About Color Mixer'),
                content: const Text('Mix colors using RGB sliders and save your favorites!'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: Text(_hexCode,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    )),
              ),
            ),
            const SizedBox(height: 24),
            _buildSlider('Red', _red, Colors.red, (v) => setState(() => _red = v)),
            _buildSlider('Green', _green, Colors.green, (v) => setState(() => _green = v)),
            _buildSlider('Blue', _blue, Colors.blue, (v) => setState(() => _blue = v)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveColor,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Color'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _red = 128; _green = 128; _blue = 128;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Quick Colors', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickColor('Pure Red', 255, 0, 0),
                _quickColor('Pure Green', 0, 255, 0),
                _quickColor('Pure Blue', 0, 0, 255),
                _quickColor('Yellow', 255, 255, 0),
                _quickColor('Cyan', 0, 255, 255),
                _quickColor('White', 255, 255, 255),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text('$label: ${value.toInt()}')),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _quickColor(String name, int r, int g, int b) {
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: Color.fromARGB(255, r, g, b), radius: 10),
      label: Text(name),
      onPressed: () => setState(() { _red = r.toDouble(); _green = g.toDouble(); _blue = b.toDouble(); }),
    );
  }
}

class SavedColorsPage extends StatelessWidget {
  final List<Color> colors;
  const SavedColorsPage({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Colors')),
      body: colors.isEmpty
          ? const Center(child: Text('No saved colors yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: colors.length,
              itemBuilder: (_, i) {
                final hex = '#${colors[i].toHexString().substring(2).toUpperCase()}';
                return Container(
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(hex,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors[i].computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        )),
                  ),
                );
              },
            ),
    );
  }
}

extension on Color {
  String toHexString() {
    return 'FF${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';
  }
}
