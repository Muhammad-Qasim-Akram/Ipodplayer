import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/utils/lrc_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LyricsView extends ConsumerStatefulWidget {
  final String lyrics;
  final ScrollController scrollController;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.scrollController,
  });

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  late List<LrcLine>? _syncedLyrics;
  int _activeLineIndex = -1;

  @override
  void initState() {
    super.initState();
    // Parse LRC format once at initialization
    _syncedLyrics = LrcParser.parse(widget.lyrics);
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-parse if lyrics changed (different song)
    if (oldWidget.lyrics != widget.lyrics) {
      _syncedLyrics = LrcParser.parse(widget.lyrics);
      _activeLineIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no synced lyrics, fall back to static rendering
    if (_syncedLyrics == null || _syncedLyrics!.isEmpty) {
      return _buildStaticLyrics();
    }

    // Synced lyrics with position tracking
    return _buildSyncedLyrics();
  }

  /// Fallback: Static/plain lyrics rendering (original behavior)
  Widget _buildStaticLyrics() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoScrollbar(
        controller: widget.scrollController,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            widget.lyrics,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Synced LRC lyrics with highlighting and auto-scroll
  Widget _buildSyncedLyrics() {
    return StreamBuilder<Duration>(
      stream: ref.read(audioPlayerProvider).positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final newActiveIndex = LrcParser.findActiveLineIndex(
          _syncedLyrics!,
          position,
        );

        // Update active index
        if (newActiveIndex != _activeLineIndex) {
          _activeLineIndex = newActiveIndex;

          // Auto-scroll to active line with smooth animation
          if (_activeLineIndex >= 0) {
            Future.microtask(() => _scrollToActiveLine(_activeLineIndex));
          }
        }

        return SizedBox(
          width: double.infinity,
          child: CupertinoScrollbar(
            controller: widget.scrollController,
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  _syncedLyrics!.length,
                  (index) => _buildLrcLineWidget(
                    line: _syncedLyrics![index],
                    isActive: index == _activeLineIndex,
                    index: index,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a single lyric line widget
  Widget _buildLrcLineWidget({
    required LrcLine line,
    required bool isActive,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => _seekToLine(line),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isActive ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isActive
                ? CupertinoColors.activeBlue
                : CupertinoColors.label.withOpacity(0.6),
            height: 1.4,
          ),
          child: Text(
            line.text.isEmpty ? '[...]' : line.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Scrolls the lyrics view to keep the active line centered
  void _scrollToActiveLine(int lineIndex) {
    if (!widget.scrollController.hasClients || lineIndex < 0) {
      return;
    }

    // Approximate line height
    const lineHeight = 34.0; // fontSize 16 + padding/line-height
    final targetOffset = lineIndex * lineHeight - (200); // Center on screen

    widget.scrollController.animateTo(
      targetOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Seeks playback to the tapped line's timestamp
  void _seekToLine(LrcLine line) {
    ref
        .read(audioPlayerServiceProvider.notifier)
        .seekToDuration(line.timestamp.inSeconds);
  }
}

