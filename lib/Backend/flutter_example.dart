import 'dart:convert';
import 'dart:io';

class Song {
  final String videoId;
  final String title;
  final String artist;
  final String duration;

  Song({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      videoId: json['videoId'],
      title: json['title'],
      artist: json['artists'][0]['name'],
      duration: json['duration'],
    );
  }
}

class YTMusicDownloader {
  static Future<List<Song>> searchSongs(String query) async {
    final result = await Process.run('ytmusic-dl', ['search', query]);
    
    if (result.exitCode == 0) {
      final json = jsonDecode(result.stdout);
      if (json['status'] == 'success') {
        return (json['results'] as List)
            .map((songJson) => Song.fromJson(songJson))
            .toList();
      }
      throw Exception(json['message']);
    }
    throw Exception('Search failed: ${result.stderr}');
  }

  static Future<String> downloadSong(Song song) async {
    final result = await Process.run(
      'ytmusic-dl',
      ['download', song.videoId, song.title],
    );
    
    if (result.exitCode == 0) {
      final json = jsonDecode(result.stdout);
      if (json['status'] == 'success') {
        return json['file_path'];
      }
      throw Exception(json['message']);
    }
    throw Exception('Download failed: ${result.stderr}');
  }
}

// Example usage in Flutter:
/*
class _MyHomePageState extends State<MyHomePage> {
  List<Song> songs = [];
  bool isLoading = false;
  final searchController = TextEditingController();

  Future<void> searchSongs() async {
    setState(() => isLoading = true);
    try {
      songs = await YTMusicDownloader.searchSongs(searchController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> downloadSong(Song song) async {
    try {
      final filePath = await YTMusicDownloader.downloadSong(song);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YouTube Music Downloader')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchSongs,
                ),
              ],
            ),
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    title: Text(song.title),
                    subtitle: Text('${song.artist} • ${song.duration}'),
                    trailing: IconButton(
                      icon: Icon(Icons.download),
                      onPressed: () => downloadSong(song),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
*/
