import 'package:classipod/core/providers/filtered_audio_files_provider.dart';
import 'package:classipod/features/music/folders/utils/folder_name_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The list of unique folder paths that contain scanned music files.
/// Each folder is later treated like a playlist of the songs it contains.
final foldersProvider = Provider<List<String>>((ref) {
  final folderPathsSet = <String>{};

  for (final audioFile
      in ref.read(filteredAudioFilesProvider).requireValue) {
    final parentDirectoryPath = audioFile.parentDirectoryPath;
    if (parentDirectoryPath != null) {
      folderPathsSet.add(parentDirectoryPath);
    }
  }

  final folderPaths = folderPathsSet.toList();
  folderPaths.sort(
    (a, b) => folderDisplayName(
      a,
    ).toLowerCase().compareTo(folderDisplayName(b).toLowerCase()),
  );

  return folderPaths;
});
