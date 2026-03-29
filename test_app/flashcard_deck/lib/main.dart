import 'package:flutter/material.dart';

void main() {
  runApp(const FlashcardDeckApp());
}

// --- Data ---

class Flashcard {
  final String id;
  final String front;
  final String back;
  bool isLearned;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.isLearned = false,
  });
}

class Deck {
  final String id;
  final String name;
  final String category;
  final Color color;
  final List<Flashcard> cards;

  Deck({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.cards,
  });

  int get learnedCount => cards.where((c) => c.isLearned).length;
}

// --- State ---

class DeckState extends ChangeNotifier {
  final List<Deck> _decks = [
    Deck(
      id: '1', name: 'Spanish Basics', category: 'Language', color: Colors.orange,
      cards: [
        Flashcard(id: 'c1', front: 'Hello', back: 'Hola'),
        Flashcard(id: 'c2', front: 'Goodbye', back: 'Adiós'),
        Flashcard(id: 'c3', front: 'Thank you', back: 'Gracias'),
        Flashcard(id: 'c4', front: 'Please', back: 'Por favor'),
      ],
    ),
    Deck(
      id: '2', name: 'World Capitals', category: 'Geography', color: Colors.blue,
      cards: [
        Flashcard(id: 'c5', front: 'France', back: 'Paris'),
        Flashcard(id: 'c6', front: 'Japan', back: 'Tokyo'),
        Flashcard(id: 'c7', front: 'Australia', back: 'Canberra'),
      ],
    ),
    Deck(
      id: '3', name: 'Math Formulas', category: 'Science', color: Colors.green,
      cards: [
        Flashcard(id: 'c8', front: 'Area of Circle', back: 'π × r²'),
        Flashcard(id: 'c9', front: 'Pythagorean', back: 'a² + b² = c²'),
      ],
    ),
  ];

  List<Deck> get decks => _decks;

  void addDeck(String name, String category) {
    _decks.add(Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      color: [Colors.purple, Colors.teal, Colors.pink, Colors.indigo][_decks.length % 4],
      cards: [],
    ));
    notifyListeners();
  }

  void addCard(String deckId, String front, String back) {
    final deck = _decks.firstWhere((d) => d.id == deckId);
    deck.cards.add(Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      front: front,
      back: back,
    ));
    notifyListeners();
  }

  void toggleLearned(String deckId, String cardId) {
    final deck = _decks.firstWhere((d) => d.id == deckId);
    final card = deck.cards.firstWhere((c) => c.id == cardId);
    card.isLearned = !card.isLearned;
    notifyListeners();
  }

  void resetDeck(String deckId) {
    final deck = _decks.firstWhere((d) => d.id == deckId);
    for (var c in deck.cards) { c.isLearned = false; }
    notifyListeners();
  }

  void deleteDeck(String deckId) {
    _decks.removeWhere((d) => d.id == deckId);
    notifyListeners();
  }
}

// --- App ---

class FlashcardDeckApp extends StatelessWidget {
  const FlashcardDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashcardDeck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const DeckListScreen(),
    );
  }
}

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});
  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _state = DeckState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Decks'),
            actions: [
              IconButton(
                tooltip: 'Study Stats',
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showStatsDialog(),
              ),
            ],
          ),
          body: _state.decks.isEmpty
              ? const Center(child: Text('No decks yet.\nTap + to create one.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _state.decks.length,
                  itemBuilder: (context, index) {
                    final deck = _state.decks[index];
                    return Semantics(
                      button: true,
                      label: deck.name,
                      excludeSemantics: true,
                      child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _openDeck(deck),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: deck.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.style, color: deck.color),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deck.name, style: Theme.of(context).textTheme.titleMedium),
                                    Text('${deck.category} • ${deck.cards.length} cards • ${deck.learnedCount} learned',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              if (deck.cards.isNotEmpty)
                                CircularProgressIndicator(
                                  value: deck.learnedCount / deck.cards.length,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  color: deck.color,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ));
                  },
                ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add Deck',
            onPressed: () => _showAddDeckDialog(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showStatsDialog() {
    final totalCards = _state.decks.fold<int>(0, (s, d) => s + d.cards.length);
    final learnedCards = _state.decks.fold<int>(0, (s, d) => s + d.learnedCount);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Study Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total decks: ${_state.decks.length}'),
            Text('Total cards: $totalCards'),
            Text('Cards learned: $learnedCards'),
            if (totalCards > 0)
              Text('Progress: ${(learnedCards / totalCards * 100).round()}%'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAddDeckDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Deck Name')),
            const SizedBox(height: 12),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                _state.addDeck(nameCtrl.text, catCtrl.text.isEmpty ? 'General' : catCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openDeck(Deck deck) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DeckDetailScreen(state: _state, deckId: deck.id),
    ));
  }
}

// --- Deck Detail ---

class DeckDetailScreen extends StatefulWidget {
  final DeckState state;
  final String deckId;

  const DeckDetailScreen({super.key, required this.state, required this.deckId});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  bool _studyMode = false;
  int _currentCardIndex = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final deck = widget.state.decks.firstWhere((d) => d.id == widget.deckId);
        return Scaffold(
          appBar: AppBar(
            title: Text(deck.name),
            actions: [
              if (deck.cards.isNotEmpty && !_studyMode)
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Study'),
                  onPressed: () => setState(() {
                    _studyMode = true;
                    _currentCardIndex = 0;
                    _showBack = false;
                  }),
                ),
              if (!_studyMode)
                PopupMenuButton(
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'reset', child: Text('Reset Progress')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Deck')),
                  ],
                  onSelected: (v) {
                    if (v == 'reset') widget.state.resetDeck(deck.id);
                    if (v == 'delete') { widget.state.deleteDeck(deck.id); Navigator.pop(context); }
                  },
                ),
            ],
          ),
          body: _studyMode ? _buildStudyMode(deck) : _buildCardList(deck),
          floatingActionButton: _studyMode ? null : FloatingActionButton(
            tooltip: 'Add Card',
            onPressed: () => _showAddCardDialog(deck),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildCardList(Deck deck) {
    if (deck.cards.isEmpty) {
      return const Center(child: Text('No cards yet.\nTap + to add one.'));
    }
    return ListView.builder(
      itemCount: deck.cards.length,
      itemBuilder: (context, index) {
        final card = deck.cards[index];
        return ListTile(
          leading: Icon(
            card.isLearned ? Icons.check_circle : Icons.circle_outlined,
            color: card.isLearned ? Colors.green : Colors.grey,
          ),
          title: Text(card.front),
          subtitle: Text(card.back),
          onTap: () => widget.state.toggleLearned(deck.id, card.id),
        );
      },
    );
  }

  Widget _buildStudyMode(Deck deck) {
    if (_currentCardIndex >= deck.cards.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text('Session Complete!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('${deck.learnedCount}/${deck.cards.length} cards learned'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() { _studyMode = false; }),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    final card = deck.cards[_currentCardIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Card ${_currentCardIndex + 1} of ${deck.cards.length}',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_currentCardIndex + 1) / deck.cards.length),
          const SizedBox(height: 32),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _showBack = !_showBack; }),
              child: Card(
                elevation: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showBack ? card.back : card.front,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showBack ? 'Answer' : 'Tap to reveal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_showBack) Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Still Learning'),
                onPressed: () => setState(() {
                  _currentCardIndex++;
                  _showBack = false;
                }),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Got It'),
                onPressed: () {
                  if (!card.isLearned) {
                    widget.state.toggleLearned(deck.id, card.id);
                  }
                  setState(() {
                    _currentCardIndex++;
                    _showBack = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(Deck deck) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Front (Question)')),
            const SizedBox(height: 12),
            TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Back (Answer)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (frontCtrl.text.isNotEmpty && backCtrl.text.isNotEmpty) {
                widget.state.addCard(deck.id, frontCtrl.text, backCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
