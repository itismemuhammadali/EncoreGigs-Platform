import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';

// ── Data model ───────────────────────────────────────────────────────────────

enum PortfolioItemType { video, image, audio }

class PortfolioViewerItem {
  final String url;
  final String title;
  final String description;
  final PortfolioItemType type;

  const PortfolioViewerItem({
    required this.url,
    required this.title,
    required this.description,
    required this.type,
  });
}

// ── Entry point ──────────────────────────────────────────────────────────────

void showPortfolioViewer(
  BuildContext context,
  PortfolioViewerItem item,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PortfolioViewerSheet(item: item),
  );
}

// ── Bottom sheet ─────────────────────────────────────────────────────────────

class _PortfolioViewerSheet extends StatefulWidget {
  final PortfolioViewerItem item;
  const _PortfolioViewerSheet({required this.item});

  @override
  State<_PortfolioViewerSheet> createState() => _PortfolioViewerSheetState();
}

class _PortfolioViewerSheetState extends State<_PortfolioViewerSheet> {
  // Video
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoadingVideo = false;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == PortfolioItemType.audio) {
      _setupAudio();
    }
  }

  void _setupAudio() {
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlayingAudio = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  Future<void> _initVideo() async {
    if (_isLoadingVideo || widget.item.url.isEmpty) return;
    if (mounted) setState(() => _isLoadingVideo = true);
    try {
      _videoController?.dispose();
      _chewieController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.item.url),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFA2F301),
          handleColor: const Color(0xFFA2F301),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
      );
    } catch (e) {
      debugPrint('Video init error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVideo = false);
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlayingAudio = false);
      } else {
        await _audioPlayer.play(UrlSource(widget.item.url));
        if (mounted) setState(() => _isPlayingAudio = true);
      }
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.description,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2F301).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFA2F301).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _typeLabel,
                    style: const TextStyle(
                        color: Color(0xFFA2F301),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Color(0xFF888888), size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFA2F301).withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),

          // Media content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildContent(),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  String get _typeLabel {
    switch (widget.item.type) {
      case PortfolioItemType.video: return 'Video';
      case PortfolioItemType.image: return 'Image';
      case PortfolioItemType.audio: return 'Audio';
    }
  }

  Widget _buildContent() {
    switch (widget.item.type) {
      case PortfolioItemType.image:
        return _buildImageContent();
      case PortfolioItemType.video:
        return _buildVideoContent();
      case PortfolioItemType.audio:
        return _buildAudioContent();
    }
  }

  // ── Image ──────────────────────────────────────────────────────────────────

  Widget _buildImageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: widget.item.url.startsWith('http')
          ? Image.network(
              widget.item.url,
              fit: BoxFit.contain,
              width: double.infinity,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFA2F301))),
              errorBuilder: (_, __, ___) => _errorPlaceholder(),
            )
          : _errorPlaceholder(),
    );
  }

  // ── Video ──────────────────────────────────────────────────────────────────

  Widget _buildVideoContent() {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Chewie(controller: _chewieController!),
      );
    }

    return GestureDetector(
      onTap: _isLoadingVideo ? null : _initVideo,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          color: const Color(0xFF1A1A1F),
          child: Center(
            child: _isLoadingVideo
                ? const SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      color: Color(0xFFA2F301),
                      strokeWidth: 3,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/video_icon.svg',
                        width: 64,
                        height: 64,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFA2F301),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tap to play video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Audio ──────────────────────────────────────────────────────────────────

  Widget _buildAudioContent() {
    final progress = _audioDuration.inMilliseconds > 0
        ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
        : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform placeholder
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/music_note_icon.svg',
              width: 72,
              height: 72,
              colorFilter: const ColorFilter.mode(
                Color(0xFFA2F301),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Progress bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFA2F301),
            inactiveTrackColor: const Color(0xFF2A2A2F),
            thumbColor: const Color(0xFFA2F301),
            overlayColor: const Color(0xFFA2F301).withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) async {
              final pos = Duration(
                  milliseconds: (v * _audioDuration.inMilliseconds).round());
              await _audioPlayer.seek(pos);
            },
          ),
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_audioPosition),
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 12)),
              Text(_formatDuration(_audioDuration),
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Play/Pause button
        GestureDetector(
          onTap: _toggleAudio,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text('Unable to load media',
            style: TextStyle(color: Color(0xFF888888))),
      ),
    );
  }
}
