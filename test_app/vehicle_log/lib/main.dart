import 'package:flutter/material.dart';

void main() {
  runApp(const VehicleLogApp());
}

// --- Data Models ---

class Vehicle {
  final String year;
  final String make;
  final String model;
  final int mileage;
  final String nextServiceDate;
  final String status; // Good, Due Soon, Overdue
  final String vin;
  final List<ServiceRecord> serviceHistory;
  final List<FuelEntry> fuelLog;

  Vehicle({
    required this.year,
    required this.make,
    required this.model,
    required this.mileage,
    required this.nextServiceDate,
    required this.status,
    this.vin = '',
    this.serviceHistory = const [],
    this.fuelLog = const [],
  });

  String get displayName => '$year $make $model';
}

class ServiceRecord {
  final String date;
  final String type;
  final int mileage;
  final double cost;

  ServiceRecord({
    required this.date,
    required this.type,
    required this.mileage,
    required this.cost,
  });
}

class FuelEntry {
  final String date;
  final double gallons;
  final double cost;
  final double mpg;

  FuelEntry({
    required this.date,
    required this.gallons,
    required this.cost,
    required this.mpg,
  });
}

class Reminder {
  final String vehicleName;
  final String serviceType;
  final String dueDate;

  Reminder({
    required this.vehicleName,
    required this.serviceType,
    required this.dueDate,
  });
}

// --- Sample Data ---

final List<Vehicle> sampleVehicles = [
  Vehicle(
    year: '2022',
    make: 'Tesla',
    model: 'Model 3',
    mileage: 28500,
    nextServiceDate: 'Apr 1, 2026',
    status: 'Good',
    vin: '5YJ3E1EA1NF123456',
    serviceHistory: [
      ServiceRecord(date: 'Jan 2026', type: 'Tire Rotation', mileage: 25000, cost: 50),
      ServiceRecord(date: 'Dec 2025', type: 'Annual Inspection', mileage: 22000, cost: 150),
    ],
    fuelLog: [
      FuelEntry(date: 'Mar 1, 2026', gallons: 0, cost: 12.50, mpg: 0),
      FuelEntry(date: 'Feb 15, 2026', gallons: 0, cost: 10.00, mpg: 0),
    ],
  ),
  Vehicle(
    year: '2020',
    make: 'Toyota',
    model: 'Camry',
    mileage: 55200,
    nextServiceDate: 'Mar 25, 2026',
    status: 'Due Soon',
    vin: '4T1B11HK5LU123456',
    serviceHistory: [
      ServiceRecord(date: 'Feb 2026', type: 'Oil Change', mileage: 52000, cost: 75),
      ServiceRecord(date: 'Nov 2025', type: 'Brake Pads', mileage: 48000, cost: 350),
    ],
    fuelLog: [
      FuelEntry(date: 'Mar 10, 2026', gallons: 12.5, cost: 45.00, mpg: 32.1),
      FuelEntry(date: 'Feb 28, 2026', gallons: 11.8, cost: 42.50, mpg: 31.5),
    ],
  ),
  Vehicle(
    year: '2018',
    make: 'Ford',
    model: 'F-150',
    mileage: 82100,
    nextServiceDate: 'Mar 15, 2026',
    status: 'Overdue',
    vin: '1FTEW1EP5JFA12345',
    serviceHistory: [
      ServiceRecord(date: 'Jan 2026', type: 'Transmission Fluid', mileage: 80000, cost: 200),
      ServiceRecord(date: 'Oct 2025', type: 'Oil Change', mileage: 75000, cost: 85),
    ],
    fuelLog: [
      FuelEntry(date: 'Mar 5, 2026', gallons: 18.2, cost: 65.00, mpg: 21.3),
      FuelEntry(date: 'Feb 20, 2026', gallons: 17.5, cost: 63.00, mpg: 22.0),
    ],
  ),
];

final List<Reminder> sampleReminders = [
  Reminder(vehicleName: '2018 Ford F-150', serviceType: 'Oil Change', dueDate: 'Mar 15, 2026'),
  Reminder(vehicleName: '2020 Toyota Camry', serviceType: 'Tire Rotation', dueDate: 'Mar 25, 2026'),
  Reminder(vehicleName: '2022 Tesla Model 3', serviceType: 'Brake Inspection', dueDate: 'Apr 1, 2026'),
  Reminder(vehicleName: '2020 Toyota Camry', serviceType: 'Oil Change', dueDate: 'Apr 10, 2026'),
  Reminder(vehicleName: '2018 Ford F-150', serviceType: 'Transmission Service', dueDate: 'Apr 15, 2026'),
];

// --- App ---

class VehicleLogApp extends StatelessWidget {
  const VehicleLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Log',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Log'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reminders') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reminders',
                child: Text('Reminders'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
        },
        child: const Text('Add Vehicle'),
      ),
      body: ListView.builder(
        itemCount: sampleVehicles.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final v = sampleVehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(v.displayName),
              subtitle: Text('${_formatMileage(v.mileage)} mi  •  Next service: ${v.nextServiceDate}'),
              trailing: _StatusChip(status: v.status),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(vehicle: v)));
              },
            ),
          );
        },
      ),
    );
  }
}

String _formatMileage(int m) {
  if (m >= 1000) {
    final whole = m ~/ 1000;
    final remainder = (m % 1000).toString().padLeft(3, '0');
    return '$whole,$remainder';
  }
  return m.toString();
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'Good':
        bg = Colors.green;
        break;
      case 'Due Soon':
        bg = Colors.orange;
        break;
      case 'Overdue':
        bg = Colors.red;
        break;
      default:
        bg = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatelessWidget {
  final Vehicle vehicle;
  const DetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(vehicle.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Year', vehicle.year),
            _infoRow('Make', vehicle.make),
            _infoRow('Model', vehicle.model),
            _infoRow('Mileage', '${_formatMileage(vehicle.mileage)} mi'),
            _infoRow('VIN', vehicle.vin),
            _infoRow('Next Service', vehicle.nextServiceDate),
            _infoRow('Status', vehicle.status),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ServiceHistoryScreen(vehicle: vehicle),
                    ));
                  },
                  child: const Text('Service History'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FuelLogScreen(vehicle: vehicle),
                    ));
                  },
                  child: const Text('Fuel Log'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EditVehicleScreen(vehicle: vehicle),
                    ));
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Service History Screen ---

class ServiceHistoryScreen extends StatelessWidget {
  final Vehicle vehicle;
  const ServiceHistoryScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service History')),
      body: ListView.builder(
        itemCount: vehicle.serviceHistory.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final s = vehicle.serviceHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(s.type),
              subtitle: Text('${s.date}  •  ${_formatMileage(s.mileage)} mi  •  \$${s.cost.toStringAsFixed(0)}'),
            ),
          );
        },
      ),
    );
  }
}

// --- Fuel Log Screen ---

class FuelLogScreen extends StatelessWidget {
  final Vehicle vehicle;
  const FuelLogScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Log')),
      body: ListView.builder(
        itemCount: vehicle.fuelLog.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final f = vehicle.fuelLog[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(f.date),
              subtitle: Text('${f.gallons} gal  •  \$${f.cost.toStringAsFixed(2)}  •  ${f.mpg} mpg'),
            ),
          );
        },
      ),
    );
  }
}

// --- Add Vehicle Screen ---

class AddVehicleScreen extends StatelessWidget {
  const AddVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Mileage', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'VIN', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Edit Vehicle Screen ---

class EditVehicleScreen extends StatelessWidget {
  final Vehicle vehicle;
  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Vehicle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                controller: TextEditingController(text: vehicle.year),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
                controller: TextEditingController(text: vehicle.make),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                controller: TextEditingController(text: vehicle.model),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Mileage', border: OutlineInputBorder()),
                controller: TextEditingController(text: vehicle.mileage.toString()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'VIN', border: OutlineInputBorder()),
                controller: TextEditingController(text: vehicle.vin),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Reminders Screen ---

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView.builder(
        itemCount: sampleReminders.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final r = sampleReminders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(r.vehicleName),
              subtitle: Text('${r.serviceType}  •  Due: ${r.dueDate}'),
            ),
          );
        },
      ),
    );
  }
}
