import 'package:flutter/material.dart';

void main() {
  runApp(const BMICalculatorApp());
}

class BMICalculatorApp extends StatelessWidget {
  const BMICalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BMIInputScreen(),
    );
  }
}

class BMIInputScreen extends StatefulWidget {
  const BMIInputScreen({super.key});

  @override
  State<BMIInputScreen> createState() => _BMIInputScreenState();
}

class _BMIInputScreenState extends State<BMIInputScreen> {
  String _selectedGender = 'Male';
  double _height = 170;
  int _weight = 75;
  int _age = 25;

  void _incrementWeight() => setState(() => _weight++);
  void _decrementWeight() => setState(() {
        if (_weight > 1) _weight--;
      });
  void _incrementAge() => setState(() => _age++);
  void _decrementAge() => setState(() {
        if (_age > 1) _age--;
      });

  void _calculate() {
    final heightM = _height / 100.0;
    final bmi = _weight / (heightM * heightM);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BMIResultScreen(
          bmi: bmi,
          gender: _selectedGender,
          age: _age,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gender selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Card(
                      color: _selectedGender == 'Male'
                          ? const Color(0xFF4A90D9)
                          : cs.surfaceContainerHighest,
                      elevation: _selectedGender == 'Male' ? 6 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _selectedGender == 'Male'
                            ? const BorderSide(color: Color(0xFF4A90D9), width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male,
                              size: 48,
                              color: _selectedGender == 'Male'
                                  ? Colors.white
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Male',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _selectedGender == 'Male'
                                    ? Colors.white
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Card(
                      color: _selectedGender == 'Female'
                          ? const Color(0xFFE91E8C)
                          : cs.surfaceContainerHighest,
                      elevation: _selectedGender == 'Female' ? 6 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: _selectedGender == 'Female'
                            ? const BorderSide(color: Color(0xFFE91E8C), width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female,
                              size: 48,
                              color: _selectedGender == 'Female'
                                  ? Colors.white
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Female',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _selectedGender == 'Female'
                                    ? Colors.white
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Height slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Height: ${_height.round()} cm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Slider(
                      value: _height,
                      min: 100,
                      max: 220,
                      divisions: 120,
                      label: '${_height.round()} cm',
                      onChanged: (v) => setState(() => _height = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('100 cm', style: theme.textTheme.bodySmall),
                        Text('220 cm', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weight and Age row
            Row(
              children: [
                // Weight
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Weight (kg)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _decrementWeight,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: cs.secondaryContainer,
                                  foregroundColor: cs.onSecondaryContainer,
                                ),
                                child: const Text(
                                  '-',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_weight',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _incrementWeight,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: cs.secondaryContainer,
                                  foregroundColor: cs.onSecondaryContainer,
                                ),
                                child: const Text(
                                  '+',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Age
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Age',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _decrementAge,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: cs.secondaryContainer,
                                  foregroundColor: cs.onSecondaryContainer,
                                ),
                                child: const Text(
                                  '-',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_age',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _incrementAge,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: cs.secondaryContainer,
                                  foregroundColor: cs.onSecondaryContainer,
                                ),
                                child: const Text(
                                  '+',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Calculate button
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Calculate'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class BMIResultScreen extends StatelessWidget {
  final double bmi;
  final String gender;
  final int age;

  const BMIResultScreen({
    super.key,
    required this.bmi,
    required this.gender,
    required this.age,
  });

  String get _category {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  String get _description {
    if (bmi < 18.5) {
      return 'Your BMI indicates you are underweight. Consider consulting a healthcare provider about healthy ways to gain weight through balanced nutrition.';
    } else if (bmi < 25.0) {
      return 'Your BMI is within the normal range. You are maintaining a healthy weight. Keep up your balanced diet and regular physical activity.';
    } else if (bmi < 30.0) {
      return 'Your BMI indicates you are overweight. Small lifestyle changes like regular exercise and a balanced diet can help you reach a healthier weight.';
    } else {
      return 'Your BMI indicates obesity. It is recommended to consult a healthcare provider for personalized guidance on reaching a healthier weight safely.';
    }
  }

  Color _categoryColor(BuildContext context) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor = _categoryColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Result'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      'Your BMI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                        fontSize: 72,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: catColor, width: 1.5),
                      ),
                      child: Text(
                        _category,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Recalculate'),
            ),
          ],
        ),
      ),
    );
  }
}
