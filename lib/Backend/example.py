from services import search_songs, download_song

def download_favorite_song(artist_name, song_keyword):
    """
    Example function showing how to use the YouTube Music module
    to search for and download a specific song
    """
    print(f"\nSearching for '{song_keyword}' by {artist_name}...")
    
    # Search for songs
    search_query = f"{artist_name} {song_keyword}"
    results = search_songs(search_query)
    
    # Find first matching song
    for song in results:
        if (song_keyword.lower() in song['title'].lower() and 
            artist_name.lower() in song['artists'][0]['name'].lower()):
            print(f"\nFound matching song: {song['title']} by {song['artists'][0]['name']}")
            
            # Download the song
            file_path = download_song(song['videoId'], song['title'])
            if file_path:
                print(f"\nSuccessfully downloaded to: {file_path}")
            return
    
    print(f"\nNo exact match found for '{song_keyword}' by {artist_name}")

if __name__ == "__main__":
    # Example usage
    artist = "Lauv"
    song = "Mean It"
    download_favorite_song(artist, song)
