import 'package:flutter/material.dart';

void main() {
  runApp(const PollBoothApp());
}

// --- Data Models ---

class PollOption {
  final String id;
  final String text;
  int votes;

  PollOption({required this.id, required this.text, this.votes = 0});
}

class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final String category;
  final bool isActive;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.category,
    this.isActive = true,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);

  double percentFor(PollOption o) =>
      totalVotes == 0 ? 0.0 : (o.votes / totalVotes) * 100;
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<Poll> _polls = [
    Poll(
      id: '1',
      question: 'Best programming language?',
      category: 'Technology',
      options: [
        PollOption(id: '1a', text: 'Dart', votes: 42),
        PollOption(id: '1b', text: 'Python', votes: 38),
        PollOption(id: '1c', text: 'Rust', votes: 29),
        PollOption(id: '1d', text: 'TypeScript', votes: 35),
      ],
    ),
    Poll(
      id: '2',
      question: 'Favorite season?',
      category: 'Lifestyle',
      options: [
        PollOption(id: '2a', text: 'Spring', votes: 25),
        PollOption(id: '2b', text: 'Summer', votes: 40),
        PollOption(id: '2c', text: 'Autumn', votes: 30),
        PollOption(id: '2d', text: 'Winter', votes: 18),
      ],
    ),
    Poll(
      id: '3',
      question: 'Best coffee type?',
      category: 'Food',
      options: [
        PollOption(id: '3a', text: 'Espresso', votes: 33),
        PollOption(id: '3b', text: 'Latte', votes: 28),
        PollOption(id: '3c', text: 'Cappuccino', votes: 22),
        PollOption(id: '3d', text: 'Cold Brew', votes: 19),
      ],
    ),
    Poll(
      id: '4',
      question: 'Remote or Office?',
      category: 'Work',
      options: [
        PollOption(id: '4a', text: 'Fully Remote', votes: 55),
        PollOption(id: '4b', text: 'Hybrid', votes: 30),
        PollOption(id: '4c', text: 'Office', votes: 12),
      ],
    ),
  ];

  int _selectedTab = 0;
  String _filterCategory = 'All';
  final Set<String> _votedPolls = {};

  List<Poll> get polls => _filterCategory == 'All'
      ? List.unmodifiable(_polls)
      : _polls.where((p) => p.category == _filterCategory).toList();
  List<Poll> get allPolls => List.unmodifiable(_polls);
  int get selectedTab => _selectedTab;
  String get filterCategory => _filterCategory;
  Set<String> get votedPolls => _votedPolls;

  List<String> get categories =>
      ['All', ..._polls.map((p) => p.category).toSet().toList()..sort()];

  int get totalPolls => _polls.length;
  int get totalVotes => _polls.fold(0, (s, p) => s + p.totalVotes);
  int get activePolls => _polls.where((p) => p.isActive).length;

  void setTab(int t) { _selectedTab = t; notifyListeners(); }
  void setFilter(String c) { _filterCategory = c; notifyListeners(); }

  void vote(String pollId, String optionId) {
    if (_votedPolls.contains(pollId)) return;
    final poll = _polls.firstWhere((p) => p.id == pollId);
    final option = poll.options.firstWhere((o) => o.id == optionId);
    option.votes++;
    _votedPolls.add(pollId);
    notifyListeners();
  }

  void addPoll(String question, String category, List<String> optionTexts) {
    final id = '${_polls.length + 1}';
    _polls.insert(0, Poll(
      id: id,
      question: question,
      category: category,
      options: optionTexts.asMap().entries
          .map((e) => PollOption(id: '${id}_${e.key}', text: e.value))
          .toList(),
    ));
    notifyListeners();
  }
}

// --- App ---

class PollBoothApp extends StatefulWidget {
  const PollBoothApp({super.key});

  @override
  State<PollBoothApp> createState() => _PollBoothAppState();
}

class _PollBoothAppState extends State<PollBoothApp> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => MaterialApp(
        title: 'PollBooth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: MainScreen(state: _state),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final screens = [
      PollListScreen(state: state),
      StatsScreen(state: state),
      CreatePollScreen(state: state),
    ];

    return Scaffold(
      body: screens[state.selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTab,
        onDestinationSelected: state.setTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.poll), label: 'Polls'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Create'),
        ],
      ),
    );
  }
}

// --- Polls List ---

class PollListScreen extends StatelessWidget {
  final AppState state;
  const PollListScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final polls = state.polls;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll Booth'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: state.setFilter,
            itemBuilder: (_) => state.categories
                .map((c) => PopupMenuItem(value: c, child: Text(c)))
                .toList(),
          ),
        ],
      ),
      body: polls.isEmpty
          ? const Center(child: Text('No polls found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              itemBuilder: (context, i) => PollCard(
                poll: polls[i],
                state: state,
              ),
            ),
    );
  }
}

class PollCard extends StatelessWidget {
  final Poll poll;
  final AppState state;
  const PollCard({super.key, required this.poll, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasVoted = state.votedPolls.contains(poll.id);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(poll.category,
                      style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
                ),
                const Spacer(),
                Text('${poll.totalVotes} votes',
                    style: TextStyle(color: cs.outline, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(poll.question,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...poll.options.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: hasVoted
                  ? _ResultBar(poll: poll, option: o)
                  : OutlinedButton(
                      onPressed: () => state.vote(poll.id, o.id),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text(o.text),
                    ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final Poll poll;
  final PollOption option;
  const _ResultBar({required this.poll, required this.option});

  @override
  Widget build(BuildContext context) {
    final pct = poll.percentFor(option);
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: pct / 100,
            child: Container(
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: Text(option.text)),
                Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Stats Screen ---

class StatsScreen extends StatelessWidget {
  final AppState state;
  const StatsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Find top voted option across all polls
    PollOption? topOption;
    String topPollQ = '';
    for (final p in state.allPolls) {
      for (final o in p.options) {
        if (topOption == null || o.votes > topOption.votes) {
          topOption = o;
          topPollQ = p.question;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            icon: Icons.poll,
            title: 'Total Polls',
            value: '${state.totalPolls}',
            color: cs.primary,
          ),
          _StatCard(
            icon: Icons.how_to_vote,
            title: 'Total Votes',
            value: '${state.totalVotes}',
            color: cs.tertiary,
          ),
          _StatCard(
            icon: Icons.check_circle,
            title: 'Active Polls',
            value: '${state.activePolls}',
            color: cs.secondary,
          ),
          _StatCard(
            icon: Icons.star,
            title: 'Most Popular',
            value: topOption?.text ?? 'N/A',
            subtitle: topPollQ,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text('Votes by Category',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...state.categories.where((c) => c != 'All').map((cat) {
            final catPolls =
                state.allPolls.where((p) => p.category == cat).toList();
            final catVotes =
                catPolls.fold(0, (s, p) => s + p.totalVotes);
            return ListTile(
              leading: const Icon(Icons.category),
              title: Text(cat),
              trailing: Text('$catVotes votes',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!, maxLines: 1) : null,
        trailing:
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- Create Poll Screen ---

class CreatePollScreen extends StatefulWidget {
  final AppState state;
  const CreatePollScreen({super.key, required this.state});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionCtrl = TextEditingController();
  final _option1Ctrl = TextEditingController();
  final _option2Ctrl = TextEditingController();
  final _option3Ctrl = TextEditingController();
  String _category = 'Technology';

  @override
  void dispose() {
    _questionCtrl.dispose();
    _option1Ctrl.dispose();
    _option2Ctrl.dispose();
    _option3Ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _questionCtrl.text.trim();
    final opts = [
      _option1Ctrl.text.trim(),
      _option2Ctrl.text.trim(),
      _option3Ctrl.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    if (q.isEmpty || opts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill question and at least 2 options')),
      );
      return;
    }

    widget.state.addPoll(q, _category, opts);
    _questionCtrl.clear();
    _option1Ctrl.clear();
    _option2Ctrl.clear();
    _option3Ctrl.clear();
    widget.state.setTab(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll created!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Poll')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _questionCtrl,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'What do you want to ask?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ['Technology', 'Lifestyle', 'Food', 'Work', 'Sports', 'Entertainment']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _option1Ctrl,
            decoration: const InputDecoration(
              labelText: 'Option 1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _option2Ctrl,
            decoration: const InputDecoration(
              labelText: 'Option 2',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _option3Ctrl,
            decoration: const InputDecoration(
              labelText: 'Option 3 (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: const Text('Create Poll'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
