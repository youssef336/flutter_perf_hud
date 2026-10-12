/// Human-readable byte count: `512 B`, `12.3 KB`, `140 MB`, `1.20 GB`.
String formatBytes(int? bytes) {
  if (bytes == null) {
    return 'n/a';
  }
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }
  if (bytes >= mb) {
    final value = bytes / mb;
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} MB';
  }
  if (bytes >= kb) {
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

/// Microseconds as milliseconds with one decimal: `16.7 ms`.
String formatMs(num micros) => '${(micros / 1000).toStringAsFixed(1)} ms';

/// A duration as `1h 02m 03s`, `2m 05s` or `42s`.
String formatDuration(Duration duration) {
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  String two(int v) => v.toString().padLeft(2, '0');
  if (h > 0) {
    return '${h}h ${two(m)}m ${two(s)}s';
  }
  if (m > 0) {
    return '${m}m ${two(s)}s';
  }
  return '${s}s';
}
