import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'rss.dart';

/// One reading of process memory and the image cache.
@immutable
class MemorySnapshot {
  /// Creates a memory snapshot. Byte counts are null when the platform does
  /// not expose them (process memory on the web).
  const MemorySnapshot({
    required this.rssBytes,
    required this.maxRssBytes,
    required this.imageCacheBytes,
    required this.imageCacheMaxBytes,
    required this.imageCacheCount,
    required this.imageCacheMaxCount,
    required this.liveImageCount,
  });

  /// Reads the current values from the process and from
  /// `PaintingBinding.instance.imageCache`.
  factory MemorySnapshot.capture({ImageCache? imageCache}) {
    final cache = imageCache ?? PaintingBinding.instance.imageCache;
    return MemorySnapshot(
      rssBytes: readCurrentRss(),
      maxRssBytes: readMaxRss(),
      imageCacheBytes: cache.currentSizeBytes,
      imageCacheMaxBytes: cache.maximumSizeBytes,
      imageCacheCount: cache.currentSize,
      imageCacheMaxCount: cache.maximumSize,
      liveImageCount: cache.liveImageCount,
    );
  }

  /// Resident memory of the whole process (Dart heap, engine, GPU-mapped
  /// buffers, native libraries).
  final int? rssBytes;

  /// Highest resident memory the OS has seen for this process.
  final int? maxRssBytes;

  /// Bytes held by decoded images in the image cache.
  final int imageCacheBytes;

  /// Byte limit of the image cache.
  final int imageCacheMaxBytes;

  /// Images held by the cache.
  final int imageCacheCount;

  /// Image count limit of the cache.
  final int imageCacheMaxCount;

  /// Images currently on screen or otherwise held by a listener.
  final int liveImageCount;

  /// Image cache fill level by bytes, `0..1`.
  double get imageCacheFill =>
      imageCacheMaxBytes <= 0 ? 0 : (imageCacheBytes / imageCacheMaxBytes).clamp(0, 1).toDouble();
}

/// Keeps memory history and session peaks.
class MemoryStats {
  /// Creates an empty memory history of [historyLength] samples.
  MemoryStats({this.historyLength = 60}) : assert(historyLength > 0);

  /// Number of samples kept.
  final int historyLength;

  final ListQueue<MemorySnapshot> _history = ListQueue<MemorySnapshot>();
  int? _peakRss;
  int _peakImageCacheBytes = 0;
  int _peakImageCacheCount = 0;
  int _revision = 0;

  /// Increments whenever the data changes.
  int get revision => _revision;

  /// Most recent snapshot, or null before the first sample.
  MemorySnapshot? get latest => _history.isEmpty ? null : _history.last;

  /// Recent snapshots, oldest first.
  List<MemorySnapshot> get history => List<MemorySnapshot>.unmodifiable(_history);

  /// Highest RSS seen this session (taking the OS peak into account), or
  /// null if the platform does not report it.
  int? get peakRssBytes => _peakRss;

  /// Largest image cache footprint seen this session.
  int get peakImageCacheBytes => _peakImageCacheBytes;

  /// Most images held by the cache at once this session.
  int get peakImageCacheCount => _peakImageCacheCount;

  /// Records a snapshot.
  void add(MemorySnapshot snapshot) {
    _history.addLast(snapshot);
    while (_history.length > historyLength) {
      _history.removeFirst();
    }
    for (final value in <int?>[snapshot.rssBytes, snapshot.maxRssBytes]) {
      if (value != null && (_peakRss == null || value > _peakRss!)) {
        _peakRss = value;
      }
    }
    if (snapshot.imageCacheBytes > _peakImageCacheBytes) {
      _peakImageCacheBytes = snapshot.imageCacheBytes;
    }
    if (snapshot.imageCacheCount > _peakImageCacheCount) {
      _peakImageCacheCount = snapshot.imageCacheCount;
    }
    _revision++;
  }

  /// Forgets everything.
  void reset() {
    _history.clear();
    _peakRss = null;
    _peakImageCacheBytes = 0;
    _peakImageCacheCount = 0;
    _revision++;
  }
}
