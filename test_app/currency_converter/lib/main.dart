import 'package:flutter/material.dart';

void main() => runApp(const CurrencyConverterApp());

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const CurrencyConverterHome(),
    );
  }
}

class Currency {
  final String code;
  final String name;
  final String symbol;
  final double rateToUsd;
  bool isFavorite;
  Currency({required this.code, required this.name, required this.symbol,
            required this.rateToUsd, this.isFavorite = false});
}

class CurrencyConverterHome extends StatefulWidget {
  const CurrencyConverterHome({super.key});
  @override
  State<CurrencyConverterHome> createState() => _CurrencyConverterHomeState();
}

class _CurrencyConverterHomeState extends State<CurrencyConverterHome> {
  final _amountCtrl = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _result = 0;

  final List<Currency> _currencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', rateToUsd: 1.0),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', rateToUsd: 0.92),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', rateToUsd: 0.79),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', rateToUsd: 149.50),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', rateToUsd: 1.53),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', rateToUsd: 1.36),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', rateToUsd: 0.88),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', rateToUsd: 83.12),
  ];

  void _convert() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final fromRate = _currencies.firstWhere((c) => c.code == _fromCurrency).rateToUsd;
    final toRate = _currencies.firstWhere((c) => c.code == _toCurrency).rateToUsd;
    setState(() => _result = (amount / fromRate) * toRate);
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convert();
    });
  }

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    final toSymbol = _currencies.firstWhere((c) => c.code == _toCurrency).symbol;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoriteCurrenciesPage(
                  currencies: _currencies,
                  onToggle: (c) => setState(() => c.isFavorite = !c.isFavorite),
                ))),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Rates',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AllRatesPage(currencies: _currencies, baseCurrency: _fromCurrency))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Amount input
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _convert(),
            ),
            const SizedBox(height: 16),
            // From currency
            DropdownButtonFormField<String>(
              value: _fromCurrency,
              decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
              items: _currencies.map((c) =>
                  DropdownMenuItem(value: c.code, child: Text('${c.code} — ${c.name}'))).toList(),
              onChanged: (v) {
                setState(() => _fromCurrency = v!);
                _convert();
              },
            ),
            const SizedBox(height: 8),
            // Swap button
            IconButton(
              icon: const Icon(Icons.swap_vert, size: 32),
              tooltip: 'Swap',
              onPressed: _swap,
            ),
            const SizedBox(height: 8),
            // To currency
            DropdownButtonFormField<String>(
              value: _toCurrency,
              decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
              items: _currencies.map((c) =>
                  DropdownMenuItem(value: c.code, child: Text('${c.code} — ${c.name}'))).toList(),
              onChanged: (v) {
                setState(() => _toCurrency = v!);
                _convert();
              },
            ),
            const SizedBox(height: 24),
            // Result
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$toSymbol ${_result.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_amountCtrl.text} $_fromCurrency = ${_result.toStringAsFixed(2)} $_toCurrency',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Convert button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _convert,
                child: const Text('Convert'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteCurrenciesPage extends StatelessWidget {
  final List<Currency> currencies;
  final ValueChanged<Currency> onToggle;
  const FavoriteCurrenciesPage({super.key, required this.currencies, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final favs = currencies.where((c) => c.isFavorite).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Currencies')),
      body: favs.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: favs.length,
              itemBuilder: (_, i) => ListTile(
                title: Text('${favs[i].code} — ${favs[i].name}'),
                subtitle: Text('Rate: ${favs[i].rateToUsd} per USD'),
                trailing: IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: 'Remove',
                  onPressed: () => onToggle(favs[i]),
                ),
              ),
            ),
    );
  }
}

class AllRatesPage extends StatelessWidget {
  final List<Currency> currencies;
  final String baseCurrency;
  const AllRatesPage({super.key, required this.currencies, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    final baseRate = currencies.firstWhere((c) => c.code == baseCurrency).rateToUsd;
    return Scaffold(
      appBar: AppBar(title: Text('Rates (1 $baseCurrency)')),
      body: ListView.builder(
        itemCount: currencies.length,
        itemBuilder: (_, i) {
          final c = currencies[i];
          final rate = c.rateToUsd / baseRate;
          return ListTile(
            leading: Text(c.symbol, style: const TextStyle(fontSize: 20)),
            title: Text('${c.code} — ${c.name}'),
            trailing: Text(rate.toStringAsFixed(4), style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
