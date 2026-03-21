import 'package:flutter/material.dart';

void main() {
  runApp(const RegistrationFormApp());
}

class RegistrationFormApp extends StatelessWidget {
  const RegistrationFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RegistrationScreen(),
    );
  }
}

enum Gender { male, female, other }

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  Gender? _selectedGender;
  DateTime? _birthDate;

  // Step 2: Account Details
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 3: Preferences
  String _selectedCountry = 'United States';
  bool _newsletter = true;
  bool _termsAccepted = false;
  double _experienceLevel = 2;
  final List<String> _selectedInterests = [];

  final _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'Japan',
    'Australia',
  ];

  final _interests = [
    'Technology',
    'Sports',
    'Music',
    'Travel',
    'Food',
    'Art',
  ];

  void _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submit() {
    if (_termsAccepted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(
            name: _nameController.text,
            email: _emailController.text,
            username: _usernameController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _currentStep == 2 ? _submit : _nextStep,
          onStepCancel: _currentStep > 0 ? _prevStep : null,
          controlsBuilder: (context, details) {
            return Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 2 ? 'Submit' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Personal Info'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Gender'),
                  ),
                  Row(
                    children: Gender.values.map((g) {
                      return Expanded(
                        child: RadioListTile<Gender>(
                          title: Text(g.name[0].toUpperCase() + g.name.substring(1)),
                          value: g,
                          groupValue: _selectedGender,
                          onChanged: (v) => setState(() => _selectedGender = v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.cake),
                    label: Text(
                      _birthDate != null
                          ? 'Born: ${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                          : 'Select Birth Date',
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Account'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                    validator: (v) =>
                        v == null || v.length < 3 ? 'Min 3 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Preferences'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                    ),
                    items: _countries
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCountry = v ?? _selectedCountry),
                  ),
                  const SizedBox(height: 16),
                  const Text('Experience Level'),
                  Slider(
                    value: _experienceLevel,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _experienceLevel.round().toString(),
                    onChanged: (v) => setState(() => _experienceLevel = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Interests'),
                  Wrap(
                    spacing: 8,
                    children: _interests.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Newsletter'),
                    subtitle: const Text('Receive email updates'),
                    value: _newsletter,
                    onChanged: (v) => setState(() => _newsletter = v),
                  ),
                  CheckboxListTile(
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('I accept the terms'),
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String name;
  final String email;
  final String username;

  const SuccessScreen({
    super.key,
    required this.name,
    required this.email,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Registration Complete!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Welcome, $name!'),
              Text('Email: $email'),
              Text('Username: $username'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
