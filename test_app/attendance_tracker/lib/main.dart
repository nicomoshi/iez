import 'package:flutter/material.dart';

void main() {
  runApp(const AttendanceTrackerApp());
}

// --- Data Models ---

enum AttendanceStatus { present, absent, late_, excused }

extension AttendanceStatusLabel on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late_: return 'Late';
      case AttendanceStatus.excused: return 'Excused';
    }
  }
}

class Student {
  final String id;
  final String name;
  final String grade;

  Student({required this.id, required this.name, required this.grade});
}

class AttendanceRecord {
  final String studentId;
  final DateTime date;
  AttendanceStatus status;

  AttendanceRecord({required this.studentId, required this.date, required this.status});
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<Student> _students = [
    Student(id: '1', name: 'Emma Wilson', grade: 'A'),
    Student(id: '2', name: 'James Chen', grade: 'B+'),
    Student(id: '3', name: 'Sofia Rodriguez', grade: 'A-'),
    Student(id: '4', name: 'Liam Johnson', grade: 'B'),
    Student(id: '5', name: 'Olivia Brown', grade: 'A+'),
    Student(id: '6', name: 'Noah Davis', grade: 'C+'),
  ];

  final List<AttendanceRecord> _records = [];
  DateTime _selectedDate = DateTime.now();

  AppState() {
    // Seed today's attendance
    final today = DateTime.now();
    for (final s in _students) {
      _records.add(AttendanceRecord(studentId: s.id, date: today, status: AttendanceStatus.present));
    }
    // Mark one absent and one late for variety
    _records[2].status = AttendanceStatus.absent;
    _records[5].status = AttendanceStatus.late_;
  }

  List<Student> get students => List.unmodifiable(_students);
  DateTime get selectedDate => _selectedDate;

  List<AttendanceRecord> recordsForDate(DateTime date) =>
      _records.where((r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day).toList();

  AttendanceRecord? recordFor(String studentId, DateTime date) {
    final matches = _records.where((r) => r.studentId == studentId && r.date.year == date.year && r.date.month == date.month && r.date.day == date.day);
    return matches.isEmpty ? null : matches.first;
  }

  int presentCount(DateTime date) => recordsForDate(date).where((r) => r.status == AttendanceStatus.present).length;
  int absentCount(DateTime date) => recordsForDate(date).where((r) => r.status == AttendanceStatus.absent).length;
  int lateCount(DateTime date) => recordsForDate(date).where((r) => r.status == AttendanceStatus.late_).length;
  int excusedCount(DateTime date) => recordsForDate(date).where((r) => r.status == AttendanceStatus.excused).length;

  double attendanceRate(DateTime date) {
    final records = recordsForDate(date);
    if (records.isEmpty) return 0;
    final present = records.where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.late_).length;
    return present / records.length;
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void updateStatus(String studentId, DateTime date, AttendanceStatus status) {
    final record = recordFor(studentId, date);
    if (record != null) {
      record.status = status;
    } else {
      _records.add(AttendanceRecord(studentId: studentId, date: date, status: status));
    }
    notifyListeners();
  }

  void addStudent(Student student) {
    _students.add(student);
    // Create record for today
    _records.add(AttendanceRecord(studentId: student.id, date: DateTime.now(), status: AttendanceStatus.present));
    notifyListeners();
  }
}

// --- App ---

class AttendanceTrackerApp extends StatefulWidget {
  const AttendanceTrackerApp({super.key});

  @override
  State<AttendanceTrackerApp> createState() => _AttendanceTrackerAppState();
}

class _AttendanceTrackerAppState extends State<AttendanceTrackerApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: MainScreen(state: _state),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AttendancePage(state: widget.state),
      StudentsPage(state: widget.state),
      ReportsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
        ],
      ),
    );
  }
}

// --- Attendance Page ---

class AttendancePage extends StatelessWidget {
  final AppState state;
  const AttendancePage({super.key, required this.state});

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late_: return Colors.orange;
      case AttendanceStatus.excused: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = state.selectedDate;
    final dateStr = '${date.month}/${date.day}/${date.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(dateStr, style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CountChip(label: 'Present', count: state.presentCount(date), color: Colors.green),
                    _CountChip(label: 'Absent', count: state.absentCount(date), color: Colors.red),
                    _CountChip(label: 'Late', count: state.lateCount(date), color: Colors.orange),
                    _CountChip(label: 'Excused', count: state.excusedCount(date), color: Colors.blue),
                  ],
                ),
              ),
            ),
          ),
          // Student list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.students.length,
              itemBuilder: (context, index) {
                final student = state.students[index];
                final record = state.recordFor(student.id, date);
                final status = record?.status ?? AttendanceStatus.present;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(student.name),
                    subtitle: Text('Grade: ${student.grade}'),
                    trailing: DropdownButton<AttendanceStatus>(
                      value: status,
                      underline: const SizedBox(),
                      items: AttendanceStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label, style: TextStyle(color: _statusColor(s))),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) state.updateStatus(student.id, date, v);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// --- Students Page ---

class StudentsPage extends StatelessWidget {
  final AppState state;
  const StudentsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.students.length,
        itemBuilder: (context, index) {
          final student = state.students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(student.name[0])),
              title: Text(student.name),
              subtitle: Text('Grade: ${student.grade}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailPage(state: state, student: student))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
            const SizedBox(height: 12),
            TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'Grade')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                state.addStudent(Student(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  grade: gradeController.text.isNotEmpty ? gradeController.text : 'N/A',
                ));
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

// --- Student Detail Page ---

class StudentDetailPage extends StatelessWidget {
  final AppState state;
  final Student student;
  const StudentDetailPage({super.key, required this.state, required this.student});

  @override
  Widget build(BuildContext context) {
    final record = state.recordFor(student.id, state.selectedDate);
    final status = record?.status ?? AttendanceStatus.present;

    return Scaffold(
      appBar: AppBar(title: Text(student.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Info', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Name', value: student.name),
                  _InfoRow(label: 'Grade', value: student.grade),
                  _InfoRow(label: 'Today', value: status.label),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Reports Page ---

class ReportsPage extends StatelessWidget {
  final AppState state;
  const ReportsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final date = state.selectedDate;
    final rate = state.attendanceRate(date);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Attendance Rate', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text('${(rate * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: rate),
                  const SizedBox(height: 8),
                  Text('${state.presentCount(date) + state.lateCount(date)} of ${state.students.length} students present'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breakdown', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _ReportRow(label: 'Present', value: '${state.presentCount(date)}', color: Colors.green),
                  _ReportRow(label: 'Absent', value: '${state.absentCount(date)}', color: Colors.red),
                  _ReportRow(label: 'Late', value: '${state.lateCount(date)}', color: Colors.orange),
                  _ReportRow(label: 'Excused', value: '${state.excusedCount(date)}', color: Colors.blue),
                  const Divider(),
                  _ReportRow(label: 'Total Students', value: '${state.students.length}', color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReportRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
