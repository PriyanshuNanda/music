import 'dart:convert';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';

class PythonService {
  static final PythonService _instance = PythonService._internal();
  factory PythonService() => _instance;
  PythonService._internal();

  final _pythonBridge = PythonBridge();

  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    if (query.isEmpty) return [];

    try {
      final result = await _pythonBridge.runCode('''
import os
import sys

app_root = '/data/data/com.example.ymusic/files'
os.chdir(app_root)
print(f'Changed working directory to: {os.getcwd()}')

asset_finder_path = os.path.join(app_root, 'chaquopy/AssetFinder/app')
if asset_finder_path not in sys.path:
    sys.path.append(asset_finder_path)

try:
    from services import api
    query = "$query"
    results = api.search_songs(query)
    import json
    if isinstance(results, list):
        formatted_results = []
        for song in results[:50]:
            try:
                artists = song.get('artists', [])
                artist_name = artists[0].get('name', 'Unknown') if artists else 'Unknown'
                thumbnails = song.get('thumbnails', [])
                thumbnail_url = thumbnails[-1].get('url') if thumbnails else ''
                formatted_results.append({
                    'title': song.get('title', 'Unknown'),
                    'artist': artist_name,
                    'duration': song.get('duration', 'Unknown'),
                    'videoId': song.get('videoId', ''),
                    'thumbnailUrl': thumbnail_url
                })
            except (IndexError, AttributeError) as e:
                print(f'Error formatting song: {str(e)}')
                continue
        results = formatted_results
    print(f'Search results: {json.dumps(formatted_results if "formatted_results" in locals() else [])}')
except Exception as e:
    print(f'Error accessing directory: {str(e)}')
''');

      if (result.output != null) {
        final resultsStart = result.output!.indexOf('Search results:');
        if (resultsStart != -1) {
          String jsonString =
              result.output!.substring(resultsStart + 15).trim();

          final startBracket = jsonString.indexOf('[');
          final endBracket = jsonString.lastIndexOf(']');
          if (startBracket != -1 && endBracket != -1) {
            jsonString = jsonString.substring(startBracket, endBracket + 1);
            List<dynamic> parsed = jsonDecode(jsonString) as List<dynamic>;
            return List<Map<String, dynamic>>.from(parsed);
          }
        }
      }
      return [];
    } catch (e) {
      print('Error in searchSongs: $e');
      return [];
    }
  }
}
