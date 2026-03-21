import 'package:flutter/material.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────────────────

class Flashcard {
  final String question;
  final String answer;

  const Flashcard({required this.question, required this.answer});
}

class Deck {
  final String name;
  final List<Flashcard> cards;
  final int mastered;

  const Deck({required this.name, required this.cards, required this.mastered});

  int get totalCards => cards.length;
}

final List<Deck> decks = [
  Deck(
    name: 'Math',
    mastered: 3,
    cards: [
      const Flashcard(question: 'What is 7 times 8?', answer: '56'),
      const Flashcard(question: 'What is the square root of 144?', answer: '12'),
      const Flashcard(question: 'What is 15 percent of 200?', answer: '30'),
      const Flashcard(question: 'What is 2 to the power of 10?', answer: '1024'),
      const Flashcard(question: 'What is pi to 2 decimal places?', answer: '3.14'),
    ],
  ),
  Deck(
    name: 'Science',
    mastered: 5,
    cards: [
      const Flashcard(question: 'What is the chemical symbol for gold?', answer: 'Au'),
      const Flashcard(question: 'How many bones are in the adult human body?', answer: '206'),
      const Flashcard(question: 'What planet is closest to the Sun?', answer: 'Mercury'),
      const Flashcard(question: 'What is the speed of light in km per second?', answer: '299,792 km/s'),
      const Flashcard(question: 'What gas do plants absorb from the air?', answer: 'Carbon dioxide'),
    ],
  ),
  Deck(
    name: 'History',
    mastered: 1,
    cards: [
      const Flashcard(question: 'In what year did World War II end?', answer: '1945'),
      const Flashcard(question: 'Who was the first President of the United States?', answer: 'George Washington'),
      const Flashcard(question: 'What ancient wonder was in Alexandria?', answer: 'The Lighthouse of Alexandria'),
      const Flashcard(question: 'In what year did the Berlin Wall fall?', answer: '1989'),
      const Flashcard(question: 'Who wrote the Declaration of Independence?', answer: 'Thomas Jefferson'),
    ],
  ),
];

// ─── Settings Model ──────────────────────────────────────────────────────────

class AppSettings {
  bool shuffleCards;
  bool showProgress;
  String cardsPerSession; // '5', '10', 'All'

  AppSettings({
    this.shuffleCards = false,
    this.showProgress = true,
    this.cardsPerSession = '5',
  });
}

final AppSettings appSettings = AppSettings();

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return DeckCard(deck: deck);
        },
      ),
    );
  }
}

// ─── Deck Card ────────────────────────────────────────────────────────────────

class DeckCard extends StatelessWidget {
  final Deck deck;

  const DeckCard({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(deck: deck),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${deck.totalCards} cards',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${deck.mastered}/${deck.totalCards} mastered',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quiz Screen ─────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  final Deck deck;

  const QuizScreen({super.key, required this.deck});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Flashcard> _cards;
  int _currentIndex = 0;
  bool _answerVisible = false;
  int _gotItCount = 0;

  @override
  void initState() {
    super.initState();
    _initCards();
  }

  void _initCards() {
    _cards = List<Flashcard>.from(widget.deck.cards);
    if (appSettings.shuffleCards) {
      _cards.shuffle();
    }
    final limit = appSettings.cardsPerSession == 'All'
        ? _cards.length
        : int.tryParse(appSettings.cardsPerSession) ?? _cards.length;
    if (limit < _cards.length) {
      _cards = _cards.sublist(0, limit);
    }
  }

  Flashcard get _currentCard => _cards[_currentIndex];
  bool get _isLast => _currentIndex == _cards.length - 1;

  void _showAnswer() {
    setState(() {
      _answerVisible = true;
    });
  }

  void _nextCard(bool gotIt) {
    final newScore = gotIt ? _gotItCount + 1 : _gotItCount;
    if (_isLast) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            deck: widget.deck,
            totalCards: _cards.length,
            score: newScore,
          ),
        ),
      );
    } else {
      setState(() {
        if (gotIt) _gotItCount++;
        _currentIndex++;
        _answerVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_currentIndex + 1) / _cards.length;
    final cardNumber = _currentIndex + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        bottom: appSettings.showProgress
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: colorScheme.primary,
                ),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card counter
            Text(
              'Card $cardNumber of ${_cards.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Flashcard
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Question',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentCard.question,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (_answerVisible) ...[
                        const SizedBox(height: 32),
                        Divider(color: colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Answer',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.secondary,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentCard.answer,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            if (!_answerVisible)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showAnswer,
                  child: const Text('Show Answer'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _nextCard(true),
                      child: const Text('Got It'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _nextCard(false),
                      child: const Text('Need Practice'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Results Screen ───────────────────────────────────────────────────────────

class ResultsScreen extends StatelessWidget {
  final Deck deck;
  final int totalCards;
  final int score;

  const ResultsScreen({
    super.key,
    required this.deck,
    required this.totalCards,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Score: $score/$totalCards',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(deck: deck),
                      ),
                    );
                  },
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Decks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Shuffle Cards'),
            value: appSettings.shuffleCards,
            onChanged: (val) {
              setState(() {
                appSettings.shuffleCards = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Show Progress'),
            value: appSettings.showProgress,
            onChanged: (val) {
              setState(() {
                appSettings.showProgress = val;
              });
            },
          ),
          ListTile(
            title: const Text('Cards Per Session'),
            trailing: DropdownButton<String>(
              value: appSettings.cardsPerSession,
              items: const [
                DropdownMenuItem(value: '5', child: Text('5')),
                DropdownMenuItem(value: '10', child: Text('10')),
                DropdownMenuItem(value: 'All', child: Text('All')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    appSettings.cardsPerSession = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
