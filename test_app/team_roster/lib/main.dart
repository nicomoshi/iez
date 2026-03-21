import 'package:flutter/material.dart';

void main() {
  runApp(const TeamRosterApp());
}

class Player {
  String name;
  int number;
  String position;
  String status;
  int gamesPlayed;
  int goals;
  int assists;
  String phone;
  String email;

  Player({
    required this.name,
    required this.number,
    required this.position,
    required this.status,
    this.gamesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.phone = '',
    this.email = '',
  });
}

class Game {
  final String date;
  final String opponent;
  final String location;
  final String homeAway;

  const Game({
    required this.date,
    required this.opponent,
    required this.location,
    required this.homeAway,
  });
}

final List<Player> players = [
  Player(
    name: 'Alex Rivera',
    number: 10,
    position: 'Forward',
    status: 'Active',
    gamesPlayed: 18,
    goals: 12,
    assists: 8,
    phone: '555-0110',
    email: 'alex.rivera@team.com',
  ),
  Player(
    name: 'Jordan Kim',
    number: 1,
    position: 'Goalkeeper',
    status: 'Active',
    gamesPlayed: 18,
    goals: 0,
    assists: 0,
    phone: '555-0101',
    email: 'jordan.kim@team.com',
  ),
  Player(
    name: 'Casey Morgan',
    number: 7,
    position: 'Midfielder',
    status: 'Injured',
    gamesPlayed: 14,
    goals: 5,
    assists: 10,
    phone: '555-0107',
    email: 'casey.morgan@team.com',
  ),
  Player(
    name: 'Taylor Smith',
    number: 4,
    position: 'Defender',
    status: 'Active',
    gamesPlayed: 17,
    goals: 2,
    assists: 3,
    phone: '555-0104',
    email: 'taylor.smith@team.com',
  ),
  Player(
    name: 'Sam Johnson',
    number: 22,
    position: 'Forward',
    status: 'Bench',
    gamesPlayed: 10,
    goals: 3,
    assists: 2,
    phone: '555-0122',
    email: 'sam.johnson@team.com',
  ),
];

final List<Game> schedule = [
  const Game(
    date: 'Mar 25',
    opponent: 'Lightning FC',
    location: 'City Stadium',
    homeAway: 'Home',
  ),
  const Game(
    date: 'Mar 30',
    opponent: 'Storm United',
    location: 'Away Park',
    homeAway: 'Away',
  ),
  const Game(
    date: 'Apr 5',
    opponent: 'Phoenix Rising',
    location: 'City Stadium',
    homeAway: 'Home',
  ),
];

class TeamRosterApp extends StatelessWidget {
  const TeamRosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Roster',
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Roster'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Schedule') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Schedule',
                child: Text('Schedule'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thunder Hawks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Record: 12-5-1'),
                  const SizedBox(height: 4),
                  const Text('Next Game: Mar 25 vs Lightning FC'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(player.name),
                    subtitle: Text('#${player.number} - ${player.position}'),
                    trailing: Chip(
                      label: Text(player.status),
                      backgroundColor: _statusColor(player.status),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerDetailScreen(player: player),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPlayerScreen(),
            ),
          );
          setState(() {});
        },
        child: const Text('Add'),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green.shade100;
      case 'Injured':
        return Colors.red.shade100;
      case 'Bench':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '#${player.number} - ${player.position}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Games Played: ${player.gamesPlayed}'),
            Text('Goals: ${player.goals}'),
            Text('Assists: ${player.assists}'),
            const SizedBox(height: 16),
            Text(
              'Contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Phone: ${player.phone}'),
            Text('Email: ${player.email}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlayerScreen(player: player),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditPlayerScreen extends StatefulWidget {
  final Player player;

  const EditPlayerScreen({super.key, required this.player});

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _positionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _numberController =
        TextEditingController(text: widget.player.number.toString());
    _positionController = TextEditingController(text: widget.player.position);
    _phoneController = TextEditingController(text: widget.player.phone);
    _emailController = TextEditingController(text: widget.player.email);
    _status = widget.player.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Player'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['Active', 'Injured', 'Bench']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                widget.player.name = _nameController.text;
                widget.player.number =
                    int.tryParse(_numberController.text) ?? widget.player.number;
                widget.player.position = _positionController.text;
                widget.player.phone = _phoneController.text;
                widget.player.email = _emailController.text;
                widget.player.status = _status;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _status = 'Active';

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Player'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['Active', 'Injured', 'Bench']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  players.add(Player(
                    name: _nameController.text,
                    number: int.tryParse(_numberController.text) ?? 0,
                    position: _positionController.text,
                    status: _status,
                    phone: _phoneController.text,
                    email: _emailController.text,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Player'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final game = schedule[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text('vs ${game.opponent}'),
              subtitle: Text('${game.date} - ${game.location}'),
              trailing: Chip(
                label: Text(game.homeAway),
                backgroundColor: game.homeAway == 'Home'
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
              ),
            ),
          );
        },
      ),
    );
  }
}
