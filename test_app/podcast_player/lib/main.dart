import 'package:flutter/material.dart';

void main() => runApp(const PodcastPlayerApp());

class PodcastPlayerApp extends StatelessWidget {
  const PodcastPlayerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcast Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const PodcastHome(),
    );
  }
}

class Episode {
  final String title;
  final String show;
  final String duration;
  final String date;
  bool downloaded;
  bool played;
  Episode({
    required this.title,
    required this.show,
    required this.duration,
    required this.date,
    this.downloaded = false,
    this.played = false,
  });
}

class PodcastHome extends StatefulWidget {
  const PodcastHome({super.key});
  @override
  State<PodcastHome> createState() => _PodcastHomeState();
}

class _PodcastHomeState extends State<PodcastHome> {
  int _currentIndex = 0;
  final List<Episode> _episodes = [
    Episode(title: 'The Future of AI', show: 'Tech Talk', duration: '45 min', date: 'Mar 20'),
    Episode(title: 'Deep Work Habits', show: 'Productivity Pod', duration: '32 min', date: 'Mar 19'),
    Episode(title: 'Startup Secrets', show: 'Business Weekly', duration: '58 min', date: 'Mar 18'),
    Episode(title: 'Flutter State Management', show: 'Code Radio', duration: '40 min', date: 'Mar 17'),
    Episode(title: 'Mindful Morning', show: 'Wellness Hour', duration: '25 min', date: 'Mar 16'),
    Episode(title: 'Market Trends 2026', show: 'Business Weekly', duration: '52 min', date: 'Mar 15'),
    Episode(title: 'Rust vs Go', show: 'Code Radio', duration: '38 min', date: 'Mar 14'),
    Episode(title: 'Sleep Science', show: 'Wellness Hour', duration: '30 min', date: 'Mar 13'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcast Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Downloads',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DownloadsPage(
                  episodes: _episodes.where((e) => e.downloaded).toList(),
                ))),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Queue',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => QueuePage(
                  episodes: _episodes.where((e) => !e.played).toList(),
                ))),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildEpisodesTab(),
          _buildShowsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.headphones), label: 'Episodes'),
          NavigationDestination(icon: Icon(Icons.podcasts), label: 'Shows'),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab() {
    return ListView.builder(
      itemCount: _episodes.length,
      itemBuilder: (_, i) {
        final ep = _episodes[i];
        return ListTile(
          leading: CircleAvatar(child: Icon(ep.played ? Icons.check : Icons.play_arrow)),
          title: Text(ep.title),
          subtitle: Text('${ep.show} · ${ep.duration} · ${ep.date}'),
          trailing: IconButton(
            icon: Icon(ep.downloaded ? Icons.download_done : Icons.download_outlined),
            tooltip: ep.downloaded ? 'Downloaded' : 'Download',
            onPressed: () => setState(() => ep.downloaded = !ep.downloaded),
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => EpisodeDetailPage(episode: ep))),
        );
      },
    );
  }

  Widget _buildShowsTab() {
    final shows = <String, List<Episode>>{};
    for (final ep in _episodes) {
      shows.putIfAbsent(ep.show, () => []).add(ep);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: shows.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.podcasts)),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} episodes'),
          ),
        );
      }).toList(),
    );
  }
}

class EpisodeDetailPage extends StatelessWidget {
  final Episode episode;
  const EpisodeDetailPage({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(episode.show)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(episode.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(episode.show, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(episode.duration)),
                const SizedBox(width: 8),
                Chip(label: Text(episode.date)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('About this episode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('An engaging discussion covering the latest trends and insights in this topic area.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Episode'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadsPage extends StatelessWidget {
  final List<Episode> episodes;
  const DownloadsPage({super.key, required this.episodes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: episodes.isEmpty
          ? const Center(child: Text('No downloads yet'))
          : ListView.builder(
              itemCount: episodes.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(episodes[i].title),
                subtitle: Text(episodes[i].show),
              ),
            ),
    );
  }
}

class QueuePage extends StatelessWidget {
  final List<Episode> episodes;
  const QueuePage({super.key, required this.episodes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Up Next')),
      body: episodes.isEmpty
          ? const Center(child: Text('Queue is empty'))
          : ListView.builder(
              itemCount: episodes.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text('${i + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                title: Text(episodes[i].title),
                subtitle: Text('${episodes[i].show} · ${episodes[i].duration}'),
              ),
            ),
    );
  }
}
