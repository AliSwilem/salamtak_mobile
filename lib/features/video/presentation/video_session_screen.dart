import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/video_session_model.dart';
import 'providers/video_providers.dart';

class VideoSessionScreen extends ConsumerWidget {
  final int appointmentId;

  const VideoSessionScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).role;
    final session = ref.watch(videoSessionProvider(appointmentId));
    final action = ref.watch(videoActionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to appointment',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _backToAppointment(context, role),
        ),
        title: Text('Video appointment #$appointmentId'),
      ),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _VideoError(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(videoSessionProvider(appointmentId)),
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(videoSessionProvider(appointmentId));
            await ref.read(videoSessionProvider(appointmentId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (item == null)
                _NoSessionCard(
                  role: role,
                  appointmentId: appointmentId,
                  isLoading: action.isLoading,
                )
              else ...[
                _SessionHeader(session: item),
                const SizedBox(height: 12),
                _LiveKitVideoSurface(
                  session: item,
                  appointmentId: appointmentId,
                  isActionLoading: action.isLoading,
                ),
                const SizedBox(height: 12),
                _SessionDetails(session: item),
                const SizedBox(height: 12),
                _SessionActions(
                  session: item,
                  appointmentId: appointmentId,
                  isLoading: action.isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _backToAppointment(BuildContext context, String? role) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final base = role == 'doctor' ? '/doctor' : '/patient';
    context.go('$base/appointments/$appointmentId');
  }
}

class _NoSessionCard extends ConsumerWidget {
  final String? role;
  final int appointmentId;
  final bool isLoading;

  const _NoSessionCard({
    required this.role,
    required this.appointmentId,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = role == 'doctor';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isDoctor ? 'No video session started' : 'Waiting for doctor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isDoctor
                  ? 'Start a secure video session when this appointment is eligible.'
                  : 'The doctor has not started the video session yet. Pull to refresh or return later.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isDoctor)
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final session = await ref
                            .read(videoActionProvider.notifier)
                            .start(appointmentId);
                        if (context.mounted) {
                          _showActionResult(
                            context,
                            ref,
                            session,
                            'Video session started. Tap Join video to connect.',
                          );
                        }
                      },
                icon: const Icon(Icons.video_call_outlined),
                label: Text(isLoading ? 'Starting...' : 'Start video session'),
              )
            else
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(videoSessionProvider(appointmentId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Check again'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final VideoSessionModel session;

  const _SessionHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = session.isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.videocam_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.participantName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: session.displayStatus, color: color),
                      if (session.canJoin)
                        _InfoChip(
                          label: 'Joinable',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      if (session.currentUserHasJoined)
                        _InfoChip(
                          label: 'You joined',
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      if (session.waitingForDoctor)
                        const _InfoChip(label: 'Waiting for doctor'),
                      if (session.waitingForPatient)
                        const _InfoChip(label: 'Waiting for patient'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveKitVideoSurface extends ConsumerStatefulWidget {
  final VideoSessionModel session;
  final int appointmentId;
  final bool isActionLoading;

  const _LiveKitVideoSurface({
    required this.session,
    required this.appointmentId,
    required this.isActionLoading,
  });

  @override
  ConsumerState<_LiveKitVideoSurface> createState() =>
      _LiveKitVideoSurfaceState();
}

class _LiveKitVideoSurfaceState extends ConsumerState<_LiveKitVideoSurface> {
  lk.Room? _room;
  bool _connecting = false;
  bool _connected = false;
  bool _cameraEnabled = true;
  bool _micEnabled = true;
  bool _switchingCamera = false;
  String? _mediaError;
  lk.CameraPosition _cameraPosition = lk.CameraPosition.front;

  bool get _hasJoinCredentials =>
      widget.session.hasCredentials &&
      widget.session.canJoin &&
      widget.session.currentUserHasJoined;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfReady());
  }

  @override
  void didUpdateWidget(covariant _LiveKitVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionChanged =
        oldWidget.session.id != widget.session.id ||
        oldWidget.session.accessToken != widget.session.accessToken ||
        oldWidget.session.liveKitUrl != widget.session.liveKitUrl;
    if (sessionChanged || !_hasJoinCredentials) {
      _disconnectLiveKit();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfReady());
  }

  @override
  void dispose() {
    _disconnectLiveKit();
    super.dispose();
  }

  Future<void> _connectIfReady() async {
    if (!mounted || !_hasJoinCredentials || _connecting || _connected) return;
    final url = widget.session.liveKitUrl;
    final token = widget.session.accessToken;
    if (url == null || token == null) return;

    setState(() {
      _connecting = true;
      _mediaError = null;
    });

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );
    room.addListener(_onRoomChanged);

    try {
      await room.connect(url, token);
      try {
        await room.localParticipant?.setCameraEnabled(true);
        _cameraEnabled = true;
      } catch (_) {
        _cameraEnabled = false;
        _mediaError =
            'Camera could not be started. Allow camera permission in the browser and try again.';
      }
      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
        _micEnabled = true;
      } catch (_) {
        _micEnabled = false;
        _mediaError = [
          if (_mediaError != null) _mediaError,
          'Microphone could not be started. Allow microphone permission in the browser and try again.',
        ].whereType<String>().join('\n');
      }
      if (!mounted) {
        room.removeListener(_onRoomChanged);
        await room.disconnect();
        await room.dispose();
        return;
      }
      setState(() {
        _room = room;
        _connected = true;
        _connecting = false;
      });
    } catch (error) {
      room.removeListener(_onRoomChanged);
      await room.dispose();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connected = false;
        _mediaError = _friendlyLiveKitError(error);
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final room = _room;
    setState(() {
      _connected = room?.connectionState == lk.ConnectionState.connected;
    });
  }

  Future<void> _disconnectLiveKit() async {
    final room = _room;
    _room = null;
    _connected = false;
    if (room == null) return;
    room.removeListener(_onRoomChanged);
    try {
      await room.localParticipant?.setCameraEnabled(false);
      await room.localParticipant?.setMicrophoneEnabled(false);
      await room.disconnect();
    } finally {
      await room.dispose();
    }
  }

  Future<void> _toggleMic() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final next = !_micEnabled;
    try {
      await participant.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micEnabled = next);
    } catch (error) {
      if (mounted) setState(() => _mediaError = _friendlyLiveKitError(error));
    }
  }

  Future<void> _toggleCamera() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final next = !_cameraEnabled;
    try {
      await participant.setCameraEnabled(next);
      if (mounted) setState(() => _cameraEnabled = next);
    } catch (error) {
      if (mounted) setState(() => _mediaError = _friendlyLiveKitError(error));
    }
  }

  Future<void> _switchCamera() async {
    final track = _localVideoTrack;
    if (track == null || _switchingCamera) return;
    final next = _cameraPosition == lk.CameraPosition.front
        ? lk.CameraPosition.back
        : lk.CameraPosition.front;
    setState(() => _switchingCamera = true);
    try {
      await track.setCameraPosition(next);
      if (mounted) setState(() => _cameraPosition = next);
    } catch (error) {
      if (mounted) setState(() => _mediaError = _friendlyLiveKitError(error));
    } finally {
      if (mounted) setState(() => _switchingCamera = false);
    }
  }

  Future<void> _leaveCall() async {
    await _disconnectLiveKit();
    final updated = await ref
        .read(videoActionProvider.notifier)
        .leave(
          appointmentId: widget.appointmentId,
          sessionId: widget.session.id,
          reason: '${widget.session.currentUserRole}_left_livekit_call',
        );
    if (mounted) {
      _showActionResult(context, ref, updated, 'Left video call.');
    }
  }

  Future<void> _endCall() async {
    await _disconnectLiveKit();
    final updated = await ref
        .read(videoActionProvider.notifier)
        .end(
          appointmentId: widget.appointmentId,
          sessionId: widget.session.id,
          reason: 'doctor_ended_livekit_call',
        );
    if (mounted) {
      _showActionResult(context, ref, updated, 'Video call ended.');
    }
  }

  lk.LocalVideoTrack? get _localVideoTrack {
    final participant = _room?.localParticipant;
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track != null && !publication.muted) return track;
    }
    return null;
  }

  lk.VideoTrack? get _remoteVideoTrack {
    final room = _room;
    if (room == null) return null;
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null && !publication.muted) return track;
      }
    }
    return null;
  }

  String get _connectionLabel {
    final room = _room;
    if (_connecting) return 'Connecting to LiveKit...';
    if (room == null) return 'Not connected';
    switch (room.connectionState) {
      case lk.ConnectionState.connected:
        return 'Connected';
      case lk.ConnectionState.connecting:
        return 'Connecting...';
      case lk.ConnectionState.reconnecting:
        return 'Reconnecting...';
      case lk.ConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localTrack = _localVideoTrack;
    final remoteTrack = _remoteVideoTrack;
    final room = _room;
    final hasRemoteParticipants = room?.remoteParticipants.isNotEmpty == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 320,
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: remoteTrack != null
                      ? lk.VideoTrackRenderer(remoteTrack)
                      : _WaitingForRemoteParticipant(
                          connected: _connected,
                          hasRemoteParticipants: hasRemoteParticipants,
                          message: _hasJoinCredentials
                              ? 'Waiting for the other participant...'
                              : widget.session.noticeMessage ??
                                    'Tap Join video when this appointment is inside the allowed join window.',
                        ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  width: 118,
                  height: 148,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: localTrack != null
                          ? lk.VideoTrackRenderer(localTrack)
                          : const _NoLocalVideoPreview(),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _ConnectionPill(
                    label: _connectionLabel,
                    connected: _connected,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_connecting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (_mediaError?.isNotEmpty == true) ...[
                  Text(
                    _mediaError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _connected && !widget.isActionLoading
                          ? _toggleMic
                          : null,
                      icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                      label: Text(_micEnabled ? 'Mute' : 'Unmute'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _connected && !widget.isActionLoading
                          ? _toggleCamera
                          : null,
                      icon: Icon(
                        _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      ),
                      label: Text(_cameraEnabled ? 'Camera off' : 'Camera on'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _connected &&
                              _cameraEnabled &&
                              !_switchingCamera &&
                              localTrack != null
                          ? _switchCamera
                          : null,
                      icon: const Icon(Icons.cameraswitch_outlined),
                      label: Text(_switchingCamera ? 'Switching...' : 'Switch'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          widget.session.currentUserHasJoined &&
                              !widget.isActionLoading
                          ? _leaveCall
                          : null,
                      icon: const Icon(Icons.call_end_outlined),
                      label: const Text('Leave call'),
                    ),
                    if (widget.session.currentUserRole == 'doctor')
                      OutlinedButton.icon(
                        onPressed:
                            widget.session.canEnd && !widget.isActionLoading
                            ? _endCall
                            : null,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('End session'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingForRemoteParticipant extends StatelessWidget {
  final bool connected;
  final bool hasRemoteParticipants;
  final String message;

  const _WaitingForRemoteParticipant({
    required this.connected,
    required this.hasRemoteParticipants,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.person_search_outlined : Icons.lock_clock,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              connected
                  ? hasRemoteParticipants
                        ? 'Remote camera is off'
                        : 'Waiting for the other participant'
                  : 'Video not connected yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLocalVideoPreview extends StatelessWidget {
  const _NoLocalVideoPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, color: Colors.white70),
          SizedBox(height: 6),
          Text(
            'Local video',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  final String label;
  final bool connected;

  const _ConnectionPill({required this.label, required this.connected});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade700 : Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SessionDetails extends StatelessWidget {
  final VideoSessionModel session;

  const _SessionDetails({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Session ID', value: '${session.id}'),
            _DetailRow(
              label: 'Appointment ID',
              value: '${session.appointmentId}',
            ),
            _DetailRow(label: 'Provider', value: session.provider),
            _DetailRow(label: 'Room', value: session.roomName),
            _DetailRow(label: 'LiveKit URL', value: session.liveKitUrl ?? '-'),
            _DetailRow(
              label: 'Access token',
              value: session.accessToken?.isNotEmpty == true
                  ? 'Available'
                  : 'Not issued',
            ),
            _DetailRow(
              label: 'Join window',
              value: _windowText(
                session.joinWindowStart,
                session.joinWindowEnd,
              ),
            ),
            if (session.noticeMessage?.isNotEmpty == true)
              _DetailRow(label: 'Notice', value: session.noticeMessage!),
            if (session.endReason?.isNotEmpty == true)
              _DetailRow(label: 'End reason', value: session.endReason!),
          ],
        ),
      ),
    );
  }
}

class _SessionActions extends ConsumerWidget {
  final VideoSessionModel session;
  final int appointmentId;
  final bool isLoading;

  const _SessionActions({
    required this.session,
    required this.appointmentId,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (session.currentUserRole == 'doctor' && session.canStart)
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final updated = await ref
                            .read(videoActionProvider.notifier)
                            .start(appointmentId);
                        if (context.mounted) {
                          _showActionResult(
                            context,
                            ref,
                            updated,
                            'Video session started. Tap Join video to connect.',
                          );
                        }
                      },
                icon: const Icon(Icons.video_call_outlined),
                label: Text(isLoading ? 'Starting...' : 'Start / reopen'),
              ),
            if (session.canJoin)
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final updated = await ref
                            .read(videoActionProvider.notifier)
                            .join(appointmentId);
                        if (context.mounted) {
                          _showActionResult(
                            context,
                            ref,
                            updated,
                            'Joined video session. Video connection is ready.',
                          );
                        }
                      },
                icon: const Icon(Icons.login),
                label: Text(
                  isLoading
                      ? 'Joining...'
                      : session.currentUserHasJoined
                      ? 'Refresh connection'
                      : 'Join video',
                ),
              ),
            if (!session.currentUserHasJoined)
              OutlinedButton.icon(
                onPressed: isLoading || !session.isActive
                    ? null
                    : () async {
                        final updated = await ref
                            .read(videoActionProvider.notifier)
                            .leave(
                              appointmentId: appointmentId,
                              sessionId: session.id,
                              reason: '${session.currentUserRole}_left_call',
                            );
                        if (context.mounted) {
                          _showActionResult(
                            context,
                            ref,
                            updated,
                            'Left video session.',
                          );
                        }
                      },
                icon: const Icon(Icons.call_end_outlined),
                label: const Text('Leave session'),
              ),
            if (session.currentUserRole == 'doctor' &&
                !session.currentUserHasJoined)
              OutlinedButton.icon(
                onPressed: isLoading || !session.canEnd
                    ? null
                    : () async {
                        final updated = await ref
                            .read(videoActionProvider.notifier)
                            .end(
                              appointmentId: appointmentId,
                              sessionId: session.id,
                              reason: 'doctor_ended_call',
                            );
                        if (context.mounted) {
                          _showActionResult(
                            context,
                            ref,
                            updated,
                            'Video session ended.',
                          );
                        }
                      },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('End session'),
              ),
            if (!session.canJoin &&
                !session.canEnd &&
                !(session.currentUserRole == 'doctor' && session.canStart))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No video action is currently available. Pull to refresh for the latest session state.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _InfoChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.secondary;
    return Chip(
      label: Text(label),
      side: BorderSide(color: chipColor.withValues(alpha: 0.35)),
      backgroundColor: chipColor.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _VideoError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showActionResult(
  BuildContext context,
  WidgetRef ref,
  VideoSessionModel? session,
  String successMessage,
) {
  final error = ref.read(videoActionProvider).error;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_friendlyError(error)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }

  if (session != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }
}

String _friendlyError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final detail = _detail(error.response?.data);
    if (statusCode == 404) return 'Video session not found.';
    if (statusCode == 403) return detail ?? 'You cannot access this session.';
    if (statusCode == 409) {
      return detail ?? 'This appointment is not eligible for video.';
    }
    if (statusCode == 503) {
      return detail ?? 'Video calls are temporarily unavailable.';
    }
    if (detail != null) return detail;
  }
  return 'Video session could not be loaded. Please try again.';
}

String _friendlyLiveKitError(Object error) {
  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('permission') ||
      lower.contains('notallowed') ||
      lower.contains('denied')) {
    return 'Camera or microphone permission was denied. Allow access in the browser and join again.';
  }
  if (lower.contains('token') || lower.contains('401')) {
    return 'The video token was rejected or expired. Tap Join video again to refresh the connection.';
  }
  if (lower.contains('websocket') || lower.contains('connect')) {
    return 'Could not connect to the LiveKit room. Check your network and try again.';
  }
  return 'LiveKit video could not start. Please try joining again.';
}

String? _detail(dynamic data) {
  if (data is Map) {
    final detail = data['detail'] ?? data['message'] ?? data['error'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
  }
  return null;
}

String _windowText(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '-';
  return '${_dateTimeText(start)} - ${_dateTimeText(end)}';
}

String _dateTimeText(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
