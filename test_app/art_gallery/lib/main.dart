import 'package:flutter/material.dart';

void main() {
  runApp(const ArtGalleryApp());
}

// --- Data Models ---

class Artwork {
  final String title;
  final String artistName;
  final String medium;
  final int year;
  final String dimensions;
  final String description;
  bool isFavorite;

  Artwork({
    required this.title,
    required this.artistName,
    required this.medium,
    required this.year,
    this.dimensions = '73.7 cm x 92.1 cm',
    this.description = 'A masterpiece of world art.',
    this.isFavorite = false,
  });
}

class Artist {
  final String name;
  final String nationality;
  final String style;
  final String bio;

  const Artist({
    required this.name,
    required this.nationality,
    required this.style,
    required this.bio,
  });
}

class Exhibition {
  final String name;
  final String dates;
  final String location;
  final String featuredArtist;

  const Exhibition({
    required this.name,
    required this.dates,
    required this.location,
    required this.featuredArtist,
  });
}

// --- Data ---

final List<Artwork> artworks = [
  Artwork(
    title: 'Starry Night',
    artistName: 'Van Gogh',
    medium: 'Oil on Canvas',
    year: 1889,
    dimensions: '73.7 cm x 92.1 cm',
    description:
        'A swirling night sky over a village, painted during Van Gogh\'s stay at the Saint-Paul-de-Mausole asylum.',
  ),
  Artwork(
    title: 'The Persistence of Memory',
    artistName: 'Dali',
    medium: 'Oil on Canvas',
    year: 1931,
    dimensions: '24.1 cm x 33 cm',
    description:
        'Melting clocks in a dreamlike landscape, one of the most recognizable works of Surrealism.',
  ),
  Artwork(
    title: 'Girl with a Pearl Earring',
    artistName: 'Vermeer',
    medium: 'Oil on Canvas',
    year: 1665,
    dimensions: '44.5 cm x 39 cm',
    description:
        'Often called the Mona Lisa of the North, this tronie depicts a girl wearing an exotic dress and a large pearl earring.',
  ),
  Artwork(
    title: 'The Great Wave',
    artistName: 'Hokusai',
    medium: 'Woodblock Print',
    year: 1831,
    dimensions: '25.7 cm x 37.8 cm',
    description:
        'A towering wave threatens boats off the coast of Kanagawa, with Mount Fuji in the background.',
  ),
  Artwork(
    title: 'Water Lilies',
    artistName: 'Monet',
    medium: 'Oil on Canvas',
    year: 1906,
    dimensions: '89.9 cm x 100.3 cm',
    description:
        'Part of a series of approximately 250 oil paintings depicting Monet\'s flower garden at Giverny.',
  ),
  Artwork(
    title: 'The Kiss',
    artistName: 'Klimt',
    medium: 'Oil and Gold Leaf',
    year: 1908,
    dimensions: '180 cm x 180 cm',
    description:
        'A couple embracing, richly decorated in elaborate robes with gold leaf patterns.',
  ),
];

final List<Artist> artists = [
  const Artist(
    name: 'Van Gogh',
    nationality: 'Dutch',
    style: 'Post-Impressionism',
    bio:
        'Vincent van Gogh was a Dutch Post-Impressionist painter who posthumously became one of the most famous and influential figures in Western art history.',
  ),
  const Artist(
    name: 'Dali',
    nationality: 'Spanish',
    style: 'Surrealism',
    bio:
        'Salvador Dali was a Spanish Surrealist artist renowned for his technical skill, precise draftsmanship, and striking imagery.',
  ),
  const Artist(
    name: 'Monet',
    nationality: 'French',
    style: 'Impressionism',
    bio:
        'Claude Monet was a French painter and founder of Impressionist painting, known for his landscapes and water lily series.',
  ),
];

final List<Exhibition> exhibitions = [
  const Exhibition(
    name: 'Impressionist Masters',
    dates: 'Mar 1 - Jun 30',
    location: 'Main Hall',
    featuredArtist: 'Monet',
  ),
  const Exhibition(
    name: 'Modern Visions',
    dates: 'Apr 15 - Jul 31',
    location: 'East Wing',
    featuredArtist: 'Dali',
  ),
];

// --- App ---

class ArtGalleryApp extends StatelessWidget {
  const ArtGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Art Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    GalleryTab(),
    ArtistsTab(),
    ExhibitionsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Gallery'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'about') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'about',
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Artists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Exhibitions',
          ),
        ],
      ),
    );
  }
}

// --- Gallery Tab ---

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtworkDetailScreen(artwork: artwork),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.deepPurple.shade100,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artwork.artistName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${artwork.medium}, ${artwork.year}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Artists Tab ---

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});

  int _artworkCount(String artistName) {
    return artworks.where((a) => a.artistName == artistName).length;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final count = _artworkCount(artist.name);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              artist.name[0],
              style: TextStyle(color: Colors.deepPurple.shade700),
            ),
          ),
          title: Text(artist.name),
          subtitle: Text(
            '${artist.nationality} · ${artist.style} · $count ${count == 1 ? "work" : "works"}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistProfileScreen(artist: artist),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Exhibitions Tab ---

class ExhibitionsTab extends StatelessWidget {
  const ExhibitionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exhibitions.length,
      itemBuilder: (context, index) {
        final exhibition = exhibitions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(exhibition.name),
            subtitle: Text(
              '${exhibition.dates}\n${exhibition.location} · Featured: ${exhibition.featuredArtist}',
            ),
            isThreeLine: true,
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.event),
            ),
          ),
        );
      },
    );
  }
}

// --- Artwork Detail Screen ---

class ArtworkDetailScreen extends StatefulWidget {
  final Artwork artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: Colors.deepPurple.shade200,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              artwork.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              artwork.artistName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 12),
            _detailRow('Year', '${artwork.year}'),
            _detailRow('Medium', artwork.medium),
            _detailRow('Dimensions', artwork.dimensions),
            const SizedBox(height: 12),
            Text(
              artwork.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    artwork.isFavorite = !artwork.isFavorite;
                  });
                },
                icon: Icon(
                  artwork.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(artwork.isFavorite ? 'Favorited' : 'Favorite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Artist Profile Screen ---

class ArtistProfileScreen extends StatelessWidget {
  final Artist artist;

  const ArtistProfileScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final artistWorks =
        artworks.where((a) => a.artistName == artist.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(
                  artist.name[0],
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                artist.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${artist.nationality} · ${artist.style}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Biography',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(artist.bio),
            const SizedBox(height: 20),
            Text(
              'Artworks (${artistWorks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...artistWorks.map(
              (work) => Card(
                child: ListTile(
                  title: Text(work.title),
                  subtitle: Text('${work.medium}, ${work.year}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtworkDetailScreen(artwork: work),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- About Screen ---

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.museum,
                size: 80,
                color: Colors.deepPurple.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Art Gallery',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            _infoRow(Icons.info, 'About',
                'A curated collection of masterworks from around the world, spanning centuries of artistic achievement.'),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time, 'Hours',
                'Tuesday - Sunday: 10:00 AM - 6:00 PM\nMonday: Closed'),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on, 'Address',
                '123 Museum Drive\nArt District, NY 10001'),
            const SizedBox(height: 12),
            _infoRow(Icons.phone, 'Contact', '(555) 123-4567'),
            const SizedBox(height: 12),
            _infoRow(Icons.email, 'Email', 'info@artgallery.com'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple.shade300, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
