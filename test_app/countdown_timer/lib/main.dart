import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const CountdownTimerApp());

class CountdownTimerApp extends StatelessWidget {
  const CountdownTimerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});
  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> {
  int _totalSeconds = 60;
  int _remainingSeconds = 60;
  bool _isRunning = false;
  Timer? _timer;
  final List<String> _history = [];

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _history.insert(0, 'Completed ${_totalSeconds}s at ${TimeOfDay.now().format(context)}');
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = _totalSeconds);
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => HistoryPage(history: _history))),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              final result = await Navigator.push<int>(context,
                  MaterialPageRoute(builder: (_) => SettingsPage(currentSeconds: _totalSeconds)));
              if (result != null) {
                setState(() {
                  _totalSeconds = result;
                  _remainingSeconds = result;
                  _isRunning = false;
                });
                _timer?.cancel();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_timeDisplay,
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
                semanticsLabel: 'Time remaining'),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopTimer : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Duration: ${_totalSeconds}s',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final List<String> history;
  const HistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer History')),
      body: history.isEmpty
          ? const Center(child: Text('No completed timers yet'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(history[i]),
              ),
            ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final int currentSeconds;
  const SettingsPage({super.key, required this.currentSeconds});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _sliderValue;
  final List<int> _presets = [30, 60, 120, 300, 600];

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentSeconds.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_sliderValue.toInt()} seconds',
                style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: _sliderValue,
              min: 10,
              max: 600,
              divisions: 59,
              label: '${_sliderValue.toInt()}s',
              onChanged: (v) => setState(() => _sliderValue = v),
            ),
            const SizedBox(height: 20),
            Text('Quick Presets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _presets.map((p) => ActionChip(
                label: Text('${p}s'),
                onPressed: () => setState(() => _sliderValue = p.toDouble()),
              )).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _sliderValue.toInt()),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
