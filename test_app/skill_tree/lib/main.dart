import 'package:flutter/material.dart';

void main() {
  runApp(const SkillTreeApp());
}

class Achievement {
  final String name;
  final String description;
  bool unlocked;

  Achievement({
    required this.name,
    required this.description,
    required this.unlocked,
  });
}

class Skill {
  String name;
  String description;
  String category;
  int level;
  int xp;
  final int xpPerLevel;
  List<String> milestones;

  Skill({
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    required this.xp,
    this.xpPerLevel = 1000,
    required this.milestones,
  });
}

class AppState extends ChangeNotifier {
  final List<String> categories = [
    'Programming',
    'Design',
    'Languages',
    'Music',
  ];

  final List<Skill> skills = [
    Skill(
      name: 'Dart',
      description: 'A client-optimized language for fast apps on any platform.',
      category: 'Programming',
      level: 7,
      xp: 750,
      milestones: ['Hello World', 'Null Safety', 'Async/Await', 'Isolates'],
    ),
    Skill(
      name: 'Python',
      description: 'A versatile language for scripting, data science, and web.',
      category: 'Programming',
      level: 5,
      xp: 400,
      milestones: ['Variables', 'Functions', 'Classes', 'Decorators'],
    ),
    Skill(
      name: 'SQL',
      description: 'Query language for managing relational databases.',
      category: 'Programming',
      level: 3,
      xp: 200,
      milestones: ['SELECT', 'JOIN', 'Subqueries', 'Indexes'],
    ),
    Skill(
      name: 'Figma',
      description: 'Collaborative interface design tool.',
      category: 'Design',
      level: 4,
      xp: 350,
      milestones: ['Frames', 'Components', 'Auto Layout', 'Prototyping'],
    ),
    Skill(
      name: 'Typography',
      description: 'The art and technique of arranging type.',
      category: 'Design',
      level: 2,
      xp: 100,
      milestones: ['Font Pairing', 'Hierarchy', 'Spacing', 'Readability'],
    ),
    Skill(
      name: 'Japanese',
      description: 'East Asian language with three writing systems.',
      category: 'Languages',
      level: 3,
      xp: 250,
      milestones: ['Hiragana', 'Katakana', 'Kanji Basics', 'Grammar'],
    ),
    Skill(
      name: 'Spanish',
      description: 'A Romance language spoken worldwide.',
      category: 'Languages',
      level: 6,
      xp: 600,
      milestones: ['Greetings', 'Conjugation', 'Subjunctive', 'Fluency'],
    ),
    Skill(
      name: 'Guitar',
      description: 'String instrument played by strumming or plucking.',
      category: 'Music',
      level: 4,
      xp: 400,
      milestones: ['Open Chords', 'Barre Chords', 'Scales', 'Fingerpicking'],
    ),
    Skill(
      name: 'Piano',
      description: 'Keyboard instrument with wide range and versatility.',
      category: 'Music',
      level: 2,
      xp: 150,
      milestones: ['Scales', 'Chords', 'Sight Reading', 'Improvisation'],
    ),
  ];

  final List<Achievement> achievements = [
    Achievement(
      name: 'First Steps',
      description: 'Practice any skill for the first time.',
      unlocked: true,
    ),
    Achievement(
      name: 'Level 5 Club',
      description: 'Reach level 5 in any skill.',
      unlocked: true,
    ),
    Achievement(
      name: 'Polymath',
      description: 'Reach level 3 in 5 different skills.',
      unlocked: false,
    ),
    Achievement(
      name: 'Master',
      description: 'Reach level 10 in any skill.',
      unlocked: false,
    ),
  ];

  List<Skill> skillsForCategory(String category) {
    return skills.where((s) => s.category == category).toList();
  }

  void addSkill(Skill skill) {
    skills.add(skill);
    notifyListeners();
  }

  void practiceSkill(Skill skill) {
    skill.xp += 50;
    if (skill.xp >= skill.xpPerLevel) {
      skill.xp -= skill.xpPerLevel;
      skill.level += 1;
    }
    notifyListeners();
  }
}

class SkillTreeApp extends StatelessWidget {
  const SkillTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Tree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'achievements') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AchievementsScreen(achievements: _state.achievements),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'achievements',
                child: Text('Achievements'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: _state.categories.map((category) {
          final categorySkills = _state.skillsForCategory(category);
          return ExpansionTile(
            title: Text(category),
            children: categorySkills.map((skill) {
              return ListTile(
                title: Text(skill.name),
                subtitle: Text(
                    'Level ${skill.level} - ${skill.xp}/${skill.xpPerLevel} XP'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SkillDetailScreen(
                        skill: skill,
                        state: _state,
                      ),
                    ),
                  );
                  setState(() {});
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSkillScreen(state: _state),
            ),
          );
          setState(() {});
        },
        child: const Text('Add Skill'),
      ),
    );
  }
}

class SkillDetailScreen extends StatefulWidget {
  final Skill skill;
  final AppState state;

  const SkillDetailScreen({
    super.key,
    required this.skill,
    required this.state,
  });

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    return Scaffold(
      appBar: AppBar(
        title: Text(skill.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(skill.description),
            const SizedBox(height: 16),
            Text('Level ${skill.level}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${skill.xp}/${skill.xpPerLevel} XP',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: skill.xp / skill.xpPerLevel,
            ),
            const SizedBox(height: 24),
            Text('Milestones',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...skill.milestones.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(m),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.state.practiceSkill(skill);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+50 XP gained!')),
                    );
                  },
                  child: const Text('Practice'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // Edit functionality placeholder
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddSkillScreen extends StatefulWidget {
  final AppState state;

  const AddSkillScreen({super.key, required this.state});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Programming';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Skill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.state.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.state.addSkill(Skill(
                    name: _nameController.text,
                    description: _descController.text,
                    category: _selectedCategory,
                    level: 1,
                    xp: 0,
                    milestones: ['Getting Started'],
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Skill'),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsScreen({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: ListView.builder(
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index];
          return ListTile(
            leading: Icon(
              a.unlocked ? Icons.emoji_events : Icons.lock,
              color: a.unlocked ? Colors.amber : Colors.grey,
            ),
            title: Text(a.name),
            subtitle: Text(a.description),
            trailing: Text(a.unlocked ? 'Unlocked' : 'Locked'),
          );
        },
      ),
    );
  }
}
