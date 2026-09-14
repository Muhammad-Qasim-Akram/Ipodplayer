/// Returns just the last path segment of a folder path (e.g. "Rock" for
/// "/storage/emulated/0/Music/Rock"), so folder tiles show a readable name
/// instead of the full path. Falls back to the original path if it can't
/// be split (e.g. a root directory).
String folderDisplayName(String folderPath) {
  final normalizedPath = folderPath.replaceAll('\\', '/');

  final trimmedPath = normalizedPath.endsWith('/')
      ? normalizedPath.substring(0, normalizedPath.length - 1)
      : normalizedPath;

  final segments = trimmedPath.split('/');
  final lastSegment = segments.isNotEmpty ? segments.last : '';

  return lastSegment.isEmpty ? folderPath : lastSegment;
}
