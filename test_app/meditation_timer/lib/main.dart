import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MeditationTimerApp());
}

// --- Data Models ---

class MeditationSession {
  final String id;
  final String name;
  final int durationMinutes;
  final String category;
  final DateTime completedAt;

  MeditationSession({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.category,
    required this.completedAt,
  });
}

class MeditationPreset {
  final String id;
  final String name;
  final int durationMinutes;
  final String category;
  final String description;

  MeditationPreset({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.category,
    required this.description,
  });
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<MeditationPreset> _presets = [
    MeditationPreset(id: '1', name: 'Morning Calm', durationMinutes: 5, category: 'Mindfulness', description: 'Start your day with clarity'),
    MeditationPreset(id: '2', name: 'Deep Focus', durationMinutes: 10, category: 'Focus', description: 'Sharpen your concentration'),
    MeditationPreset(id: '3', name: 'Sleep Well', durationMinutes: 15, category: 'Sleep', description: 'Drift off peacefully'),
    MeditationPreset(id: '4', name: 'Stress Relief', durationMinutes: 10, category: 'Relaxation', description: 'Release tension and worry'),
    MeditationPreset(id: '5', name: 'Body Scan', durationMinutes: 20, category: 'Mindfulness', description: 'Full body awareness practice'),
  ];

  final List<MeditationSession> _history = [
    MeditationSession(id: '1', name: 'Morning Calm', durationMinutes: 5, category: 'Mindfulness', completedAt: DateTime.now().subtract(const Duration(days: 1))),
    MeditationSession(id: '2', name: 'Deep Focus', durationMinutes: 10, category: 'Focus', completedAt: DateTime.now().subtract(const Duration(days: 2))),
    MeditationSession(id: '3', name: 'Sleep Well', durationMinutes: 15, category: 'Sleep', completedAt: DateTime.now().subtract(const Duration(days: 3))),
  ];

  bool _darkMode = false;
  bool _soundEnabled = true;
  int _dailyGoalMinutes = 15;

  List<MeditationPreset> get presets => List.unmodifiable(_presets);
  List<MeditationSession> get history => List.unmodifiable(_history);
  bool get darkMode => _darkMode;
  bool get soundEnabled => _soundEnabled;
  int get dailyGoalMinutes => _dailyGoalMinutes;

  int get totalMinutesToday {
    final today = DateTime.now();
    return _history
        .where((s) => s.completedAt.year == today.year && s.completedAt.month == today.month && s.completedAt.day == today.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get totalSessions => _history.length;
  int get totalMinutes => _history.fold(0, (sum, s) => sum + s.durationMinutes);
  int get currentStreak {
    int streak = 0;
    var day = DateTime.now();
    for (int i = 0; i < 30; i++) {
      if (_history.any((s) => s.completedAt.year == day.year && s.completedAt.month == day.month && s.completedAt.day == day.day)) {
        streak++;
      } else if (i > 0) {
        break;
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void addSession(MeditationSession session) {
    _history.insert(0, session);
    notifyListeners();
  }

  void addPreset(MeditationPreset preset) {
    _presets.add(preset);
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  void setDailyGoal(int minutes) {
    _dailyGoalMinutes = minutes;
    notifyListeners();
  }
}

// --- App ---

class MeditationTimerApp extends StatefulWidget {
  const MeditationTimerApp({super.key});

  @override
  State<MeditationTimerApp> createState() => _MeditationTimerAppState();
}

class _MeditationTimerAppState extends State<MeditationTimerApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meditation Timer',
      debugShowCheckedModeBanner: false,
      theme: _state.darkMode ? ThemeData.dark(useMaterial3: true) : ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: MainScreen(state: _state),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PresetsPage(state: widget.state),
      HistoryPage(state: widget.state),
      StatsPage(state: widget.state),
      SettingsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.self_improvement), label: 'Meditate'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- Presets Page ---

class PresetsPage extends StatelessWidget {
  final AppState state;
  const PresetsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditate')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.presets.length,
        itemBuilder: (context, index) {
          final preset = state.presets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(preset.name),
              subtitle: Text('${preset.durationMinutes} min · ${preset.category}'),
              trailing: Text(preset.description, style: Theme.of(context).textTheme.bodySmall),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TimerPage(state: state, preset: preset))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPresetDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Preset'),
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '10');
    String category = 'Mindfulness';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Preset Name')),
            const SizedBox(height: 12),
            TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (minutes)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Mindfulness', 'Focus', 'Sleep', 'Relaxation'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v ?? category,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                state.addPreset(MeditationPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  durationMinutes: int.tryParse(durationController.text) ?? 10,
                  category: category,
                  description: 'Custom preset',
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// --- Timer Page ---

class TimerPage extends StatefulWidget {
  final AppState state;
  final MeditationPreset preset;
  const TimerPage({super.key, required this.state, required this.preset});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.preset.durationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _isCompleted = true;
        });
        widget.state.addSession(MeditationSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: widget.preset.name,
          durationMinutes: widget.preset.durationMinutes,
          category: widget.preset.category,
          completedAt: DateTime.now(),
        ));
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.preset.durationMinutes * 60;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.preset.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.preset.category, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(_formatTime(_remainingSeconds), style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text('${widget.preset.durationMinutes} minute session', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 48),
            if (_isCompleted)
              Column(
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Session Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning)
                    FilledButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.replay),
                    label: const Text('Reset'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// --- History Page ---

class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: state.history.isEmpty
          ? const Center(child: Text('No sessions yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final session = state.history[index];
                final daysDiff = DateTime.now().difference(session.completedAt).inDays;
                final when = daysDiff == 0 ? 'Today' : daysDiff == 1 ? 'Yesterday' : '$daysDiff days ago';
                return ListTile(
                  leading: const Icon(Icons.self_improvement),
                  title: Text(session.name),
                  subtitle: Text('${session.durationMinutes} min · ${session.category}'),
                  trailing: Text(when),
                );
              },
            ),
    );
  }
}

// --- Stats Page ---

class StatsPage extends StatelessWidget {
  final AppState state;
  const StatsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final categories = <String, int>{};
    for (final s in state.history) {
      categories[s.category] = (categories[s.category] ?? 0) + s.durationMinutes;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _StatRow(label: 'Total Sessions', value: '${state.totalSessions}'),
                  _StatRow(label: 'Total Minutes', value: '${state.totalMinutes}'),
                  _StatRow(label: 'Current Streak', value: '${state.currentStreak} days'),
                  _StatRow(label: 'Daily Goal', value: '${state.dailyGoalMinutes} min'),
                  _StatRow(label: 'Today', value: '${state.totalMinutesToday} min'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('By Category', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...categories.entries.map((e) => _StatRow(label: e.key, value: '${e.value} min')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}

// --- Settings Page ---

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: state.darkMode,
            onChanged: (_) => state.toggleDarkMode(),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound on session end'),
            value: state.soundEnabled,
            onChanged: (_) => state.toggleSound(),
          ),
          ListTile(
            title: const Text('Daily Goal'),
            subtitle: Text('${state.dailyGoalMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGoalDialog(context),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Meditation Timer v1.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About'),
                content: const Text('Meditation Timer helps you build a daily meditation practice. Track sessions, view stats, and stay consistent.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final controller = TextEditingController(text: '${state.dailyGoalMinutes}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Minutes per day'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                state.setDailyGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
