import 'package:flutter/material.dart';

void main() {
  runApp(const StudyPlannerApp());
}

enum Difficulty { Easy, Medium, Hard }

class StudySession {
  String subject;
  String topic;
  DateTime date;
  int duration;
  Difficulty difficulty;
  String notes;
  bool completed;

  StudySession({
    required this.subject,
    required this.topic,
    required this.date,
    required this.duration,
    required this.difficulty,
    this.notes = '',
    this.completed = false,
  });
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        colorSchemeSeed: Colors.purple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<StudySession> _sessions = [
    StudySession(
      subject: 'Math',
      topic: 'Linear Algebra',
      date: DateTime(2026, 3, 18),
      duration: 45,
      difficulty: Difficulty.Hard,
      notes: 'Focus on matrix transformations and eigenvalues.',
      completed: true,
    ),
    StudySession(
      subject: 'Science',
      topic: 'Organic Chemistry',
      date: DateTime(2026, 3, 19),
      duration: 60,
      difficulty: Difficulty.Medium,
      notes: 'Review functional groups and naming conventions.',
      completed: true,
    ),
    StudySession(
      subject: 'English',
      topic: 'Essay Writing',
      date: DateTime(2026, 3, 20),
      duration: 30,
      difficulty: Difficulty.Easy,
      notes: 'Practice thesis statement construction.',
      completed: false,
    ),
    StudySession(
      subject: 'History',
      topic: 'World War II',
      date: DateTime(2026, 3, 21),
      duration: 50,
      difficulty: Difficulty.Medium,
      notes: 'Study the Pacific theater and key battles.',
      completed: true,
    ),
    StudySession(
      subject: 'Art',
      topic: 'Renaissance Painting',
      date: DateTime(2026, 3, 22),
      duration: 40,
      difficulty: Difficulty.Easy,
      notes: 'Analyze works by Leonardo and Michelangelo.',
      completed: false,
    ),
    StudySession(
      subject: 'Math',
      topic: 'Calculus Integration',
      date: DateTime(2026, 3, 23),
      duration: 55,
      difficulty: Difficulty.Hard,
      notes: 'Practice integration by parts and substitution.',
      completed: false,
    ),
  ];

  String _selectedSubject = 'All';
  final List<String> _subjects = [
    'All',
    'Math',
    'Science',
    'English',
    'History',
    'Art',
  ];

  List<StudySession> get _filteredSessions {
    if (_selectedSubject == 'All') return _sessions;
    return _sessions.where((s) => s.subject == _selectedSubject).toList();
  }

  String _formatDate(DateTime d) {
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Progress') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressScreen(sessions: _sessions),
                  ),
                );
              } else if (value == 'Subjects') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectsScreen(sessions: _sessions),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Progress', child: Text('Progress')),
              const PopupMenuItem(value: 'Subjects', child: Text('Subjects')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: _subjects.map((subject) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(subject),
                    selected: _selectedSubject == subject,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = subject;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filteredSessions.isEmpty
                ? const Center(child: Text('No sessions found.'))
                : ListView.builder(
                    itemCount: _filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = _filteredSessions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(session.topic),
                          subtitle: Text(
                            '${session.subject} - ${_formatDate(session.date)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${session.duration} min'),
                              if (session.completed)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check_circle,
                                      color: Colors.green),
                                ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  session: session,
                                  onDelete: () {
                                    setState(() {
                                      _sessions.remove(session);
                                    });
                                  },
                                  onToggle: () {
                                    setState(() {
                                      session.completed = !session.completed;
                                    });
                                  },
                                ),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<StudySession>(
            context,
            MaterialPageRoute(builder: (_) => const AddSessionScreen()),
          );
          if (result != null) {
            setState(() {
              _sessions.add(result);
            });
          }
        },
        label: const Text('Add Session'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final StudySession session;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const DetailScreen({
    super.key,
    required this.session,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _formatDate(DateTime d) {
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.topic,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Subject: ${session.subject}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(session.date)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${session.duration} minutes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Difficulty: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(label: Text(session.difficulty.name)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Notes:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              session.notes.isEmpty ? 'No notes.' : session.notes,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              session.completed
                  ? 'Status: Completed'
                  : 'Status: Not Completed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: session.completed ? Colors.green : Colors.orange,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onToggle();
                  setState(() {});
                },
                child: Text(
                  session.completed ? 'Mark Incomplete' : 'Mark Complete',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
                child: const Text('Delete Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  String _subject = 'Math';
  Difficulty _difficulty = Difficulty.Medium;

  final List<String> _subjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Art',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _subject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: _subjects.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _subject = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Difficulty>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: Difficulty.values.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _difficulty = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final session = StudySession(
                      subject: _subject,
                      topic: _topicController.text,
                      date: DateTime.now(),
                      duration: int.parse(_durationController.text),
                      difficulty: _difficulty,
                      notes: _notesController.text,
                    );
                    Navigator.pop(context, session);
                  }
                },
                child: const Text('Add Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  final List<StudySession> sessions;

  const ProgressScreen({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final total = sessions.length;
    final completed = sessions.where((s) => s.completed).length;
    final totalTime = sessions.fold<int>(0, (sum, s) => sum + s.duration);
    final avgDuration = total > 0 ? (totalTime / total).round() : 0;

    final easyCount =
        sessions.where((s) => s.difficulty == Difficulty.Easy).length;
    final mediumCount =
        sessions.where((s) => s.difficulty == Difficulty.Medium).length;
    final hardCount =
        sessions.where((s) => s.difficulty == Difficulty.Hard).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Total Sessions'),
              trailing: Text('$total'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Completed'),
              trailing: Text('$completed'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Total Study Time'),
              trailing: Text('$totalTime min'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Average Duration'),
              trailing: Text('$avgDuration min'),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Difficulty Breakdown',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Easy'),
              trailing: Text('$easyCount'),
            ),
            ListTile(
              title: const Text('Medium'),
              trailing: Text('$mediumCount'),
            ),
            ListTile(
              title: const Text('Hard'),
              trailing: Text('$hardCount'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectsScreen extends StatelessWidget {
  final List<StudySession> sessions;

  const SubjectsScreen({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final subjects = <String>{};
    for (final s in sessions) {
      subjects.add(s.subject);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: ListView(
        children: subjects.map((subject) {
          final subjectSessions =
              sessions.where((s) => s.subject == subject).toList();
          final count = subjectSessions.length;
          final totalTime =
              subjectSessions.fold<int>(0, (sum, s) => sum + s.duration);
          return ListTile(
            title: Text(subject),
            subtitle: Text('$count sessions'),
            trailing: Text('$totalTime min'),
          );
        }).toList(),
      ),
    );
  }
}
