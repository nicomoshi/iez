import 'package:flutter/material.dart';

void main() {
  runApp(const JobTrackerApp());
}

enum JobStatus { applied, interview, offer, rejected }

extension JobStatusExt on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.applied:
        return 'Applied';
      case JobStatus.interview:
        return 'Interview';
      case JobStatus.offer:
        return 'Offer';
      case JobStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.applied:
        return Colors.blue;
      case JobStatus.interview:
        return Colors.orange;
      case JobStatus.offer:
        return Colors.green;
      case JobStatus.rejected:
        return Colors.red;
    }
  }
}

class JobApplication {
  String company;
  String position;
  JobStatus status;
  String salary;
  String location;
  String dateApplied;
  String notes;
  String contact;

  JobApplication({
    required this.company,
    required this.position,
    required this.status,
    required this.salary,
    required this.location,
    required this.dateApplied,
    this.notes = '',
    this.contact = '',
  });
}

class JobTrackerApp extends StatelessWidget {
  const JobTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Tracker',
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
  String _selectedFilter = 'All';

  final List<JobApplication> _applications = [
    JobApplication(
      company: 'Google',
      position: 'Senior Flutter Dev',
      status: JobStatus.applied,
      salary: '\$180k-\$220k',
      location: 'Mountain View',
      dateApplied: 'Mar 15',
      notes: 'Applied through referral',
      contact: 'Jane Smith',
    ),
    JobApplication(
      company: 'Apple',
      position: 'iOS Engineer',
      status: JobStatus.interview,
      salary: '\$170k-\$210k',
      location: 'Cupertino',
      dateApplied: 'Mar 10',
      notes: 'Phone screen completed',
      contact: 'John Doe',
    ),
    JobApplication(
      company: 'Meta',
      position: 'Mobile Engineer',
      status: JobStatus.rejected,
      salary: '\$160k-\$200k',
      location: 'Menlo Park',
      dateApplied: 'Mar 5',
      notes: 'Did not pass technical round',
      contact: 'Alice Brown',
    ),
    JobApplication(
      company: 'Netflix',
      position: 'UI Engineer',
      status: JobStatus.offer,
      salary: '\$190k-\$230k',
      location: 'Los Gatos',
      dateApplied: 'Mar 1',
      notes: 'Offer received, negotiating',
      contact: 'Bob Wilson',
    ),
    JobApplication(
      company: 'Spotify',
      position: 'Frontend Dev',
      status: JobStatus.applied,
      salary: '\$150k-\$190k',
      location: 'Remote',
      dateApplied: 'Mar 18',
      notes: 'Waiting for response',
      contact: 'Carol Lee',
    ),
  ];

  List<JobApplication> get _filteredApplications {
    if (_selectedFilter == 'All') return _applications;
    return _applications
        .where((app) => app.status.label == _selectedFilter)
        .toList();
  }

  void _addApplication(JobApplication app) {
    setState(() {
      _applications.add(app);
    });
  }

  void _updateApplication() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Analytics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalyticsScreen(applications: _applications),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Analytics',
                child: Text('Analytics'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['All', 'Applied', 'Interview', 'Offer', 'Rejected']
                  .map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : 'All';
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredApplications.length,
              itemBuilder: (context, index) {
                final app = _filteredApplications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(app.company),
                    subtitle: Text(app.position),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(
                            app.status.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: app.status.color,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(height: 4),
                        Text(app.dateApplied,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            application: app,
                            onUpdate: _updateApplication,
                          ),
                        ),
                      );
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
          final result = await Navigator.push<JobApplication>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          );
          if (result != null) {
            _addApplication(result);
          }
        },
        child: const Text('Add'),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final JobApplication application;
  final VoidCallback onUpdate;

  const DetailScreen({
    super.key,
    required this.application,
    required this.onUpdate,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.company),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.position,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Chip(
              label: Text(app.status.label,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: app.status.color,
            ),
            const SizedBox(height: 16),
            _infoRow('Salary', app.salary),
            _infoRow('Location', app.location),
            _infoRow('Date Applied', app.dateApplied),
            _infoRow('Contact', app.contact),
            const SizedBox(height: 12),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(app.notes.isEmpty ? 'No notes' : app.notes),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStatusSheet(context),
                    child: const Text('Update Status'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.push<JobApplication>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditScreen(application: app),
                        ),
                      );
                      if (result != null) {
                        setState(() {});
                        widget.onUpdate();
                      }
                    },
                    child: const Text('Edit'),
                  ),
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
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Update Status',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...JobStatus.values.map((status) => ListTile(
                    title: Text(status.label),
                    leading: CircleAvatar(
                      backgroundColor: status.color,
                      radius: 12,
                    ),
                    onTap: () {
                      setState(() {
                        widget.application.status = status;
                      });
                      widget.onUpdate();
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class AddEditScreen extends StatefulWidget {
  final JobApplication? application;

  const AddEditScreen({super.key, this.application});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late final TextEditingController _companyCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _notesCtrl;
  late JobStatus _status;

  bool get _isEditing => widget.application != null;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _companyCtrl = TextEditingController(text: app?.company ?? '');
    _positionCtrl = TextEditingController(text: app?.position ?? '');
    _salaryCtrl = TextEditingController(text: app?.salary ?? '');
    _locationCtrl = TextEditingController(text: app?.location ?? '');
    _contactCtrl = TextEditingController(text: app?.contact ?? '');
    _notesCtrl = TextEditingController(text: app?.notes ?? '');
    _status = app?.status ?? JobStatus.applied;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Application' : 'Add Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _companyCtrl,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _positionCtrl,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryCtrl,
              decoration: const InputDecoration(labelText: 'Salary'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtrl,
              decoration: const InputDecoration(labelText: 'Contact'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<JobStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: JobStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_companyCtrl.text.isEmpty || _positionCtrl.text.isEmpty) return;

    if (_isEditing) {
      final app = widget.application!;
      app.company = _companyCtrl.text;
      app.position = _positionCtrl.text;
      app.salary = _salaryCtrl.text;
      app.location = _locationCtrl.text;
      app.contact = _contactCtrl.text;
      app.notes = _notesCtrl.text;
      app.status = _status;
      Navigator.pop(context, app);
    } else {
      final app = JobApplication(
        company: _companyCtrl.text,
        position: _positionCtrl.text,
        status: _status,
        salary: _salaryCtrl.text,
        location: _locationCtrl.text,
        dateApplied: 'Mar 22',
        notes: _notesCtrl.text,
        contact: _contactCtrl.text,
      );
      Navigator.pop(context, app);
    }
  }
}

class AnalyticsScreen extends StatelessWidget {
  final List<JobApplication> applications;

  const AnalyticsScreen({super.key, required this.applications});

  @override
  Widget build(BuildContext context) {
    final total = applications.length;
    final applied =
        applications.where((a) => a.status == JobStatus.applied).length;
    final interview =
        applications.where((a) => a.status == JobStatus.interview).length;
    final offer =
        applications.where((a) => a.status == JobStatus.offer).length;
    final rejected =
        applications.where((a) => a.status == JobStatus.rejected).length;
    final responseRate =
        total > 0 ? ((interview + offer + rejected) / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('$total',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Total Applications'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Status Breakdown',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _statusRow(context, 'Applied', applied, Colors.blue),
            _statusRow(context, 'Interview', interview, Colors.orange),
            _statusRow(context, 'Offer', offer, Colors.green),
            _statusRow(context, 'Rejected', rejected, Colors.red),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('$responseRate%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('Response Rate'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(
      BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 8),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('$count',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
