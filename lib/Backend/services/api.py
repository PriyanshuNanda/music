import sys
from pathlib import Path

# Add libs directory to Python path using relative paths
CURRENT_DIR = Path(__file__).resolve().parent
LIBS_DIR = CURRENT_DIR / 'libs'
sys.path.insert(0, str(LIBS_DIR))

try:
    from ytmusicapi import YTMusic
    import yt_dlp
except ImportError as e:
    print(f"Error importing local libraries: {str(e)}")
    print("Make sure all required files are in the Backend/services/libs directory")
    sys.exit(1)

import json
import os

ytmusic = YTMusic()

# Create downloads directory relative to this file
downloads_dir = CURRENT_DIR / "downloads"
downloads_dir.mkdir(exist_ok=True)

# Configure yt-dlp for audio download
ydl_opts = {
    'format': 'bestaudio',  # Get best quality audio
    'outtmpl': str(downloads_dir / '%(title)s.%(ext)s'),
}

def get_relative_path(absolute_path):
    """Convert absolute path to path relative to working directory"""
    try:
        return str(Path(absolute_path).relative_to(os.getcwd()))
    except ValueError:
        return absolute_path

def download_song(video_id, title):
    """
    Download a song in its original audio format
    Args:
        video_id (str): YouTube video ID
        title (str): Song title
    Returns:
        str: Path to audio file or None if error
    """
    try:
        print(f"\nDownloading: {title}")
        url = f"https://music.youtube.com/watch?v={video_id}"
        
        # Clear existing files in downloads directory
        for file in downloads_dir.iterdir():
            try:
                os.remove(file)
            except:
                pass
        
        # Download the song
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            error_code = ydl.download([url])
            if error_code != 0:
                print("Error downloading song")
                return None
        
        # Find the downloaded audio file
        downloaded_files = list(downloads_dir.iterdir())
        if downloaded_files:
            file_path = str(downloaded_files[0])
            relative_path = get_relative_path(file_path)
            print(f"Downloaded audio file: {relative_path}")
            return relative_path
        
        return None
            
    except Exception as e:
        print(f"Error downloading song: {str(e)}")
        return None

def search_songs(query, limit=10):
    """
    Search for songs on YouTube Music
    Args:
        query (str): Search query (artist or song name)
        limit (int): Maximum number of results to return (default: 10)
    Returns:
        list: List of songs with their details
    """
    try:
        if not query.strip():
            print("Error: Search query cannot be empty")
            return []
        
        search_results = ytmusic.search(query=query, filter="songs")
        return search_results[:limit]
    except Exception as e:
        print(f"Error searching for songs: {str(e)}")
        return []

def print_song_details(songs):
    """
    Print formatted song details
    Args:
        songs (list): List of song dictionaries
    """
    if not songs:
        print("No songs found.")
        return

    for i, song in enumerate(songs, 1):
        print(f"\nSong {i}:")
        print(f"Title: {song['title']}")
        print(f"Artist: {song['artists'][0]['name']}")
        print(f"Duration: {song['duration']}")
        print(f"YouTube Music URL: https://music.youtube.com/watch?v={song['videoId']}")

def main():
    """Main program loop"""
    try:
        while True:
            query = input("\nEnter song or artist name to search (or 'q' to quit): ")
            if query.lower() == 'q':
                break
                
            search_results = search_songs(query)
            print_song_details(search_results)
            
            # Get song selection for download
            song_number = input("\nEnter song number to download (or Enter to skip): ")
            if song_number.strip() and song_number.isdigit():
                idx = int(song_number) - 1
                if 0 <= idx < len(search_results):
                    song = search_results[idx]
                    file_path = download_song(song['videoId'], song['title'])
                    if file_path:
                        print("\nDownload complete!")
                        print(f"Audio file saved as: {file_path}")
                        print("You can play this file with any media player that supports WebM audio")

    except KeyboardInterrupt:
        print("\nProgram terminated by user")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    main()
