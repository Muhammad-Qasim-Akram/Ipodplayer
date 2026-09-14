import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/filtered_audio_files_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Songs whose parent directory matches [folderPath], in the same order
/// they were scanned in. This is what gets played when a folder is opened
/// and treated as a playlist.
final folderSongsMetadataListProvider = Provider.autoDispose
    .family<List<MusicMetadata>, String>((ref, folderPath) {
      final List<MusicMetadata> folderSongsMetadataList = [];

      for (final metadata
          in ref.read(filteredAudioFilesProvider).requireValue) {
        if (metadata.parentDirectoryPath == folderPath) {
          folderSongsMetadataList.add(metadata);
        }
      }

      return folderSongsMetadataList;
    });
