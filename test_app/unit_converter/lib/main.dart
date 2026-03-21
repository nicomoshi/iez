import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const UnitConverterApp());
}

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit Converter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const UnitConverterHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

enum Category { length, weight, temperature, volume }

const _categoryLabels = {
  Category.length: 'Length',
  Category.weight: 'Weight',
  Category.temperature: 'Temperature',
  Category.volume: 'Volume',
};

const _categoryIcons = {
  Category.length: Icons.straighten,
  Category.weight: Icons.fitness_center,
  Category.temperature: Icons.thermostat,
  Category.volume: Icons.water_drop,
};

const _units = {
  Category.length: ['Meters', 'Feet', 'Inches', 'Kilometers', 'Miles'],
  Category.weight: ['Kilograms', 'Pounds', 'Ounces', 'Grams', 'Tonnes'],
  Category.temperature: ['Celsius', 'Fahrenheit', 'Kelvin'],
  Category.volume: ['Liters', 'Milliliters', 'Gallons', 'Cups', 'Fluid Ounces'],
};

// Convert any unit → base unit (SI), then base → target
double? convert(Category cat, String from, String to, double value) {
  if (from == to) return value;
  switch (cat) {
    case Category.length:
      return _convertLength(from, to, value);
    case Category.weight:
      return _convertWeight(from, to, value);
    case Category.temperature:
      return _convertTemperature(from, to, value);
    case Category.volume:
      return _convertVolume(from, to, value);
  }
}

double _toMeters(String unit, double v) {
  switch (unit) {
    case 'Meters':
      return v;
    case 'Feet':
      return v * 0.3048;
    case 'Inches':
      return v * 0.0254;
    case 'Kilometers':
      return v * 1000;
    case 'Miles':
      return v * 1609.344;
    default:
      return v;
  }
}

double _fromMeters(String unit, double v) {
  switch (unit) {
    case 'Meters':
      return v;
    case 'Feet':
      return v / 0.3048;
    case 'Inches':
      return v / 0.0254;
    case 'Kilometers':
      return v / 1000;
    case 'Miles':
      return v / 1609.344;
    default:
      return v;
  }
}

double _convertLength(String from, String to, double v) =>
    _fromMeters(to, _toMeters(from, v));

double _toKg(String unit, double v) {
  switch (unit) {
    case 'Kilograms':
      return v;
    case 'Pounds':
      return v * 0.453592;
    case 'Ounces':
      return v * 0.0283495;
    case 'Grams':
      return v / 1000;
    case 'Tonnes':
      return v * 1000;
    default:
      return v;
  }
}

double _fromKg(String unit, double v) {
  switch (unit) {
    case 'Kilograms':
      return v;
    case 'Pounds':
      return v / 0.453592;
    case 'Ounces':
      return v / 0.0283495;
    case 'Grams':
      return v * 1000;
    case 'Tonnes':
      return v / 1000;
    default:
      return v;
  }
}

double _convertWeight(String from, String to, double v) =>
    _fromKg(to, _toKg(from, v));

double _convertTemperature(String from, String to, double v) {
  if (from == to) return v;
  double celsius;
  switch (from) {
    case 'Celsius':
      celsius = v;
      break;
    case 'Fahrenheit':
      celsius = (v - 32) * 5 / 9;
      break;
    case 'Kelvin':
      celsius = v - 273.15;
      break;
    default:
      celsius = v;
  }
  switch (to) {
    case 'Celsius':
      return celsius;
    case 'Fahrenheit':
      return celsius * 9 / 5 + 32;
    case 'Kelvin':
      return celsius + 273.15;
    default:
      return celsius;
  }
}

double _toLiters(String unit, double v) {
  switch (unit) {
    case 'Liters':
      return v;
    case 'Milliliters':
      return v / 1000;
    case 'Gallons':
      return v * 3.78541;
    case 'Cups':
      return v * 0.236588;
    case 'Fluid Ounces':
      return v * 0.0295735;
    default:
      return v;
  }
}

double _fromLiters(String unit, double v) {
  switch (unit) {
    case 'Liters':
      return v;
    case 'Milliliters':
      return v * 1000;
    case 'Gallons':
      return v / 3.78541;
    case 'Cups':
      return v / 0.236588;
    case 'Fluid Ounces':
      return v / 0.0295735;
    default:
      return v;
  }
}

double _convertVolume(String from, String to, double v) =>
    _fromLiters(to, _toLiters(from, v));

String _formatResult(double v) {
  if (v == v.truncateToDouble() && v.abs() < 1e9) {
    return v.toStringAsFixed(0);
  }
  if (v.abs() >= 1000 || (v.abs() < 0.001 && v != 0)) {
    return v.toStringAsExponential(4);
  }
  return v
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

// ── History entry ─────────────────────────────────────────────────────────────

class HistoryEntry {
  final Category category;
  final String fromUnit;
  final String toUnit;
  final double inputValue;
  final double resultValue;

  const HistoryEntry({
    required this.category,
    required this.fromUnit,
    required this.toUnit,
    required this.inputValue,
    required this.resultValue,
  });

  String get subtitle =>
      '${_formatResult(inputValue)} $fromUnit = ${_formatResult(resultValue)} $toUnit';
}

// ── Home ──────────────────────────────────────────────────────────────────────

class UnitConverterHome extends StatefulWidget {
  const UnitConverterHome({super.key});

  @override
  State<UnitConverterHome> createState() => _UnitConverterHomeState();
}

class _UnitConverterHomeState extends State<UnitConverterHome> {
  Category _category = Category.length;
  late String _fromUnit;
  late String _toUnit;
  final _controller = TextEditingController();
  double? _result;
  final List<HistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    final units = _units[_category]!;
    _fromUnit = units[0];
    _toUnit = units[1];
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  List<String> get _currentUnits => _units[_category]!;

  void _onCategoryChanged(Category cat) {
    setState(() {
      _category = cat;
      final units = _units[cat]!;
      _fromUnit = units[0];
      _toUnit = units[1];
      _result = null;
    });
    _onInputChanged();
  }

  void _onInputChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _result = null);
      return;
    }
    final v = double.tryParse(text);
    if (v == null) {
      setState(() => _result = null);
      return;
    }
    final r = convert(_category, _fromUnit, _toUnit, v);
    setState(() => _result = r);
    if (r != null) _pushHistory(v, r);
  }

  void _pushHistory(double input, double result) {
    final entry = HistoryEntry(
      category: _category,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
      inputValue: input,
      resultValue: result,
    );
    // Avoid pushing identical consecutive entries
    if (_history.isNotEmpty && _history.first.subtitle == entry.subtitle) {
      return;
    }
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 5) _history.removeLast();
    });
  }

  void _swap() {
    setState(() {
      final tmp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tmp;
    });
    _onInputChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
        centerTitle: true,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Category chips ─────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: Category.values.map((cat) {
                final label = _categoryLabels[cat]!;
                final selected = cat == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => _onCategoryChanged(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Input field ────────────────────────────────────────────────
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Enter value',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 20),

          // ── From / Swap / To row ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fromUnit,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _fromUnit = v);
                    _onInputChanged();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton.filled(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Swap',
                  onPressed: _swap,
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _toUnit,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _toUnit = v);
                    _onInputChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Result display ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Result',
                  style: tt.labelLarge?.copyWith(color: cs.onSecondaryContainer),
                ),
                const SizedBox(height: 8),
                Text(
                  _result != null
                      ? '${_formatResult(_result!)} $_toUnit'
                      : '—',
                  style: tt.displaySmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── History ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('History', style: tt.titleMedium),
              TextButton(
                onPressed:
                    _history.isEmpty ? null : () => setState(() => _history.clear()),
                child: const Text('Clear History'),
              ),
            ],
          ),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No conversions yet.',
                style: tt.bodyMedium?.copyWith(color: cs.outline),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._history.map(
              (e) => ListTile(
                leading: Icon(
                  _categoryIcons[e.category],
                  color: cs.primary,
                ),
                title: Text(_categoryLabels[e.category]!),
                subtitle: Text(e.subtitle),
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}
