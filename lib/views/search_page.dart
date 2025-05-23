import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../viewmodels/search_view_model.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.title});
  final String title;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  final searchController = TextEditingController();
  final _searchResultsKey = GlobalKey<_SearchResultsState>();
  final _currentSongNotifier = ValueNotifier<Song?>(null);
  final _isPlayingNotifier = ValueNotifier<bool>(false);
  final _positionNotifier = ValueNotifier<Duration>(Duration.zero);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _currentSongNotifier.dispose();
    _isPlayingNotifier.dispose();
    _positionNotifier.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<SearchViewModel>(
                  builder: (context, viewModel, child) {
                    return Column(
                      children: [
                        SearchBar(
                          controller: searchController,
                          onSearch:
                              () =>
                                  viewModel.searchSongs(searchController.text),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SearchResults(
                            key: _searchResultsKey,
                            isLoading: viewModel.isLoading,
                            searchResults: viewModel.searchResults,
                            onSongChange: (song, isPlaying) {
                              _currentSongNotifier.value = song;
                              _isPlayingNotifier.value = isPlaying;
                            },
                            onPositionChange: (position) {
                              _positionNotifier.value = position;
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            ValueListenableBuilder<Song?>(
              valueListenable: _currentSongNotifier,
              builder: (context, currentSong, _) {
                if (currentSong == null) return const SizedBox.shrink();

                return ValueListenableBuilder<bool>(
                  valueListenable: _isPlayingNotifier,
                  builder: (context, isPlaying, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: currentSong.thumbnailUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentSong.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentSong.artist,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Column(
                                      children: [
                                        SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 2,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 6,
                                            ),
                                            overlayShape: const RoundSliderOverlayShape(
                                              overlayRadius: 12,
                                            ),
                                          ),
                                          child: ValueListenableBuilder<Duration>(
                                            valueListenable: _positionNotifier,
                                            builder: (context, position, _) {
                                              final duration = _searchResultsKey.currentState?._duration ?? Duration.zero;
                                              if (duration == Duration.zero) {
                                                return const SizedBox.shrink();
                                              }
                                              return Slider(
                                                value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                                                min: 0,
                                                max: duration.inMilliseconds.toDouble(),
                                                onChangeStart: (_) {
                                                  _searchResultsKey.currentState?._audioService.pause();
                                                },
                                                onChangeEnd: (_) {
                                                  _searchResultsKey.currentState?._audioService.resume();
                                                },
                                                onChanged: (value) {
                                                  final newPosition = Duration(milliseconds: value.round());
                                                  _searchResultsKey.currentState?.seekTo(newPosition);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ValueListenableBuilder<Duration>(
                                              valueListenable: _positionNotifier,
                                              builder: (context, position, _) {
                                                return Text(
                                                  _formatDuration(position),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color
                                                        ?.withOpacity(0.5),
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(
                                              currentSong.duration,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
        ValueListenableBuilder<bool>(
          valueListenable: _searchResultsKey.currentState?._audioService.playingStateNotifier ?? ValueNotifier(false),
          builder: (context, isPlaying, _) {
            return IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await _searchResultsKey.currentState?._audioService.pause();
                } else {
                  await _searchResultsKey.currentState?._audioService.resume();
                }
              },
            );
          },
        ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Search songs...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filled(icon: const Icon(Icons.search), onPressed: onSearch),
      ],
    );
  }
}

class SearchResults extends StatefulWidget {
  const SearchResults({
    super.key,
    required this.isLoading,
    required this.searchResults,
    this.onSongChange,
    this.onPositionChange,
  });

  final bool isLoading;
  final List<Song> searchResults;
  final void Function(Song song, bool isPlaying)? onSongChange;
  final void Function(Duration position)? onPositionChange;

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _audioService = AudioService();
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration?>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() async {
    await _audioService.init();

    _positionSubscription = _audioService.player.positionStream.listen((
      position,
    ) {
      if (position != null) {
        setState(() => _position = position);
        widget.onPositionChange?.call(position);
      }
    });

    _durationSubscription = _audioService.player.durationStream.listen((
      duration,
    ) {
      if (duration != null) {
        setState(() => _duration = duration);
      }
    });

    // Listen for playback state changes
    _playbackSubscription = _audioService.player.playingStream.listen((playing) {
      setState(() => _isPlaying = playing);
      if (_currentSong != null) {
        widget.onSongChange?.call(_currentSong!, playing);
      }
    });
  }

  Future<void> _playSong(Song song) async {
    try {
      // Update UI first for better responsiveness
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentSong = song;
          _isPlaying = true;
          _position = Duration.zero;
        });
        widget.onPositionChange?.call(Duration.zero);
        widget.onSongChange?.call(song, true);
      });

      // Then start playback
      await _audioService.play(song.videoId);
    } catch (e) {
      print('Error playing song: $e');
      setState(() {
        _currentSong = null;
        _isPlaying = false;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.resume();
    }
    final newPlayingState = !_isPlaying;
    setState(() {
      _isPlaying = newPlayingState;
    });
    if (_currentSong != null) {
      widget.onSongChange?.call(_currentSong!, newPlayingState);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seekTo(position);
    setState(() => _position = position);
    widget.onPositionChange?.call(position);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.searchResults.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return Scrollbar(
      child: ListView.builder(
        itemCount: widget.searchResults.length,
        cacheExtent: 200,
        itemBuilder: (context, index) {
          final song = widget.searchResults[index];
          final isSelected = _currentSong?.videoId == song.videoId;

          return Material(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                ),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                song.duration,
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                if (isSelected && _isPlaying) {
                  _togglePlayPause();
                } else {
                  _playSong(song);
                }
              },
              selected: isSelected,
              selectedTileColor: Theme.of(
                context,
              ).primaryColor.withOpacity(0.1),
            ),
          );
        },
      ),
    );
  }
}
