import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/folders/providers/folders_provider.dart';
import 'package:classipod/features/music/folders/utils/folder_name_utils.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.folders.name;

  @override
  List<String> get displayItems => ref.read(foldersProvider);

  @override
  void onSelectPressed() => _selectFolder(selectedDisplayItem);

  void _selectFolder(int index) {
    setState(() => selectedDisplayItem = index);
    final selectedFolderPath = ref.read(foldersProvider).elementAt(index);
    context.goNamed(Routes.folderSongs.name, extra: selectedFolderPath);
  }

  @override
  Widget build(BuildContext context) {
    if (displayItems.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.folders.title(context)),
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.folders.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: const DisplayListTile(
                  text: '',
                  isSelected: false,
                ),
                itemBuilder: (context, index) => DisplayListTile(
                  text: folderDisplayName(displayItems[index]),
                  isSelected: selectedDisplayItem == index,
                  onTap: () => _selectFolder(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
