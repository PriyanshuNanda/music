import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/python_service.dart';

class SearchViewModel extends ChangeNotifier {
  final _pythonService = PythonService();

  // Results and state
  List<Song> _searchResults = [];
  List<Song> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _error = '';
  String get error => _error;

  // Search history
  final List<String> _searchHistory = [];
  List<String> get searchHistory => _searchHistory.take(10).toList();

  // Cache with timestamps and memory management
  final Map<String, _CachedResult> _resultsCache = {};
  Timer? _debounceTimer;
  String? _lastQuery;
  CancelableOperation? _currentOperation;
  int _cacheHits = 0;

  // Settings
  static const int _maxCacheSize = 30; // Reduced from 50 to save memory
  static const Duration _cacheExpiration = Duration(hours: 6);

  Future<void> searchSongs(String query) async {
    // Clean up query
    query = query.trim();
    if (query.isEmpty) return;

    // Skip duplicate searches
    if (query == _lastQuery && !_isLoading) return;
    _lastQuery = query;

    // Cancel pending operations
    _debounceTimer?.cancel();
    _currentOperation?.cancel();

    // Update search history
    if (_searchHistory.isEmpty || _searchHistory.first != query) {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);

      if (_searchHistory.length > 20) {
        _searchHistory.removeLast();
      }
    }

    // Debounce to prevent rapid API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // Check cache first (memory efficient)
      final currentTime = DateTime.now();
      if (_resultsCache.containsKey(query)) {
        final cachedResult = _resultsCache[query]!;

        // If cache is valid
        if (currentTime.difference(cachedResult.timestamp) < _cacheExpiration) {
          _cacheHits++;
          _updateState(
            isLoading: false,
            results: cachedResult.songs,
            error: '',
          );

          // If frequently accessed, promote cache lifetime
          if (_cacheHits > 3) {
            _resultsCache[query] = _CachedResult(
              songs: cachedResult.songs,
              timestamp: DateTime.now(), // Update timestamp
            );
          }
          return;
        }
      }

      try {
        // Show loading state
        _updateState(isLoading: true, results: [], error: '');

        // Create cancelable operation
        _currentOperation = CancelableOperation.fromFuture(
              _fetchAndProcessResults(query),
            )
            .then((songs) {
              if (_lastQuery == query) {
                _updateState(isLoading: false, results: songs, error: '');
              }
              return songs;
            })
            .catchError((e) {
              if (_lastQuery == query) {
                _updateState(isLoading: false, error: _formatErrorMessage(e));
                debugPrint('Search error: $e');
              }
              return <Song>[];
            });

        await _currentOperation?.value;
      } catch (e) {
        if (_lastQuery == query) {
          _updateState(isLoading: false, error: _formatErrorMessage(e));
        }
      } finally {
        _currentOperation = null;
      }
    });
  }

  // User-friendly error messages
  String _formatErrorMessage(dynamic error) {
    final errorMessage = error.toString();

    if (errorMessage.contains('SocketException') ||
        errorMessage.contains('Connection refused')) {
      return 'Cannot connect to the server. Please check your internet connection.';
    }

    if (errorMessage.contains('timed out')) {
      return 'Search request timed out. Please try again.';
    }

    if (errorMessage.contains('403')) {
      return 'Access denied by the server. Please try again later.';
    }

    return 'Failed to search songs. Please try again.';
  }

  // Background processing of search results
  Future<List<Song>> _fetchAndProcessResults(String query) async {
    // Fetch with timeout
    final results = await _pythonService
        .searchSongs(query)
        .timeout(const Duration(seconds: 10));

    // Process in background isolate
    final songs = await compute(_parseSongs, results);

    // Manage cache size (LRU strategy)
    _manageCache();

    // Cache the result
    _resultsCache[query] = _CachedResult(
      songs: songs,
      timestamp: DateTime.now(),
    );

    return songs;
  }

  // Manage cache size
  void _manageCache() {
    if (_resultsCache.length >= _maxCacheSize) {
      // Find oldest entry
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _resultsCache.entries) {
        if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
          oldestKey = entry.key;
          oldestTime = entry.value.timestamp;
        }
      }

      if (oldestKey != null) {
        _resultsCache.remove(oldestKey);
      }
    }
  }

  // Process JSON in background
  static List<Song> _parseSongs(List<dynamic> jsonList) {
    return jsonList.map((json) => Song.fromJson(json)).toList();
  }

  // Efficient state updates
  void _updateState({bool? isLoading, List<Song>? results, String? error}) {
    bool shouldNotify = false;

    if (isLoading != null && _isLoading != isLoading) {
      _isLoading = isLoading;
      shouldNotify = true;
    }

    if (results != null) {
      // Only update if different (prevents unnecessary rebuilds)
      if (_searchResults.length != results.length ||
          (_searchResults.isNotEmpty &&
              results.isNotEmpty &&
              _searchResults.first.videoId != results.first.videoId)) {
        _searchResults = results;
        shouldNotify = true;
      }
    }

    if (error != null && _error != error) {
      _error = error;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  // Retry functionality
  void retrySearch() {
    if (_lastQuery != null) {
      final query = _lastQuery!;
      _lastQuery = null;
      searchSongs(query);
    }
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  void clearCache() {
    _resultsCache.clear();
    _cacheHits = 0;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _currentOperation?.cancel();
    super.dispose();
  }
}

class _CachedResult {
  final List<Song> songs;
  final DateTime timestamp;

  _CachedResult({required this.songs, required this.timestamp});
}

class CancelableOperation<T> {
  final Future<T> _future;
  final Completer<T> _completer = Completer<T>();
  bool _isCanceled = false;

  CancelableOperation._(this._future) {
    _future
        .then((value) {
          if (!_isCanceled) {
            _completer.complete(value);
          }
        })
        .catchError((error) {
          if (!_isCanceled) {
            _completer.completeError(error);
          }
        });
  }

  static CancelableOperation<T> fromFuture<T>(Future<T> future) {
    return CancelableOperation._(future);
  }

  Future<T> get value => _completer.future;
  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }

  CancelableOperation<R> then<R>(FutureOr<R> Function(T) onValue) {
    return CancelableOperation._(value.then(onValue));
  }

  CancelableOperation<T> catchError(Function onError) {
    return CancelableOperation._(value.catchError(onError));
  }
}
