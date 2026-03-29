import 'package:flutter/material.dart';

void main() {
  runApp(const AuctionBidApp());
}

class AuctionItem {
  final String id;
  final String name;
  final String category;
  final double startingBid;
  double currentBid;
  final String seller;
  final DateTime endTime;
  final List<Bid> bids;

  AuctionItem({required this.id, required this.name, required this.category, required this.startingBid, required this.currentBid, required this.seller, required this.endTime, List<Bid>? bids}) : bids = bids ?? [];

  bool get isActive => endTime.isAfter(DateTime.now());
  String get timeLeft {
    final d = endTime.difference(DateTime.now());
    if (d.isNegative) return 'Ended';
    if (d.inDays > 0) return '${d.inDays}d left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }
}

class Bid {
  final String bidder;
  final double amount;
  final DateTime time;
  Bid({required this.bidder, required this.amount, required this.time});
}

class AppState extends ChangeNotifier {
  final List<AuctionItem> _items = [
    AuctionItem(id: '1', name: 'Vintage Watch', category: 'Collectibles', startingBid: 100, currentBid: 250, seller: 'John', endTime: DateTime.now().add(const Duration(hours: 12)),
      bids: [Bid(bidder: 'Alice', amount: 150, time: DateTime.now().subtract(const Duration(hours: 3))), Bid(bidder: 'Bob', amount: 250, time: DateTime.now().subtract(const Duration(hours: 1)))]),
    AuctionItem(id: '2', name: 'Oil Painting', category: 'Art', startingBid: 200, currentBid: 450, seller: 'Gallery101', endTime: DateTime.now().add(const Duration(days: 2)),
      bids: [Bid(bidder: 'Carol', amount: 300, time: DateTime.now().subtract(const Duration(days: 1))), Bid(bidder: 'Dave', amount: 450, time: DateTime.now().subtract(const Duration(hours: 5)))]),
    AuctionItem(id: '3', name: 'Signed Baseball', category: 'Sports', startingBid: 50, currentBid: 175, seller: 'SportsShop', endTime: DateTime.now().add(const Duration(days: 3)),
      bids: [Bid(bidder: 'Eve', amount: 175, time: DateTime.now().subtract(const Duration(hours: 8)))]),
    AuctionItem(id: '4', name: 'Antique Desk', category: 'Furniture', startingBid: 500, currentBid: 500, seller: 'HomeGoods', endTime: DateTime.now().add(const Duration(days: 5))),
    AuctionItem(id: '5', name: 'First Edition Book', category: 'Collectibles', startingBid: 75, currentBid: 120, seller: 'BookWorm', endTime: DateTime.now().subtract(const Duration(hours: 2)),
      bids: [Bid(bidder: 'Frank', amount: 120, time: DateTime.now().subtract(const Duration(hours: 3)))]),
  ];

  List<AuctionItem> get items => List.unmodifiable(_items);
  List<AuctionItem> get activeItems => _items.where((i) => i.isActive).toList();
  List<AuctionItem> get endedItems => _items.where((i) => !i.isActive).toList();
  int get activeCount => activeItems.length;

  void placeBid(String itemId, double amount, String bidder) {
    final item = _items.firstWhere((i) => i.id == itemId);
    item.currentBid = amount;
    item.bids.add(Bid(bidder: bidder, amount: amount, time: DateTime.now()));
    notifyListeners();
  }

  void addItem(AuctionItem item) { _items.add(item); notifyListeners(); }
}

class AuctionBidApp extends StatefulWidget {
  const AuctionBidApp({super.key});
  @override State<AuctionBidApp> createState() => _AuctionBidAppState();
}

class _AuctionBidAppState extends State<AuctionBidApp> {
  final _state = AppState();
  @override void initState() { super.initState(); _state.addListener(() => setState(() {})); }
  @override Widget build(BuildContext context) {
    return MaterialApp(title: 'Auction Bid', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber), home: MainScreen(state: _state));
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
    final pages = [BrowsePage(state: widget.state), MyBidsPage(state: widget.state), SettingsPage(state: widget.state)];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.gavel), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'My Bids'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class BrowsePage extends StatelessWidget {
  final AppState state;
  const BrowsePage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    final active = state.activeItems;
    final ended = state.endedItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Auctions'), actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${state.activeCount} live')))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Live Auctions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...active.map((item) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          title: Text(item.name), subtitle: Text('${item.category} · \$${item.currentBid.toStringAsFixed(0)} · ${item.timeLeft}'),
          trailing: Text('${item.bids.length} bids', style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(state: state, item: item))),
        ))),
        if (ended.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Ended', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...ended.map((item) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(item.name, style: const TextStyle(color: Colors.grey)),
            subtitle: Text('Final: \$${item.currentBid.toStringAsFixed(0)}'),
            trailing: const Text('Ended'),
          ))),
        ],
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('New Auction')),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Collectibles';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Auction'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
        const SizedBox(height: 12),
        TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Starting Bid'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: ['Collectibles', 'Art', 'Sports', 'Furniture', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => category = v ?? category),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (nameCtrl.text.isNotEmpty) { final price = double.tryParse(priceCtrl.text) ?? 10; state.addItem(AuctionItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text, category: category, startingBid: price, currentBid: price, seller: 'You', endTime: DateTime.now().add(const Duration(days: 7)))); Navigator.pop(ctx); } }, child: const Text('Create')),
      ],
    ));
  }
}

class ItemDetailPage extends StatelessWidget {
  final AppState state;
  final AuctionItem item;
  const ItemDetailPage({super.key, required this.state, required this.item});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Item Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _Row(label: 'Name', value: item.name),
          _Row(label: 'Category', value: item.category),
          _Row(label: 'Seller', value: item.seller),
          _Row(label: 'Starting Bid', value: '\$${item.startingBid.toStringAsFixed(0)}'),
          _Row(label: 'Current Bid', value: '\$${item.currentBid.toStringAsFixed(0)}'),
          _Row(label: 'Time Left', value: item.timeLeft),
          _Row(label: 'Total Bids', value: '${item.bids.length}'),
        ]))),
        if (item.bids.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Bid History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...item.bids.reversed.map((b) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(b.bidder), trailing: Text('\$${b.amount.toStringAsFixed(0)}')))),
        ],
        if (item.isActive) ...[
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _showBidDialog(context), icon: const Icon(Icons.gavel), label: const Text('Place Bid')),
        ],
      ]),
    );
  }

  void _showBidDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '${(item.currentBid + 25).toStringAsFixed(0)}');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Place Bid'),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Your bid (min \$${(item.currentBid + 1).toStringAsFixed(0)})'), keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { final amount = double.tryParse(ctrl.text) ?? 0; if (amount > item.currentBid) { state.placeBid(item.id, amount, 'You'); Navigator.pop(ctx); } }, child: const Text('Bid')),
      ],
    ));
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row({required this.label, required this.value});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]));
}

class MyBidsPage extends StatelessWidget {
  final AppState state;
  const MyBidsPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    final myBids = state.items.where((i) => i.bids.any((b) => b.bidder == 'You')).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My Bids')),
      body: myBids.isEmpty
        ? const Center(child: Text('No bids placed yet'))
        : ListView(padding: const EdgeInsets.all(16), children: myBids.map((item) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(item.name), subtitle: Text('\$${item.currentBid.toStringAsFixed(0)} · ${item.timeLeft}'),
            trailing: Icon(item.isActive ? Icons.timer : Icons.check_circle, color: item.isActive ? Colors.orange : Colors.green),
          ))).toList()),
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
        ListTile(title: const Text('Bid Alerts'), subtitle: const Text('Get notified when outbid'), leading: const Icon(Icons.notifications), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('Payment'), subtitle: const Text('Manage payment methods'), leading: const Icon(Icons.credit_card), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('About'), subtitle: const Text('Auction Bid v1.0'), leading: const Icon(Icons.info), onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('About'), content: const Text('Auction Bid lets you browse, bid on, and create auctions for unique items.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]))),
      ]),
    );
  }
}
