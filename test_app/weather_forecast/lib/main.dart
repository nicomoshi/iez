import 'package:flutter/material.dart';

void main() {
  runApp(const WeatherForecastApp());
}

class WeatherForecastApp extends StatelessWidget {
  const WeatherForecastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherHomeScreen(),
    );
  }
}

class CityWeather {
  final String city;
  final int tempCurrent;
  final int tempHigh;
  final int tempLow;
  final String condition;
  final IconData icon;
  final int humidity;
  final int windSpeed;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  CityWeather({
    required this.city,
    required this.tempCurrent,
    required this.tempHigh,
    required this.tempLow,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.hourly,
    required this.daily,
  });
}

class HourlyForecast {
  final String time;
  final int temp;
  final IconData icon;
  HourlyForecast({required this.time, required this.temp, required this.icon});
}

class DailyForecast {
  final String day;
  final int high;
  final int low;
  final IconData icon;
  final String condition;
  DailyForecast({required this.day, required this.high, required this.low, required this.icon, required this.condition});
}

final _cities = [
  CityWeather(
    city: 'Sydney',
    tempCurrent: 24,
    tempHigh: 28,
    tempLow: 18,
    condition: 'Partly Cloudy',
    icon: Icons.cloud,
    humidity: 65,
    windSpeed: 15,
    hourly: [
      HourlyForecast(time: 'Now', temp: 24, icon: Icons.cloud),
      HourlyForecast(time: '1PM', temp: 26, icon: Icons.wb_sunny),
      HourlyForecast(time: '2PM', temp: 27, icon: Icons.wb_sunny),
      HourlyForecast(time: '3PM', temp: 28, icon: Icons.wb_sunny),
      HourlyForecast(time: '4PM', temp: 26, icon: Icons.cloud),
      HourlyForecast(time: '5PM', temp: 24, icon: Icons.cloud),
    ],
    daily: [
      DailyForecast(day: 'Mon', high: 28, low: 18, icon: Icons.cloud, condition: 'Cloudy'),
      DailyForecast(day: 'Tue', high: 30, low: 20, icon: Icons.wb_sunny, condition: 'Sunny'),
      DailyForecast(day: 'Wed', high: 25, low: 17, icon: Icons.grain, condition: 'Rain'),
      DailyForecast(day: 'Thu', high: 22, low: 15, icon: Icons.grain, condition: 'Rain'),
      DailyForecast(day: 'Fri', high: 26, low: 18, icon: Icons.wb_sunny, condition: 'Sunny'),
    ],
  ),
  CityWeather(
    city: 'Tokyo',
    tempCurrent: 18,
    tempHigh: 22,
    tempLow: 12,
    condition: 'Sunny',
    icon: Icons.wb_sunny,
    humidity: 45,
    windSpeed: 10,
    hourly: [
      HourlyForecast(time: 'Now', temp: 18, icon: Icons.wb_sunny),
      HourlyForecast(time: '1PM', temp: 20, icon: Icons.wb_sunny),
      HourlyForecast(time: '2PM', temp: 22, icon: Icons.wb_sunny),
      HourlyForecast(time: '3PM', temp: 21, icon: Icons.cloud),
      HourlyForecast(time: '4PM', temp: 19, icon: Icons.cloud),
      HourlyForecast(time: '5PM', temp: 17, icon: Icons.cloud),
    ],
    daily: [
      DailyForecast(day: 'Mon', high: 22, low: 12, icon: Icons.wb_sunny, condition: 'Sunny'),
      DailyForecast(day: 'Tue', high: 20, low: 11, icon: Icons.cloud, condition: 'Cloudy'),
      DailyForecast(day: 'Wed', high: 18, low: 10, icon: Icons.grain, condition: 'Rain'),
      DailyForecast(day: 'Thu', high: 23, low: 14, icon: Icons.wb_sunny, condition: 'Sunny'),
      DailyForecast(day: 'Fri', high: 24, low: 15, icon: Icons.wb_sunny, condition: 'Sunny'),
    ],
  ),
  CityWeather(
    city: 'London',
    tempCurrent: 12,
    tempHigh: 15,
    tempLow: 8,
    condition: 'Rainy',
    icon: Icons.grain,
    humidity: 85,
    windSpeed: 25,
    hourly: [
      HourlyForecast(time: 'Now', temp: 12, icon: Icons.grain),
      HourlyForecast(time: '1PM', temp: 13, icon: Icons.grain),
      HourlyForecast(time: '2PM', temp: 14, icon: Icons.cloud),
      HourlyForecast(time: '3PM', temp: 15, icon: Icons.cloud),
      HourlyForecast(time: '4PM', temp: 13, icon: Icons.grain),
      HourlyForecast(time: '5PM', temp: 11, icon: Icons.grain),
    ],
    daily: [
      DailyForecast(day: 'Mon', high: 15, low: 8, icon: Icons.grain, condition: 'Rain'),
      DailyForecast(day: 'Tue', high: 14, low: 7, icon: Icons.grain, condition: 'Rain'),
      DailyForecast(day: 'Wed', high: 16, low: 9, icon: Icons.cloud, condition: 'Cloudy'),
      DailyForecast(day: 'Thu', high: 18, low: 10, icon: Icons.wb_sunny, condition: 'Sunny'),
      DailyForecast(day: 'Fri', high: 17, low: 9, icon: Icons.cloud, condition: 'Cloudy'),
    ],
  ),
];

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  int _selectedCityIndex = 0;
  bool _isCelsius = true;

  int _convertTemp(int temp) {
    if (_isCelsius) return temp;
    return (temp * 9 / 5 + 32).round();
  }

  String get _unit => _isCelsius ? '°C' : '°F';

  @override
  Widget build(BuildContext context) {
    final weather = _cities[_selectedCityIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(weather.city),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isCelsius = !_isCelsius),
            child: Text(_isCelsius ? '°C / °F' : '°F / °C'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search City',
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: CitySearchDelegate(_cities),
              );
              if (result != null) {
                setState(() => _selectedCityIndex = result);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Weather updated!')),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current weather card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(weather.icon, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      '${_convertTemp(weather.tempCurrent)}$_unit',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    Text(weather.condition, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('H: ${_convertTemp(weather.tempHigh)}$_unit  L: ${_convertTemp(weather.tempLow)}$_unit'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Weather details
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.water_drop),
                          const SizedBox(height: 4),
                          Text('${weather.humidity}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Humidity'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.air),
                          const SizedBox(height: 4),
                          Text('${weather.windSpeed} km/h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Wind'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hourly forecast
            const Text('Hourly Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weather.hourly.length,
                itemBuilder: (ctx, i) {
                  final h = weather.hourly[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(h.time, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Icon(h.icon, size: 24),
                          Text('${_convertTemp(h.temp)}$_unit'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Daily forecast
            const Text('5-Day Forecast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...weather.daily.map((d) => Card(
                  child: ListTile(
                    leading: Icon(d.icon),
                    title: Text(d.day),
                    subtitle: Text(d.condition),
                    trailing: Text('${_convertTemp(d.high)}° / ${_convertTemp(d.low)}°'),
                  ),
                )),

            // City selector
            const SizedBox(height: 16),
            const Text('Other Cities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_cities.length, (i) {
              if (i == _selectedCityIndex) return const SizedBox.shrink();
              final c = _cities[i];
              return Card(
                child: ListTile(
                  leading: Icon(c.icon),
                  title: Text(c.city),
                  subtitle: Text(c.condition),
                  trailing: Text('${_convertTemp(c.tempCurrent)}$_unit',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onTap: () => setState(() => _selectedCityIndex = i),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class CitySearchDelegate extends SearchDelegate<int?> {
  final List<CityWeather> cities;

  CitySearchDelegate(this.cities);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = cities.asMap().entries.where(
      (e) => e.value.city.toLowerCase().contains(query.toLowerCase()),
    );

    return ListView(
      children: results.map((e) => ListTile(
            leading: Icon(e.value.icon),
            title: Text(e.value.city),
            subtitle: Text('${e.value.tempCurrent}°C - ${e.value.condition}'),
            onTap: () => close(context, e.key),
          )).toList(),
    );
  }
}
