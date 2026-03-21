import 'package:flutter/material.dart';

void main() {
  runApp(const LanguageCardsApp());
}

// --- Data Models ---

enum DeckLevel { beginner, intermediate, advanced }

class FlashCard {
  final String front;
  final String back;
  bool mastered;

  FlashCard({required this.front, required this.back, this.mastered = false});
}

class Deck {
  String language;
  DeckLevel level;
  List<FlashCard> cards;

  Deck({required this.language, required this.level, List<FlashCard>? cards})
      : cards = cards ?? [];

  int get masteredCount => cards.where((c) => c.mastered).length;
  double get masteryPercent =>
      cards.isEmpty ? 0 : (masteredCount / cards.length) * 100;

  String get levelLabel {
    switch (level) {
      case DeckLevel.beginner:
        return 'Beginner';
      case DeckLevel.intermediate:
        return 'Intermediate';
      case DeckLevel.advanced:
        return 'Advanced';
    }
  }
}

// --- Global State ---

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  int totalStudied = 12;
  int totalMastered = 6;
  int dailyStreak = 3;
  int correctAnswers = 18;
  int totalAnswers = 30;

  final List<Deck> decks = [
    Deck(
      language: 'Spanish',
      level: DeckLevel.beginner,
      cards: [
        FlashCard(front: 'hola', back: 'hello', mastered: true),
        FlashCard(front: 'gato', back: 'cat', mastered: true),
        FlashCard(front: 'perro', back: 'dog', mastered: true),
        FlashCard(front: 'casa', back: 'house'),
        FlashCard(front: 'libro', back: 'book'),
        FlashCard(front: 'agua', back: 'water'),
      ],
    ),
    Deck(
      language: 'French',
      level: DeckLevel.intermediate,
      cards: [
        FlashCard(front: 'bonjour', back: 'hello', mastered: true),
        FlashCard(front: 'chat', back: 'cat', mastered: true),
        FlashCard(front: 'chien', back: 'dog', mastered: true),
        FlashCard(front: 'maison', back: 'house'),
        FlashCard(front: 'merci', back: 'thanks'),
      ],
    ),
    Deck(
      language: 'Japanese',
      level: DeckLevel.beginner,
      cards: [
        FlashCard(front: 'こんにちは', back: 'hello', mastered: true),
        FlashCard(front: 'ねこ', back: 'cat'),
        FlashCard(front: 'いぬ', back: 'dog'),
        FlashCard(front: 'ありがとう', back: 'thanks'),
      ],
    ),
  ];
}

// --- App ---

class LanguageCardsApp extends StatelessWidget {
  const LanguageCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final decks = AppState().decks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Cards'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'progress') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProgressScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'progress', child: Text('Progress')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(deck.language),
              subtitle: Text(
                  '${deck.cards.length} cards - ${deck.masteryPercent.round()}% mastery'),
              trailing: Chip(label: Text(deck.levelLabel)),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DeckScreen(deck: deck)),
                );
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDeckScreen()),
          );
          setState(() {});
        },
        child: const Text('Add Deck'),
      ),
    );
  }
}

// --- Deck Screen ---

class DeckScreen extends StatefulWidget {
  final Deck deck;
  const DeckScreen({super.key, required this.deck});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.language),
      ),
      body: ListView.builder(
        itemCount: deck.cards.length,
        itemBuilder: (context, index) {
          final card = deck.cards[index];
          return ListTile(
            title: Text(card.front),
            subtitle: Text(card.back),
            trailing: Icon(
              card.mastered ? Icons.check_circle : Icons.circle_outlined,
              color: card.mastered ? Colors.green : Colors.grey,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StudyCardScreen(card: card)),
              );
              setState(() {});
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddCardScreen(deck: deck)),
          );
          setState(() {});
        },
        child: const Text('Add Card'),
      ),
    );
  }
}

// --- Study Card Screen ---

class StudyCardScreen extends StatefulWidget {
  final FlashCard card;
  const StudyCardScreen({super.key, required this.card});

  @override
  State<StudyCardScreen> createState() => _StudyCardScreenState();
}

class _StudyCardScreenState extends State<StudyCardScreen> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _flipped ? card.back : card.front,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_flipped)
                ElevatedButton(
                  onPressed: () => setState(() => _flipped = true),
                  child: const Text('Flip'),
                )
              else ...[
                ElevatedButton(
                  onPressed: () {
                    card.mastered = true;
                    AppState().totalStudied++;
                    AppState().totalMastered++;
                    AppState().correctAnswers++;
                    AppState().totalAnswers++;
                    Navigator.pop(context);
                  },
                  child: const Text('Got It'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    card.mastered = false;
                    AppState().totalStudied++;
                    AppState().totalAnswers++;
                    Navigator.pop(context);
                  },
                  child: const Text('Review Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Add Deck Screen ---

class AddDeckScreen extends StatefulWidget {
  const AddDeckScreen({super.key});

  @override
  State<AddDeckScreen> createState() => _AddDeckScreenState();
}

class _AddDeckScreenState extends State<AddDeckScreen> {
  final _nameController = TextEditingController();
  DeckLevel _selectedLevel = DeckLevel.beginner;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Deck'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Language Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<DeckLevel>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: DeckLevel.beginner, child: Text('Beginner')),
                DropdownMenuItem(
                    value: DeckLevel.intermediate,
                    child: Text('Intermediate')),
                DropdownMenuItem(
                    value: DeckLevel.advanced, child: Text('Advanced')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedLevel = value);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  AppState()
                      .decks
                      .add(Deck(language: name, level: _selectedLevel));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Deck'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Card Screen ---

class AddCardScreen extends StatefulWidget {
  final Deck deck;
  const AddCardScreen({super.key, required this.deck});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _frontController,
              decoration: const InputDecoration(
                labelText: 'Front (Word)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _backController,
              decoration: const InputDecoration(
                labelText: 'Back (Translation)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final front = _frontController.text.trim();
                final back = _backController.text.trim();
                if (front.isNotEmpty && back.isNotEmpty) {
                  widget.deck.cards
                      .add(FlashCard(front: front, back: back));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Card'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Progress Screen ---

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final accuracy = state.totalAnswers > 0
        ? ((state.correctAnswers / state.totalAnswers) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatTile(label: 'Total Cards Studied', value: '${state.totalStudied}'),
            _StatTile(label: 'Cards Mastered', value: '${state.totalMastered}'),
            _StatTile(label: 'Daily Streak', value: '${state.dailyStreak} days'),
            _StatTile(label: 'Accuracy', value: '$accuracy%'),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
