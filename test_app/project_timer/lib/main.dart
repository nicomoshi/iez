import 'package:flutter/material.dart';

void main() {
  runApp(const ProjectTimerApp());
}

class ProjectTimerApp extends StatelessWidget {
  const ProjectTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────

class TimeEntry {
  final String date;
  final String duration;
  final String notes;

  const TimeEntry({
    required this.date,
    required this.duration,
    required this.notes,
  });
}

class Project {
  String name;
  String client;
  String description;
  double totalHours;
  double hourlyRate;
  String status; // Active, Paused, Completed
  Color color;
  List<TimeEntry> entries;

  Project({
    required this.name,
    required this.client,
    required this.description,
    required this.totalHours,
    required this.hourlyRate,
    required this.status,
    required this.color,
    required this.entries,
  });

  double get totalEarnings => totalHours * hourlyRate;
}

// ─── Global State ────────────────────────────────────────────

class AppState {
  static final List<Project> projects = [
    Project(
      name: 'Website Redesign',
      client: 'Acme Corp',
      description: 'Complete website overhaul including new design system, responsive layouts, and performance optimization.',
      totalHours: 24.5,
      hourlyRate: 95.0,
      status: 'Active',
      color: Colors.blue,
      entries: [
        const TimeEntry(date: 'Mar 22, 2026', duration: '3.5 hrs', notes: 'Homepage layout and hero section'),
        const TimeEntry(date: 'Mar 21, 2026', duration: '4.0 hrs', notes: 'Navigation redesign and mobile menu'),
        const TimeEntry(date: 'Mar 20, 2026', duration: '2.5 hrs', notes: 'Color palette and typography updates'),
        const TimeEntry(date: 'Mar 19, 2026', duration: '5.0 hrs', notes: 'Product page templates'),
      ],
    ),
    Project(
      name: 'Mobile App',
      client: 'TechStart',
      description: 'Cross-platform mobile application for task management with real-time sync and push notifications.',
      totalHours: 18.0,
      hourlyRate: 110.0,
      status: 'Active',
      color: Colors.green,
      entries: [
        const TimeEntry(date: 'Mar 22, 2026', duration: '2.0 hrs', notes: 'Authentication flow implementation'),
        const TimeEntry(date: 'Mar 21, 2026', duration: '3.5 hrs', notes: 'Dashboard UI and state management'),
        const TimeEntry(date: 'Mar 18, 2026', duration: '4.0 hrs', notes: 'API integration and data models'),
      ],
    ),
    Project(
      name: 'Logo Design',
      client: 'FreshBrand',
      description: 'Brand identity design including logo, color palette, and brand guidelines document.',
      totalHours: 8.0,
      hourlyRate: 85.0,
      status: 'Completed',
      color: Colors.orange,
      entries: [
        const TimeEntry(date: 'Mar 15, 2026', duration: '3.0 hrs', notes: 'Final revisions and brand guide'),
        const TimeEntry(date: 'Mar 14, 2026', duration: '2.5 hrs', notes: 'Logo variations and mockups'),
        const TimeEntry(date: 'Mar 12, 2026', duration: '2.5 hrs', notes: 'Initial concepts and sketches'),
      ],
    ),
    Project(
      name: 'API Integration',
      client: 'DataFlow',
      description: 'REST API design and integration with third-party services including payment processing and analytics.',
      totalHours: 12.5,
      hourlyRate: 120.0,
      status: 'Paused',
      color: Colors.purple,
      entries: [
        const TimeEntry(date: 'Mar 17, 2026', duration: '4.0 hrs', notes: 'Payment gateway integration'),
        const TimeEntry(date: 'Mar 16, 2026', duration: '3.5 hrs', notes: 'API endpoint design and documentation'),
        const TimeEntry(date: 'Mar 14, 2026', duration: '5.0 hrs', notes: 'Database schema and migrations'),
      ],
    ),
  ];

  static String? activeProject = 'Website Redesign';

  static double get todayHours {
    double total = 0;
    for (final p in projects) {
      for (final e in p.entries) {
        if (e.date == 'Mar 22, 2026') {
          total += double.parse(e.duration.replaceAll(' hrs', ''));
        }
      }
    }
    return total;
  }

  static double get weekHours {
    double total = 0;
    for (final p in projects) {
      total += p.totalHours;
    }
    return total;
  }
}

// ─── Home Screen ─────────────────────────────────────────────

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
        title: const Text('Project Timer'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reports') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reports',
                child: Text('Reports'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppState.projects.length,
              itemBuilder: (context, index) {
                return _buildProjectCard(AppState.projects[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProjectScreen()),
          );
          setState(() {});
        },
        child: const Text('Add Project'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${AppState.todayHours.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Hours Today'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${AppState.weekHours.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Hours This Week'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (AppState.activeProject != null)
              Text(
                'Active: ${AppState.activeProject}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: project.color,
          radius: 8,
        ),
        title: Text(project.name),
        subtitle: Text(project.client),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${project.totalHours.toStringAsFixed(1)} hrs',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                project.status,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _statusColor(project.status),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(project: project)),
          );
          setState(() {});
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green.shade100;
      case 'Paused':
        return Colors.orange.shade100;
      case 'Completed':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade200;
    }
  }
}

// ─── Detail Screen ───────────────────────────────────────────

class DetailScreen extends StatefulWidget {
  final Project project;
  const DetailScreen({super.key, required this.project});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Project project;

  @override
  void initState() {
    super.initState();
    project = widget.project;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project info
            Text(
              project.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              project.client,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(project.description),
            const SizedBox(height: 20),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('Total Hours', '${project.totalHours.toStringAsFixed(1)}'),
                _statColumn('Hourly Rate', '\$${project.hourlyRate.toStringAsFixed(0)}'),
                _statColumn('Total Earnings', '\$${project.totalEarnings.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (project.status == 'Active') {
                          project.status = 'Paused';
                          if (AppState.activeProject == project.name) {
                            AppState.activeProject = null;
                          }
                        } else {
                          project.status = 'Active';
                          AppState.activeProject = project.name;
                        }
                      });
                    },
                    child: Text(
                      project.status == 'Active' ? 'Pause Timer' : 'Start Timer',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProjectScreen(project: project),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent time entries
            const Text(
              'Recent Time Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...project.entries.map((entry) => _buildEntryCard(entry)),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildEntryCard(TimeEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.date, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(entry.duration, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.notes, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Project Screen ─────────────────────────────────────

class EditProjectScreen extends StatefulWidget {
  final Project project;
  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _clientCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _clientCtrl = TextEditingController(text: widget.project.client);
    _descCtrl = TextEditingController(text: widget.project.description);
    _rateCtrl = TextEditingController(text: widget.project.hourlyRate.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                labelText: 'Client',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateCtrl,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.project.name = _nameCtrl.text;
                  widget.project.client = _clientCtrl.text;
                  widget.project.description = _descCtrl.text;
                  widget.project.hourlyRate = double.tryParse(_rateCtrl.text) ?? widget.project.hourlyRate;
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Project Screen ──────────────────────────────────────

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                labelText: 'Client',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateCtrl,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text(
              'Project Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isEmpty) return;
                  AppState.projects.add(Project(
                    name: _nameCtrl.text,
                    client: _clientCtrl.text,
                    description: _descCtrl.text,
                    totalHours: 0,
                    hourlyRate: double.tryParse(_rateCtrl.text) ?? 0,
                    status: 'Active',
                    color: _selectedColor,
                    entries: [],
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reports Screen ──────────────────────────────────────────

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalEarnings = AppState.projects.fold<double>(
      0,
      (sum, p) => sum + p.totalEarnings,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly hours chart (text-based)
            const Text(
              'Weekly Hours',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBarRow('Mon', 6.5, 8),
            _buildBarRow('Tue', 7.0, 8),
            _buildBarRow('Wed', 5.5, 8),
            _buildBarRow('Thu', 8.0, 8),
            _buildBarRow('Fri', 4.5, 8),
            _buildBarRow('Sat', 2.0, 8),
            _buildBarRow('Sun', 0.0, 8),

            const SizedBox(height: 24),

            // Project breakdown
            const Text(
              'Project Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...AppState.projects.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.color,
                  radius: 8,
                ),
                title: Text(p.name),
                subtitle: Text('${p.totalHours.toStringAsFixed(1)} hrs @ \$${p.hourlyRate.toStringAsFixed(0)}/hr'),
                trailing: Text(
                  '\$${p.totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Total earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String day, double hours, double maxHours) {
    final fraction = hours / maxHours;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(day)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 20,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text('${hours.toStringAsFixed(1)} h', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
