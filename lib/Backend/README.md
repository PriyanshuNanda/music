# YouTube Music Downloader for Flutter

A self-contained Python module for searching and downloading songs from YouTube Music, designed to be used with Flutter applications.

## Project Location

This package is designed to be used directly from your Flutter project:
```
your_flutter_project/
└── lib/
    └── Backend/           # This package
        ├── services/      # Python backend
        └── downloads/     # Downloaded songs
```

## Installation

From your Flutter project root:
```bash
cd lib/Backend
pip install .
```

This will install the `ytmusic-dl` command line tool with all dependencies included.

## Usage in Flutter

### 1. Install the Python Package

First, ensure the Python package is installed:
```bash
cd lib/Backend
pip install .
```

### 2. Use the Flutter Integration Code

Copy the `YTMusicDownloader` class from `flutter_example.dart` into your Flutter project:

```dart
// Search for songs
List<Song> songs = await YTMusicDownloader.searchSongs("search query");

// Download a song
String filePath = await YTMusicDownloader.downloadSong(song);
// Returns path relative to your Flutter project
```

### CLI Commands Used by Flutter

The Flutter code uses these CLI commands:

```bash
# Search for songs (returns JSON)
ytmusic-dl search "query"

# Download a song (returns JSON)
ytmusic-dl download "video_id" "title"
```

## JSON Response Format

All CLI commands return JSON responses for easy parsing in Flutter:

Search Response:
```json
{
  "status": "success",
  "results": [
    {
      "title": "Song Title",
      "videoId": "video123",
      "artists": [{"name": "Artist Name"}],
      "duration": "3:45"
    }
  ]
}
```

Download Response:
```json
{
  "status": "success",
  "file_path": "services/downloads/song.webm"
}
```

Error Response:
```json
{
  "status": "error",
  "message": "Error description"
}
```

## Features

- Search YouTube Music
- Get song details (title, artist, duration)
- Download high-quality audio
- No external dependencies required
- CLI tool with JSON output
- WebM format output
- Relative paths for Flutter integration

## Dependencies (All Included)

All required libraries are included locally in the `libs` directory:
- ytmusicapi: YouTube Music API client
- yt-dlp: YouTube downloader
- requests: HTTP client
- urllib3: HTTP client library
- websockets: WebSocket client
- certifi: SSL/TLS certificates

## Media Player Support

The downloaded WebM files can be played with:
- Flutter's video_player plugin (with webm support)
- VLC Media Player
- MPC-HC (Media Player Classic)
- PotPlayer
- Modern web browsers

## Project Structure
```
Backend/
├── services/
│   ├── __init__.py  # Package exports
│   ├── api.py       # Core functionality
│   ├── cli.py       # CLI interface
│   ├── downloads/   # Downloaded files
│   └── libs/        # Local dependencies
├── setup.py         # Package configuration
└── flutter_example.dart  # Flutter integration example
```

## Relative Paths

All paths in responses are relative to your Flutter project root, making it easy to:
1. Locate downloaded files
2. Play files from Flutter
3. Move the project without breaking paths
4. Work across different platforms
