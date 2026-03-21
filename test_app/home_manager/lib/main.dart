import 'package:flutter/material.dart';

void main() {
  runApp(const HomeManagerApp());
}

// --- Data Models ---

class Device {
  final String name;
  final String type;
  bool isOn;
  String value;

  Device({
    required this.name,
    required this.type,
    required this.isOn,
    required this.value,
  });
}

class Room {
  final String name;
  final List<Device> devices;

  Room({required this.name, required this.devices});

  int get activeCount => devices.where((d) => d.isOn).length;

  String get summary => '${devices.length} devices, $activeCount active';
}

// --- App State ---

class AppState extends ChangeNotifier {
  bool useFahrenheit = true;
  bool notificationsOn = true;
  bool darkTheme = false;

  final List<Room> rooms = [
    Room(name: 'Living Room', devices: [
      Device(name: 'Smart Light', type: 'Light', isOn: true, value: '80%'),
      Device(name: 'Smart TV', type: 'Television', isOn: false, value: 'Off'),
      Device(name: 'Thermostat', type: 'Climate', isOn: true, value: '72°F'),
    ]),
    Room(name: 'Bedroom', devices: [
      Device(name: 'Smart Light', type: 'Light', isOn: true, value: '60%'),
      Device(name: 'Smart Speaker', type: 'Audio', isOn: true, value: 'Playing'),
      Device(name: 'Air Purifier', type: 'Air Quality', isOn: false, value: 'Off'),
    ]),
    Room(name: 'Kitchen', devices: [
      Device(name: 'Smart Light', type: 'Light', isOn: true, value: '100%'),
      Device(name: 'Coffee Maker', type: 'Appliance', isOn: false, value: 'Off'),
      Device(name: 'Smart Fridge', type: 'Appliance', isOn: true, value: '38°F'),
    ]),
    Room(name: 'Garage', devices: [
      Device(name: 'Smart Light', type: 'Light', isOn: false, value: 'Off'),
      Device(name: 'Security Camera', type: 'Security', isOn: true, value: 'Recording'),
      Device(name: 'Door Sensor', type: 'Security', isOn: true, value: 'Closed'),
    ]),
  ];

  void addRoom(String name) {
    rooms.add(Room(name: name, devices: []));
    notifyListeners();
  }

  void toggleDevice(Device device) {
    device.isOn = !device.isOn;
    if (!device.isOn) {
      device.value = 'Off';
    }
    notifyListeners();
  }

  void toggleFahrenheit() {
    useFahrenheit = !useFahrenheit;
    notifyListeners();
  }

  void toggleNotifications() {
    notificationsOn = !notificationsOn;
    notifyListeners();
  }

  void toggleDarkTheme() {
    darkTheme = !darkTheme;
    notifyListeners();
  }
}

// --- App Root ---

class HomeManagerApp extends StatefulWidget {
  const HomeManagerApp({super.key});

  @override
  State<HomeManagerApp> createState() => _HomeManagerAppState();
}

class _HomeManagerAppState extends State<HomeManagerApp> {
  final AppState appState = AppState();

  @override
  void initState() {
    super.initState();
    appState.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Manager',
      debugShowCheckedModeBanner: false,
      theme: appState.darkTheme ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(appState: appState),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Manager'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(appState: appState),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: appState.rooms.length,
        itemBuilder: (context, index) {
          final room = appState.rooms[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(room.name),
              subtitle: Text(room.summary),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomDetailScreen(room: room, appState: appState),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRoomScreen(appState: appState),
            ),
          );
        },
        child: const Text('Add Room'),
      ),
    );
  }
}

// --- Room Detail Screen ---

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final AppState appState;

  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.appState,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
      ),
      body: widget.room.devices.isEmpty
          ? const Center(child: Text('No devices in this room'))
          : ListView.builder(
              itemCount: widget.room.devices.length,
              itemBuilder: (context, index) {
                final device = widget.room.devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text('${device.type} — ${device.value}'),
                  trailing: Switch(
                    value: device.isOn,
                    onChanged: (val) {
                      setState(() {
                        widget.appState.toggleDevice(device);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}

// --- Add Room Screen ---

class AddRoomScreen extends StatefulWidget {
  final AppState appState;

  const AddRoomScreen({super.key, required this.appState});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  widget.appState.addRoom(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Room'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Settings Screen ---

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Temperature Unit'),
            subtitle: Text(widget.appState.useFahrenheit ? '°F' : '°C'),
            value: widget.appState.useFahrenheit,
            onChanged: (_) {
              setState(() {
                widget.appState.toggleFahrenheit();
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: widget.appState.notificationsOn,
            onChanged: (_) {
              setState(() {
                widget.appState.toggleNotifications();
              });
            },
          ),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: widget.appState.darkTheme,
            onChanged: (_) {
              setState(() {
                widget.appState.toggleDarkTheme();
              });
            },
          ),
        ],
      ),
    );
  }
}
