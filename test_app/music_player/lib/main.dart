import 'package:flutter/material.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class Song {
  final String title;
  final String artist;
  final Color color;

  const Song({required this.title, required this.artist, required this.color});
}

const List<Song> kSongs = [
  Song(title: 'Sunset Drive', artist: 'The Waves', color: Color(0xFFFF7043)),
  Song(title: 'Midnight Jazz', artist: 'Blue Note Trio', color: Color(0xFF1565C0)),
  Song(title: 'Electric Dreams', artist: 'Synth City', color: Color(0xFF6A1B9A)),
  Song(title: 'Mountain High', artist: 'Nature Sounds', color: Color(0xFF2E7D32)),
  Song(title: 'Urban Groove', artist: 'DJ Metro', color: Color(0xFFF57F17)),
  Song(title: 'Ocean Calm', artist: 'Ambient Works', color: Color(0xFF00838F)),
];

class Playlist {
  final String name;
  final int songCount;

  const Playlist({required this.name, required this.songCount});
}

const List<Playlist> kPlaylists = [
  Playlist(name: 'Favorites', songCount: 3),
  Playlist(name: 'Workout', songCount: 2),
];

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    LibraryScreen(),
    PlaylistsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView.builder(
        itemCount: kSongs.length,
        itemBuilder: (context, index) {
          final song = kSongs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: song.color,
              child: Text(
                song.title[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NowPlayingScreen(song: song),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NowPlayingScreen(song: song),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView.builder(
        itemCount: kPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = kPlaylists[index];
          return ListTile(
            leading: const Icon(Icons.queue_music, size: 40),
            title: Text(playlist.name),
            subtitle: Text('${playlist.songCount} songs'),
          );
        },
      ),
    );
  }
}

class NowPlayingScreen extends StatefulWidget {
  final Song song;

  const NowPlayingScreen({super.key, required this.song});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isPlaying = false;
  bool _isRepeat = false;
  bool _isShuffle = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Album art placeholder
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: widget.song.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.song.color.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.song.title[0],
                  style: const TextStyle(
                    fontSize: 96,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Song title
            Text(
              widget.song.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Artist name
            Text(
              widget.song.artist,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Progress slider
            Slider(
              value: _progress,
              min: 0,
              max: 240,
              onChanged: (value) {
                setState(() {
                  _progress = value;
                });
              },
            ),
            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(_progress.toInt())),
                  Text(_formatTime(240)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Player controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  tooltip: 'Skip Previous',
                  iconSize: 40,
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                  iconSize: 56,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  tooltip: 'Skip Next',
                  iconSize: 40,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Repeat and Shuffle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: _isRepeat
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  tooltip: 'Repeat',
                  onPressed: () {
                    setState(() {
                      _isRepeat = !_isRepeat;
                    });
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: _isShuffle
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  tooltip: 'Shuffle',
                  onPressed: () {
                    setState(() {
                      _isShuffle = !_isShuffle;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Add to Playlist
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to playlist')),
                );
              },
              child: const Text('Add to Playlist'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
