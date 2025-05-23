class Song {
  final String title;
  final String artist;
  final String duration;
  final String videoId;
  final String thumbnailUrl;

  Song({
    required this.title,
    required this.artist,
    required this.duration,
    required this.videoId,
    required this.thumbnailUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      duration: json['duration'] as String? ?? 'Unknown',
      videoId: json['videoId'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'duration': duration,
    'videoId': videoId,
    'thumbnailUrl': thumbnailUrl,
  };
}
