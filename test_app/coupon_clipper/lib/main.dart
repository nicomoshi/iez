import 'package:flutter/material.dart';

void main() {
  runApp(const CouponClipperApp());
}

class Coupon {
  final String id;
  final String store;
  final String description;
  final String code;
  final int discountPercent;
  final DateTime expiryDate;
  final bool isUsed;

  Coupon({required this.id, required this.store, required this.description, required this.code, required this.discountPercent, required this.expiryDate, this.isUsed = false});
  Coupon copyWith({bool? isUsed}) => Coupon(id: id, store: store, description: description, code: code, discountPercent: discountPercent, expiryDate: expiryDate, isUsed: isUsed ?? this.isUsed);

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  String get daysLeft {
    final d = expiryDate.difference(DateTime.now()).inDays;
    return d < 0 ? 'Expired' : d == 0 ? 'Expires today' : '$d days left';
  }
}

class AppState extends ChangeNotifier {
  final List<Coupon> _coupons = [
    Coupon(id: '1', store: 'Amazon', description: '20% off electronics', code: 'ELEC20', discountPercent: 20, expiryDate: DateTime.now().add(const Duration(days: 15))),
    Coupon(id: '2', store: 'Target', description: '10% off groceries', code: 'GROC10', discountPercent: 10, expiryDate: DateTime.now().add(const Duration(days: 7))),
    Coupon(id: '3', store: 'Nike', description: '30% off running shoes', code: 'RUN30', discountPercent: 30, expiryDate: DateTime.now().add(const Duration(days: 30))),
    Coupon(id: '4', store: 'Starbucks', description: 'Buy 1 get 1 free', code: 'BOGO', discountPercent: 50, expiryDate: DateTime.now().add(const Duration(days: 3))),
    Coupon(id: '5', store: 'Best Buy', description: '15% off laptops', code: 'LAP15', discountPercent: 15, expiryDate: DateTime.now().subtract(const Duration(days: 5))),
    Coupon(id: '6', store: 'Whole Foods', description: '25% off organic', code: 'ORG25', discountPercent: 25, expiryDate: DateTime.now().add(const Duration(days: 20))),
  ];

  List<Coupon> get coupons => List.unmodifiable(_coupons);
  List<Coupon> get activeCoupons => _coupons.where((c) => !c.isExpired && !c.isUsed).toList();
  List<Coupon> get usedCoupons => _coupons.where((c) => c.isUsed).toList();
  List<Coupon> get expiredCoupons => _coupons.where((c) => c.isExpired && !c.isUsed).toList();
  int get activeCount => activeCoupons.length;
  int get savedTotal => usedCoupons.fold(0, (sum, c) => sum + c.discountPercent);

  void markUsed(String id) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx >= 0) { _coupons[idx] = _coupons[idx].copyWith(isUsed: true); notifyListeners(); }
  }

  void addCoupon(Coupon coupon) { _coupons.add(coupon); notifyListeners(); }
  void deleteCoupon(String id) { _coupons.removeWhere((c) => c.id == id); notifyListeners(); }
}

class CouponClipperApp extends StatefulWidget {
  const CouponClipperApp({super.key});
  @override State<CouponClipperApp> createState() => _CouponClipperAppState();
}

class _CouponClipperAppState extends State<CouponClipperApp> {
  final _state = AppState();
  @override void initState() { super.initState(); _state.addListener(() => setState(() {})); }
  @override Widget build(BuildContext context) {
    return MaterialApp(title: 'Coupon Clipper', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink), home: MainScreen(state: _state));
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  @override Widget build(BuildContext context) {
    final pages = [ActivePage(state: widget.state), UsedPage(state: widget.state), SettingsPage(state: widget.state)];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_offer), label: 'Active'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Used'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class ActivePage extends StatelessWidget {
  final AppState state;
  const ActivePage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    final active = state.activeCoupons;
    final expired = state.expiredCoupons;
    return Scaffold(
      appBar: AppBar(title: const Text('My Coupons'), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${state.activeCount} active')))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (active.isNotEmpty) ...[
          Text('Active', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...active.map((c) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(c.store), subtitle: Text('${c.description} · ${c.daysLeft}'),
            trailing: Chip(label: Text('${c.discountPercent}% OFF')),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CouponDetailPage(state: state, coupon: c))),
          ))),
        ],
        if (expired.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Expired', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...expired.map((c) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(c.store, style: const TextStyle(color: Colors.grey)),
            subtitle: Text('${c.description} · Expired'),
            trailing: const Icon(Icons.timer_off, color: Colors.grey),
          ))),
        ],
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(context), icon: const Icon(Icons.add), label: const Text('Add Coupon')),
    );
  }

  void _showAddDialog(BuildContext context) {
    final storeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Coupon'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: storeCtrl, decoration: const InputDecoration(labelText: 'Store')),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 12),
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
        const SizedBox(height: 12),
        TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Discount %'), keyboardType: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (storeCtrl.text.isNotEmpty) { state.addCoupon(Coupon(id: DateTime.now().millisecondsSinceEpoch.toString(), store: storeCtrl.text, description: descCtrl.text, code: codeCtrl.text, discountPercent: int.tryParse(discountCtrl.text) ?? 10, expiryDate: DateTime.now().add(const Duration(days: 30)))); Navigator.pop(ctx); } }, child: const Text('Save')),
      ],
    ));
  }
}

class CouponDetailPage extends StatelessWidget {
  final AppState state;
  final Coupon coupon;
  const CouponDetailPage({super.key, required this.state, required this.coupon});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(coupon.store), actions: [IconButton(icon: const Icon(Icons.delete), onPressed: () { state.deleteCoupon(coupon.id); Navigator.pop(context); }, tooltip: 'Delete')]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Coupon Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _Row(label: 'Store', value: coupon.store),
          _Row(label: 'Description', value: coupon.description),
          _Row(label: 'Code', value: coupon.code),
          _Row(label: 'Discount', value: '${coupon.discountPercent}%'),
          _Row(label: 'Expires', value: coupon.daysLeft),
        ]))),
        const SizedBox(height: 16),
        if (!coupon.isUsed && !coupon.isExpired)
          FilledButton.icon(onPressed: () { state.markUsed(coupon.id); Navigator.pop(context); }, icon: const Icon(Icons.check), label: const Text('Mark as Used')),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row({required this.label, required this.value});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]));
}

class UsedPage extends StatelessWidget {
  final AppState state;
  const UsedPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    final used = state.usedCoupons;
    return Scaffold(
      appBar: AppBar(title: const Text('Used Coupons')),
      body: used.isEmpty
        ? const Center(child: Text('No used coupons yet'))
        : ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Text('Savings Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${used.length} coupons used'),
            ]))),
            const SizedBox(height: 16),
            ...used.map((c) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(c.store), subtitle: Text(c.description), trailing: const Icon(Icons.check_circle, color: Colors.green)))),
          ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(title: const Text('Notifications'), subtitle: const Text('Expiry reminders'), leading: const Icon(Icons.notifications), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('Categories'), subtitle: const Text('Manage store categories'), leading: const Icon(Icons.category), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('About'), subtitle: const Text('Coupon Clipper v1.0'), leading: const Icon(Icons.info), onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('About'), content: const Text('Coupon Clipper helps you organize and track your coupons and discounts.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]))),
      ]),
    );
  }
}
