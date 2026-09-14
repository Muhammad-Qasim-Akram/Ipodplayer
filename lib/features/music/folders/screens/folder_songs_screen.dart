import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/widgets/album_art_song_list_tile.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/folders/providers/folder_songs_provider.dart';
import 'package:classipod/features/music/folders/utils/folder_name_utils.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FolderSongsScreen extends ConsumerStatefulWidget {
  final String folderPath;

  const FolderSongsScreen({super.key, required this.folderPath});

  @override
  ConsumerState createState() => _FolderSongsScreenState();
}

class _FolderSongsScreenState extends ConsumerState<FolderSongsScreen>
    with CustomScreen {
  @override
  double get displayTileHeight => 54;

  @override
  String get routeName => Routes.folderSongs.name;

  @override
  List<MusicMetadata> get displayItems =>
      ref.read(folderSongsMetadataListProvider(widget.folderPath));

  @override
  Future<void> onSelectPressed() => _playSong(selectedDisplayItem);

  @override
  void onSelectLongPress() =>
      _navigateToFolderSongMoreOptionsModal(selectedDisplayItem);

  void _navigateToFolderSongMoreOptionsModal(int index) {
    setState(() {
      selectedDisplayItem = index;
    });
    context.goNamed(
      Routes.folderSongsMoreOptions.name,
      extra: displayItems[index],
    );
  }

  Future<void> _playSong(int index) async {
    setState(() => selectedDisplayItem = index);
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .playFolder(folderSongs: displayItems, songIndex: index);
    if (mounted) {
      await context.pushNamed(Routes.nowPlaying.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? currentlyPlayingOriginalIndex = ref
        .watch(nowPlayingDetailsProvider.select((e) => e.currentMetadata))
        ?.originalSongIndex;
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: folderDisplayName(widget.folderPath)),
          if (displayItems.isEmpty)
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            )
          else
            Flexible(
              child: CupertinoScrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: displayItems.length,
                  prototypeItem: AlbumArtSongListTile(
                    songMetadata: MusicMetadata(),
                    isSelected: false,
                    isCurrentlyPlaying: false,
                    onTap: () {},
                    onLongPress: () {},
                  ),
                  itemBuilder: (context, index) => AlbumArtSongListTile(
                    songMetadata: displayItems[index],
                    isSelected: selectedDisplayItem == index,
                    isCurrentlyPlaying:
                        currentlyPlayingOriginalIndex ==
                        displayItems[index].originalSongIndex,
                    onTap: () async => _playSong(index),
                    onLongPress: () =>
                        _navigateToFolderSongMoreOptionsModal(index),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
