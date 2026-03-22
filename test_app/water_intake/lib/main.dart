import 'package:flutter/material.dart';

void main() {
  runApp(const WaterIntakeApp());
}

class WaterIntakeApp extends StatelessWidget {
  const WaterIntakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Intake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class DrinkEntry {
  final String type;
  final int amountMl;
  final TimeOfDay time;

  DrinkEntry({required this.type, required this.amountMl, required this.time});
}

class DailyRecord {
  final String date;
  final double liters;

  DailyRecord({required this.date, required this.liters});
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double _currentIntake = 1.5;
  final double _dailyTarget = 2.5;
  bool _notificationsEnabled = true;

  final List<DrinkEntry> _todayDrinks = [
    DrinkEntry(type: 'Water', amountMl: 500, time: const TimeOfDay(hour: 8, minute: 0)),
    DrinkEntry(type: 'Coffee', amountMl: 250, time: const TimeOfDay(hour: 10, minute: 30)),
    DrinkEntry(type: 'Water', amountMl: 500, time: const TimeOfDay(hour: 12, minute: 0)),
    DrinkEntry(type: 'Tea', amountMl: 250, time: const TimeOfDay(hour: 15, minute: 0)),
  ];

  final List<DailyRecord> _history = [
    DailyRecord(date: 'March 20', liters: 2.5),
    DailyRecord(date: 'March 19', liters: 2.0),
    DailyRecord(date: 'March 18', liters: 1.8),
    DailyRecord(date: 'March 17', liters: 2.2),
  ];

  void _addWaterQuick(int ml) {
    setState(() {
      _currentIntake += ml / 1000.0;
      _todayDrinks.insert(
        0,
        DrinkEntry(
          type: 'Water',
          amountMl: ml,
          time: TimeOfDay.now(),
        ),
      );
    });
  }

  void _addDrinkEntry(String type, int amountMl) {
    setState(() {
      _currentIntake += amountMl / 1000.0;
      _todayDrinks.insert(
        0,
        DrinkEntry(
          type: type,
          amountMl: amountMl,
          time: TimeOfDay.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
          _buildGoalsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddWaterPage()),
                );
                if (result != null) {
                  _addDrinkEntry(
                    result['type'] as String,
                    result['amount'] as int,
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Water'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final progress = (_currentIntake / _dailyTarget).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                  Text(
                    '${_currentIntake.toStringAsFixed(1)}L / ${_dailyTarget.toStringAsFixed(1)}L',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: () => _addWaterQuick(250),
                child: const Text('250ml'),
              ),
              FilledButton.tonal(
                onPressed: () => _addWaterQuick(500),
                child: const Text('500ml'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddWaterPage()),
                  );
                  if (result != null) {
                    _addDrinkEntry(
                      result['type'] as String,
                      result['amount'] as int,
                    );
                  }
                },
                child: const Text('Custom'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Today's Drinks",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayDrinks.length,
            itemBuilder: (context, index) {
              final drink = _todayDrinks[index];
              return ListTile(
                leading: Icon(
                  drink.type == 'Water'
                      ? Icons.water_drop
                      : drink.type == 'Coffee'
                          ? Icons.coffee
                          : drink.type == 'Tea'
                              ? Icons.emoji_food_beverage
                              : Icons.local_drink,
                  color: Colors.blue,
                ),
                title: Text('${drink.type} - ${drink.amountMl}ml'),
                subtitle: Text(
                  '${drink.time.hour.toString().padLeft(2, '0')}:${drink.time.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final record = _history[index];
                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('${record.date} - ${record.liters.toStringAsFixed(1)}L'),
                  trailing: Icon(
                    record.liters >= _dailyTarget
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: record.liters >= _dailyTarget
                        ? Colors.green
                        : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Daily Target'),
            trailing: Text(
              '${_dailyTarget.toStringAsFixed(1)}L',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Reminder Interval'),
            trailing: Text(
              '2 hours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search History',
                hintText: 'Search by date or drink type',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Type to search your water intake history'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddWaterPage extends StatefulWidget {
  const AddWaterPage({super.key});

  @override
  State<AddWaterPage> createState() => _AddWaterPageState();
}

class _AddWaterPageState extends State<AddWaterPage> {
  final _amountController = TextEditingController();
  String _selectedDrinkType = 'Water';
  final List<String> _drinkTypes = ['Water', 'Tea', 'Coffee', 'Juice'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Water'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                hintText: 'Enter amount in ml',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDrinkType,
              decoration: const InputDecoration(
                labelText: 'Drink Type',
                border: OutlineInputBorder(),
              ),
              items: _drinkTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDrinkType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(_amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(context, {
                    'type': _selectedDrinkType,
                    'amount': amount,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
