import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.light,
        ),
      ),
      home: const PomodoroHomePage(),
    );
  }
}

enum SessionType { work, shortBreak, longBreak }

class AppSettings {
  int workMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  bool autoStartBreaks;

  AppSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.autoStartBreaks = false,
  });

  int durationFor(SessionType type) {
    switch (type) {
      case SessionType.work:
        return workMinutes;
      case SessionType.shortBreak:
        return shortBreakMinutes;
      case SessionType.longBreak:
        return longBreakMinutes;
    }
  }
}

class PomodoroHomePage extends StatefulWidget {
  const PomodoroHomePage({super.key});

  @override
  State<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends State<PomodoroHomePage> {
  AppSettings _settings = AppSettings();

  SessionType _currentSession = SessionType.work;
  int _sessionCount = 1;
  static const int _totalSessions = 4;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _settings.workMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _sessionLabel {
    switch (_currentSession) {
      case SessionType.work:
        return 'Work';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String get _timerDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isPaused = false;
          _onSessionComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _settings.durationFor(_currentSession) * 60;
    });
  }

  void _onSessionComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session complete!')),
    );

    if (_currentSession == SessionType.work) {
      if (_sessionCount >= _totalSessions) {
        setState(() {
          _currentSession = SessionType.longBreak;
          _sessionCount = 1;
          _remainingSeconds = _settings.longBreakMinutes * 60;
        });
      } else {
        setState(() {
          _sessionCount++;
          _currentSession = SessionType.shortBreak;
          _remainingSeconds = _settings.shortBreakMinutes * 60;
        });
      }
    } else {
      setState(() {
        _currentSession = SessionType.work;
        _remainingSeconds = _settings.workMinutes * 60;
      });
    }

    if (_settings.autoStartBreaks) {
      _startTimer();
    }
  }

  void _selectSession(SessionType type) {
    _timer?.cancel();
    setState(() {
      _currentSession = type;
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _settings.durationFor(type) * 60;
    });
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(settings: _settings),
      ),
    );
    if (updated != null) {
      setState(() {
        _settings = updated;
        _timer?.cancel();
        _isRunning = false;
        _isPaused = false;
        _remainingSeconds = _settings.durationFor(_currentSession) * 60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // Session type indicator
              Text(
                _sessionLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Session counter
              Text(
                'Session $_sessionCount of $_totalSessions',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Circular timer display
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 8,
                  ),
                  color: colorScheme.primaryContainer,
                ),
                child: Center(
                  child: Text(
                    _timerDisplay,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Start / Pause / Resume button
              ElevatedButton(
                onPressed: () {
                  if (_isRunning) {
                    _pauseTimer();
                  } else if (_isPaused) {
                    _resumeTimer();
                  } else {
                    _startTimer();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(160, 52),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(
                  _isRunning
                      ? 'Pause'
                      : _isPaused
                          ? 'Resume'
                          : 'Start',
                ),
              ),
              const SizedBox(height: 12),

              // Reset button
              TextButton(
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
              const SizedBox(height: 32),

              // Mode selector chips/cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ModeCard(
                    label: 'Work (25 min)',
                    selected: _currentSession == SessionType.work,
                    onTap: () => _selectSession(SessionType.work),
                  ),
                  _ModeCard(
                    label: 'Short Break (5 min)',
                    selected: _currentSession == SessionType.shortBreak,
                    onTap: () => _selectSession(SessionType.shortBreak),
                  ),
                  _ModeCard(
                    label: 'Long Break (15 min)',
                    selected: _currentSession == SessionType.longBreak,
                    onTap: () => _selectSession(SessionType.longBreak),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: selected ? 4 : 1,
        color: selected ? colorScheme.primaryContainer : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final AppSettings settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _workMinutes;
  late double _shortBreakMinutes;
  late double _longBreakMinutes;
  late bool _autoStartBreaks;

  @override
  void initState() {
    super.initState();
    _workMinutes = widget.settings.workMinutes.toDouble();
    _shortBreakMinutes = widget.settings.shortBreakMinutes.toDouble();
    _longBreakMinutes = widget.settings.longBreakMinutes.toDouble();
    _autoStartBreaks = widget.settings.autoStartBreaks;
  }

  void _save() {
    Navigator.pop(
      context,
      AppSettings(
        workMinutes: _workMinutes.round(),
        shortBreakMinutes: _shortBreakMinutes.round(),
        longBreakMinutes: _longBreakMinutes.round(),
        autoStartBreaks: _autoStartBreaks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Work Duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _workMinutes,
                  min: 15,
                  max: 60,
                  divisions: 45,
                  label: '${_workMinutes.round()} min',
                  onChanged: (v) => setState(() => _workMinutes = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${_workMinutes.round()} min',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Short Break Duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _shortBreakMinutes,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '${_shortBreakMinutes.round()} min',
                  onChanged: (v) => setState(() => _shortBreakMinutes = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${_shortBreakMinutes.round()} min',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Long Break Duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _longBreakMinutes,
                  min: 10,
                  max: 30,
                  divisions: 20,
                  label: '${_longBreakMinutes.round()} min',
                  onChanged: (v) => setState(() => _longBreakMinutes = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '${_longBreakMinutes.round()} min',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Auto-start breaks'),
            value: _autoStartBreaks,
            onChanged: (v) => setState(() => _autoStartBreaks = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
