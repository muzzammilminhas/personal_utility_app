import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

import '../../models/recording.dart';
import '../../services/audio_service.dart';
import '../../utils/app_constants.dart';

class PlaybackScreen extends StatefulWidget {
  final Recording recording;

  const PlaybackScreen({super.key, required this.recording});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService = AudioService();

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoadingUrl = true;
  String? _errorMessage;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    _positionSub = _player.onPositionChanged.listen((pos) {
      setState(() => _position = pos);
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      setState(() => _duration = dur);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      setState(() => _playerState = state);
    });

    try {
      final url = await _audioService.getPlaybackUrl(widget.recording.filePath);
      if (!mounted) return;
      setState(() => _isLoadingUrl = false);

      await _player.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUrl = false;
          _errorMessage = 'Could not load audio: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();

    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      final url = await _audioService.getPlaybackUrl(widget.recording.filePath);
      await _player.play(UrlSource(url));
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() => _position = Duration.zero);
  }

  Future<void> _seek(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await _player.seek(position);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get _sliderValue {
    if (_duration.inMilliseconds == 0) return 0.0;
    final value = _position.inMilliseconds / _duration.inMilliseconds;

    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = _playerState == PlayerState.playing;
    final isCompleted = _playerState == PlayerState.completed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recording.title, overflow: TextOverflow.ellipsis),
        backgroundColor: ModuleColors.recorderLight,
        foregroundColor: ModuleColors.recorder,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(theme),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoadingUrl)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: ModuleColors.recorder),
                    SizedBox(height: 12),
                    Text('Loading audio...'),
                  ],
                ),
              )
            else if (_errorMessage != null)
              _buildError(theme)
            else
              _buildPlayer(theme, isPlaying, isCompleted),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ModuleColors.recorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recording.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy · HH:mm')
                            .format(widget.recording.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.recording.notes.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 16, color: ModuleColors.recorder),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.recording.notes,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(ThemeData theme, bool isPlaying, bool isCompleted) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildWaveformVisual(isPlaying),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ModuleColors.recorder,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: ModuleColors.recorder,
                inactiveTrackColor:
                    ModuleColors.recorder.withValues(alpha: 0.2),
                thumbColor: ModuleColors.recorder,
                overlayColor: ModuleColors.recorder.withValues(alpha: 0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _position.inMilliseconds
                    .toDouble()
                    .clamp(0.0, _duration.inMilliseconds.toDouble()),
                min: 0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: _duration.inMilliseconds > 0 ? _seek : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  onPressed: () async {
                    final newPos = _position - const Duration(seconds: 10);
                    await _seek(newPos.isNegative
                        ? 0
                        : newPos.inMilliseconds.toDouble());
                  },
                  icon: const Icon(Icons.replay_10_rounded),
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: 'Rewind 10s',
                ),
                const SizedBox(width: AppSpacing.lg),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: ModuleColors.recorder,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.replay_rounded
                          : isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                IconButton(
                  iconSize: 36,
                  onPressed: () async {
                    final newPos = _position + const Duration(seconds: 10);
                    final maxMs = _duration.inMilliseconds.toDouble();
                    await _seek(newPos.inMilliseconds > maxMs
                        ? maxMs
                        : newPos.inMilliseconds.toDouble());
                  },
                  icon: const Icon(Icons.forward_10_rounded),
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: 'Forward 10s',
                ),
              ],
            ),
            if (isPlaying || _position > Duration.zero) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Stop'),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformVisual(bool isPlaying) {
    const barCount = 30;

    const heights = [
      12,
      20,
      28,
      16,
      32,
      24,
      36,
      18,
      40,
      28,
      20,
      36,
      24,
      32,
      16,
      28,
      40,
      20,
      32,
      24,
      36,
      18,
      28,
      40,
      24,
      16,
      32,
      20,
      28,
      14,
    ];

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final filled = _sliderValue > (i / barCount);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: heights[i % heights.length].toDouble(),
              decoration: BoxDecoration(
                color: filled
                    ? ModuleColors.recorder
                    : ModuleColors.recorder.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(_errorMessage ?? 'Playback error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error)),
      ],
    );
  }
}
