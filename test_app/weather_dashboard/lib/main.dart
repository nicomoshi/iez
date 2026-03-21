import 'package:flutter/material.dart';

void main() => runApp(const WeatherDashboardApp());

class WeatherDashboardApp extends StatelessWidget {
  const WeatherDashboardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true),
      home: const WeatherHome(),
    );
  }
}

class CityWeather {
  final String city;
  final int temp;
  final String condition;
  final int humidity;
  final int wind;
  final List<DayForecast> forecast;
  CityWeather({
    required this.city,
    required this.temp,
    required this.condition,
    required this.humidity,
    required this.wind,
    required this.forecast,
  });
}

class DayForecast {
  final String day;
  final int high;
  final int low;
  final String condition;
  DayForecast({required this.day, required this.high, required this.low, required this.condition});
}

final _cities = [
  CityWeather(city: 'San Francisco', temp: 18, condition: 'Foggy', humidity: 78, wind: 15, forecast: [
    DayForecast(day: 'Mon', high: 19, low: 13, condition: 'Cloudy'),
    DayForecast(day: 'Tue', high: 20, low: 14, condition: 'Sunny'),
    DayForecast(day: 'Wed', high: 18, low: 12, condition: 'Foggy'),
    DayForecast(day: 'Thu', high: 21, low: 15, condition: 'Sunny'),
    DayForecast(day: 'Fri', high: 17, low: 11, condition: 'Rain'),
  ]),
  CityWeather(city: 'New York', temp: 25, condition: 'Sunny', humidity: 55, wind: 10, forecast: [
    DayForecast(day: 'Mon', high: 27, low: 20, condition: 'Sunny'),
    DayForecast(day: 'Tue', high: 26, low: 19, condition: 'Cloudy'),
    DayForecast(day: 'Wed', high: 24, low: 18, condition: 'Rain'),
    DayForecast(day: 'Thu', high: 28, low: 21, condition: 'Sunny'),
    DayForecast(day: 'Fri', high: 25, low: 19, condition: 'Cloudy'),
  ]),
  CityWeather(city: 'Tokyo', temp: 30, condition: 'Humid', humidity: 85, wind: 8, forecast: [
    DayForecast(day: 'Mon', high: 32, low: 26, condition: 'Humid'),
    DayForecast(day: 'Tue', high: 31, low: 25, condition: 'Rain'),
    DayForecast(day: 'Wed', high: 29, low: 24, condition: 'Cloudy'),
    DayForecast(day: 'Thu', high: 33, low: 27, condition: 'Sunny'),
    DayForecast(day: 'Fri', high: 30, low: 25, condition: 'Humid'),
  ]),
  CityWeather(city: 'London', temp: 15, condition: 'Rainy', humidity: 82, wind: 20, forecast: [
    DayForecast(day: 'Mon', high: 16, low: 10, condition: 'Rain'),
    DayForecast(day: 'Tue', high: 14, low: 9, condition: 'Cloudy'),
    DayForecast(day: 'Wed', high: 17, low: 11, condition: 'Sunny'),
    DayForecast(day: 'Thu', high: 13, low: 8, condition: 'Rain'),
    DayForecast(day: 'Fri', high: 15, low: 10, condition: 'Cloudy'),
  ]),
];

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});
  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  bool _useCelsius = true;

  String _tempStr(int celsius) => _useCelsius ? '$celsius°C' : '${(celsius * 9 / 5 + 32).round()}°F';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              final result = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => SettingsPage(useCelsius: _useCelsius)));
              if (result != null) setState(() => _useCelsius = result);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _cities.length,
        itemBuilder: (_, i) {
          final city = _cities[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CityDetailPage(city: city, tempStr: _tempStr))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(city.city, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(_tempStr(city.temp), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(city.condition, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.water_drop, size: 16, color: Colors.blue[300]),
                        Text(' ${city.humidity}%'),
                        const SizedBox(width: 16),
                        Icon(Icons.air, size: 16, color: Colors.grey[500]),
                        Text(' ${city.wind} km/h'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CityDetailPage extends StatelessWidget {
  final CityWeather city;
  final String Function(int) tempStr;
  const CityDetailPage({super.key, required this.city, required this.tempStr});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(city.city)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(tempStr(city.temp), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  Text(city.condition, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Humidity: ${city.humidity}%'),
                      const SizedBox(width: 24),
                      Text('Wind: ${city.wind} km/h'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('5-Day Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...city.forecast.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text(f.day, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(child: Text(f.condition)),
                  Text('${tempStr(f.high)} / ${tempStr(f.low)}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool useCelsius;
  const SettingsPage({super.key, required this.useCelsius});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _useCelsius;

  @override
  void initState() {
    super.initState();
    _useCelsius = widget.useCelsius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Celsius'),
            subtitle: Text(_useCelsius ? 'Showing °C' : 'Showing °F'),
            value: _useCelsius,
            onChanged: (v) => setState(() => _useCelsius = v),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Weather Dashboard v1.0'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _useCelsius),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
