from ytmusicapi import YTMusic
import json

def search_songs(query):
    """Search for songs on YouTube Music"""
    try:
        # Debug information
        import os
        current_dir = os.getcwd()
        print(f"Current working directory: {current_dir}")
        print(f"Directory contents: {os.listdir(current_dir)}")
        
        # List parent directory
        parent_dir = os.path.dirname(current_dir)
        print(f"Parent directory: {parent_dir}")
        print(f"Parent directory contents: {os.listdir(parent_dir)}")
        
        # Initialize YTMusic without authentication
        ytmusic = YTMusic(auth=None)
        search_results = ytmusic.search(query, filter="songs")
        return search_results
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e)}

def download_song(video_id, title):
    """Download a song by video ID"""
    try:
        from yt_dlp import YoutubeDL
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': f'downloads/{title}.%(ext)s',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
        }
        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f'https://music.youtube.com/watch?v={video_id}', download=True)
            return f'downloads/{title}.mp3'
    except Exception as e:
        print(f"Error downloading: {str(e)}")
        return None
