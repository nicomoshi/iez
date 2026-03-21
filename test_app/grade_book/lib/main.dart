import 'package:flutter/material.dart';

void main() {
  runApp(const GradeBookApp());
}

class Assignment {
  String name;
  double score;
  double maxScore;
  double weight;

  Assignment({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.weight,
  });

  String get scoreDisplay => '${score.toInt()}/${maxScore.toInt()}';
  String get weightDisplay => '${weight.toInt()}%';
  double get percentage => (score / maxScore) * 100;
}

class Course {
  String name;
  String instructor;
  String letterGrade;
  double percentage;
  int credits;
  String semester;
  List<Assignment> assignments;

  Course({
    required this.name,
    required this.instructor,
    required this.letterGrade,
    required this.percentage,
    required this.credits,
    required this.semester,
    required this.assignments,
  });

  String get gradeDisplay => '$letterGrade (${percentage.toInt()}%)';

  double get gpaPoints {
    switch (letterGrade) {
      case 'A+':
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }
}

class GradeBookApp extends StatelessWidget {
  const GradeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade Book',
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
  final List<Course> courses = [
    Course(
      name: 'Data Structures',
      instructor: 'Prof. Smith',
      letterGrade: 'A',
      percentage: 94,
      credits: 4,
      semester: 'Fall 2025',
      assignments: [
        Assignment(name: 'Midterm', score: 92, maxScore: 100, weight: 30),
        Assignment(name: 'Final', score: 96, maxScore: 100, weight: 40),
        Assignment(name: 'Labs', score: 90, maxScore: 100, weight: 30),
      ],
    ),
    Course(
      name: 'Linear Algebra',
      instructor: 'Prof. Chen',
      letterGrade: 'B+',
      percentage: 88,
      credits: 3,
      semester: 'Fall 2025',
      assignments: [
        Assignment(name: 'Exam 1', score: 85, maxScore: 100, weight: 25),
        Assignment(name: 'Exam 2', score: 90, maxScore: 100, weight: 25),
        Assignment(name: 'Homework', score: 88, maxScore: 100, weight: 50),
      ],
    ),
    Course(
      name: 'Operating Systems',
      instructor: 'Prof. Lee',
      letterGrade: 'A-',
      percentage: 91,
      credits: 4,
      semester: 'Spring 2026',
      assignments: [
        Assignment(name: 'Project 1', score: 95, maxScore: 100, weight: 20),
        Assignment(name: 'Midterm', score: 88, maxScore: 100, weight: 30),
        Assignment(name: 'Project 2', score: 92, maxScore: 100, weight: 50),
      ],
    ),
    Course(
      name: 'Art History',
      instructor: 'Prof. Davis',
      letterGrade: 'B',
      percentage: 84,
      credits: 3,
      semester: 'Spring 2026',
      assignments: [
        Assignment(name: 'Essay', score: 80, maxScore: 100, weight: 40),
        Assignment(name: 'Presentation', score: 88, maxScore: 100, weight: 30),
        Assignment(name: 'Final', score: 85, maxScore: 100, weight: 30),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Book'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Summary') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SummaryScreen(courses: courses),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Summary',
                child: Text('Summary'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(course.name),
              subtitle: Text(
                '${course.gradeDisplay} • ${course.credits} credits • ${course.semester}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailScreen(course: course),
                  ),
                );
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Course>(
            context,
            MaterialPageRoute(builder: (context) => const AddCourseScreen()),
          );
          if (result != null) {
            setState(() {
              courses.add(result);
            });
          }
        },
        child: const Text('Add Course'),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructor: ${course.instructor}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grade: ${course.gradeDisplay}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Credits: ${course.credits}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semester: ${course.semester}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Assignments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...course.assignments.map(
            (a) => ListTile(
              title: Text(a.name),
              subtitle: Text('Weight: ${a.weightDisplay}'),
              trailing: Text(
                a.scoreDisplay,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Assignment>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAssignmentScreen(),
            ),
          );
          if (result != null) {
            setState(() {
              course.assignments.add(result);
            });
          }
        },
        child: const Text('Add Assignment'),
      ),
    );
  }
}

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _nameController = TextEditingController();
  final _instructorController = TextEditingController();
  final _creditsController = TextEditingController();
  String _selectedSemester = 'Fall 2025';

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _creditsController,
              decoration: const InputDecoration(
                labelText: 'Credits',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Fall 2025',
                  child: Text('Fall 2025'),
                ),
                DropdownMenuItem(
                  value: 'Spring 2026',
                  child: Text('Spring 2026'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _instructorController.text.isNotEmpty &&
                    _creditsController.text.isNotEmpty) {
                  final course = Course(
                    name: _nameController.text,
                    instructor: _instructorController.text,
                    letterGrade: 'N/A',
                    percentage: 0,
                    credits: int.tryParse(_creditsController.text) ?? 0,
                    semester: _selectedSemester,
                    assignments: [],
                  );
                  Navigator.pop(context, course);
                }
              },
              child: const Text('Save Course'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Assignment Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              decoration: const InputDecoration(
                labelText: 'Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxScoreController,
              decoration: const InputDecoration(
                labelText: 'Max Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _scoreController.text.isNotEmpty &&
                    _maxScoreController.text.isNotEmpty &&
                    _weightController.text.isNotEmpty) {
                  final assignment = Assignment(
                    name: _nameController.text,
                    score: double.tryParse(_scoreController.text) ?? 0,
                    maxScore: double.tryParse(_maxScoreController.text) ?? 100,
                    weight: double.tryParse(_weightController.text) ?? 0,
                  );
                  Navigator.pop(context, assignment);
                }
              },
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final List<Course> courses;

  const SummaryScreen({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    final totalCredits = courses.fold<int>(0, (sum, c) => sum + c.credits);
    final gpa = courses.isEmpty
        ? 0.0
        : courses.fold<double>(0, (sum, c) => sum + c.gpaPoints * c.credits) /
            totalCredits;

    final fall2025Credits = courses
        .where((c) => c.semester == 'Fall 2025')
        .fold<int>(0, (sum, c) => sum + c.credits);
    final spring2026Credits = courses
        .where((c) => c.semester == 'Spring 2026')
        .fold<int>(0, (sum, c) => sum + c.credits);

    final gradeCounts = <String, int>{};
    for (final c in courses) {
      gradeCounts[c.letterGrade] = (gradeCounts[c.letterGrade] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'GPA',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gpa.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
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
                  Text(
                    'Credits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Total Credits: $totalCredits'),
                  const SizedBox(height: 4),
                  Text('Fall 2025: $fall2025Credits credits'),
                  const SizedBox(height: 4),
                  Text('Spring 2026: $spring2026Credits credits'),
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
                  Text(
                    'Grade Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...gradeCounts.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${e.key}: ${e.value} course${e.value > 1 ? 's' : ''}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
