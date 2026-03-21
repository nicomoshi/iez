import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _resetOnNext = false;
  final List<String> _history = [];

  void _onDigit(String digit) {
    setState(() {
      if (_resetOnNext) {
        _display = digit;
        _resetOnNext = false;
      } else if (_display == '0' && digit != '.') {
        _display = digit;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '$_display $op';
      _resetOnNext = true;
    });
  }

  void _onEquals() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_display);
    if (second == null) return;

    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '-':
        result = _firstOperand! - second;
        break;
      case '*':
        result = _firstOperand! * second;
        break;
      case '/':
        if (second == 0) {
          setState(() {
            _display = 'Error';
            _expression = '';
            _resetOnNext = true;
          });
          return;
        }
        result = _firstOperand! / second;
        break;
      case '%':
        result = _firstOperand! % second;
        break;
      default:
        return;
    }

    final resultStr =
        result == result.roundToDouble() && !result.isInfinite && !result.isNaN
            ? result.toInt().toString()
            : result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    setState(() {
      _history.insert(0, '$_expression $second = $resultStr');
      _display = resultStr;
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _resetOnNext = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _resetOnNext = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onToggleSign() {
    setState(() {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else if (_display != '0') {
        _display = '-$_display';
      }
    });
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text('No calculations yet'))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_history[index]),
                      dense: true,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () {
                setState(() => _history.clear());
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label,
      {VoidCallback? onPressed, Color? color, bool expanded = false}) {
    return Expanded(
      flex: expanded ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 64,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 20,
                        color: cs.onSurface.withAlpha(128),
                      ),
                    ),
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton('C',
                          onPressed: _onClear,
                          color: cs.errorContainer),
                      _buildButton('+/-',
                          onPressed: _onToggleSign,
                          color: cs.tertiaryContainer),
                      _buildButton('%',
                          onPressed: () => _onOperator('%'),
                          color: cs.tertiaryContainer),
                      _buildButton('/',
                          onPressed: () => _onOperator('/'),
                          color: cs.primaryContainer),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('7', onPressed: () => _onDigit('7')),
                      _buildButton('8', onPressed: () => _onDigit('8')),
                      _buildButton('9', onPressed: () => _onDigit('9')),
                      _buildButton('*',
                          onPressed: () => _onOperator('*'),
                          color: cs.primaryContainer),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4', onPressed: () => _onDigit('4')),
                      _buildButton('5', onPressed: () => _onDigit('5')),
                      _buildButton('6', onPressed: () => _onDigit('6')),
                      _buildButton('-',
                          onPressed: () => _onOperator('-'),
                          color: cs.primaryContainer),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1', onPressed: () => _onDigit('1')),
                      _buildButton('2', onPressed: () => _onDigit('2')),
                      _buildButton('3', onPressed: () => _onDigit('3')),
                      _buildButton('+',
                          onPressed: () => _onOperator('+'),
                          color: cs.primaryContainer),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('0',
                          onPressed: () => _onDigit('0'), expanded: true),
                      _buildButton('.', onPressed: () => _onDigit('.')),
                      _buildButton('=',
                          onPressed: _onEquals,
                          color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
