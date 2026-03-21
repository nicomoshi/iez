import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CupertinoFormApp());

class CupertinoFormApp extends StatelessWidget {
  const CupertinoFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Cupertino Form Test',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: FormPage(),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _nameCtrl = TextEditingController(text: '');
  final _emailCtrl = TextEditingController(text: '');
  bool _newsletter = true;
  bool _darkMode = false;
  double _fontSize = 16;
  int _selectedPlan = 0;
  final _plans = ['Free', 'Basic', 'Premium'];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Cupertino Form'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Save'),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Saved'),
                content: Text('Name: ${_nameCtrl.text}\nEmail: ${_emailCtrl.text}'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('PERSONAL'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _nameCtrl,
                  prefix: const Text('Name'),
                  placeholder: 'Enter your name',
                ),
                CupertinoTextFormFieldRow(
                  controller: _emailCtrl,
                  prefix: const Text('Email'),
                  placeholder: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('PREFERENCES'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Newsletter'),
                  child: CupertinoSwitch(
                    value: _newsletter,
                    onChanged: (v) => setState(() => _newsletter = v),
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Dark Mode'),
                  child: CupertinoSwitch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Font Size'),
                  child: SizedBox(
                    width: 200,
                    child: CupertinoSlider(
                      value: _fontSize,
                      min: 10,
                      max: 24,
                      divisions: 7,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('PLAN'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Subscription'),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedPlan,
                    children: {
                      0: const Text('Free'),
                      1: const Text('Basic'),
                      2: const Text('Premium'),
                    },
                    onValueChanged: (v) => setState(() => _selectedPlan = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Current Plan: ${_plans[_selectedPlan]}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoFormSection.insetGrouped(
              header: const Text('ACTIONS'),
              children: [
                CupertinoListTile(
                  title: const Text('View Profile'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => ProfilePage(
                      name: _nameCtrl.text.isEmpty ? 'User' : _nameCtrl.text,
                      email: _emailCtrl.text.isEmpty ? 'N/A' : _emailCtrl.text,
                      plan: _plans[_selectedPlan],
                    )));
                  },
                ),
                CupertinoListTile(
                  title: const Text('Reset All'),
                  trailing: const Icon(CupertinoIcons.refresh, size: 20),
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (ctx) => CupertinoActionSheet(
                        title: const Text('Reset All Settings?'),
                        message: const Text('This will clear all form data.'),
                        actions: [
                          CupertinoActionSheetAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _nameCtrl.clear();
                                _emailCtrl.clear();
                                _newsletter = true;
                                _darkMode = false;
                                _fontSize = 16;
                                _selectedPlan = 0;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final String plan;

  const ProfilePage({super.key, required this.name, required this.email, required this.plan});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 32),
            const Center(
              child: Icon(CupertinoIcons.person_circle, size: 80),
            ),
            const SizedBox(height: 16),
            CupertinoFormSection.insetGrouped(
              header: const Text('DETAILS'),
              children: [
                CupertinoFormRow(prefix: const Text('Name'), child: Text(name)),
                CupertinoFormRow(prefix: const Text('Email'), child: Text(email)),
                CupertinoFormRow(prefix: const Text('Plan'), child: Text(plan)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
