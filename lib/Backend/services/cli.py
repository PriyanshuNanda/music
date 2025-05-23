import sys
import json
from pathlib import Path
from .api import search_songs, download_song

def search_command(query):
    """Search for songs and return JSON results"""
    try:
        results = search_songs(query)
        print(json.dumps({
            'status': 'success',
            'results': results
        }, ensure_ascii=False))  # ensure_ascii=False for proper unicode handling
        return 0
    except Exception as e:
        print(json.dumps({
            'status': 'error',
            'message': str(e)
        }))
        return 1

def download_command(video_id, title):
    """Download a specific song and return JSON result with relative path"""
    try:
        file_path = download_song(video_id, title)
        if file_path:
            print(json.dumps({
                'status': 'success',
                'file_path': file_path  # path is already relative from api.py
            }))
            return 0
        else:
            print(json.dumps({
                'status': 'error',
                'message': 'Download failed'
            }))
            return 1
    except Exception as e:
        print(json.dumps({
            'status': 'error',
            'message': str(e)
        }))
        return 1

def main():
    """CLI entry point"""
    if len(sys.argv) < 2:
        print(json.dumps({
            'status': 'error',
            'message': 'Command required: search or download'
        }))
        return 1

    command = sys.argv[1]

    if command == 'search' and len(sys.argv) > 2:
        # Search command: ytmusic-dl search "song name"
        query = ' '.join(sys.argv[2:])
        return search_command(query)

    elif command == 'download' and len(sys.argv) > 3:
        # Download command: ytmusic-dl download video_id "song title"
        video_id = sys.argv[2]
        title = ' '.join(sys.argv[3:])
        return download_command(video_id, title)

    else:
        print(json.dumps({
            'status': 'error',
            'message': 'Invalid command. Use: ytmusic-dl search "query" or ytmusic-dl download video_id "title"'
        }))
        return 1

if __name__ == "__main__":
    sys.exit(main())
