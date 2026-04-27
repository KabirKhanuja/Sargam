enum SessionState { idle, running, paused, ended }

class RiyazSession {
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration totalDuration;
  final Duration effectiveDuration;
  final SessionState state;

  const RiyazSession({
    required this.startedAt,
    this.endedAt,
    required this.totalDuration,
    required this.effectiveDuration,
    required this.state,
  });

  factory RiyazSession.idle() => RiyazSession(
        startedAt: DateTime.fromMillisecondsSinceEpoch(0),
        endedAt: null,
        totalDuration: Duration.zero,
        effectiveDuration: Duration.zero,
        state: SessionState.idle,
      );

  bool get isRunning => state == SessionState.running;

  RiyazSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? totalDuration,
    Duration? effectiveDuration,
    SessionState? state,
  }) =>
      RiyazSession(
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        totalDuration: totalDuration ?? this.totalDuration,
        effectiveDuration: effectiveDuration ?? this.effectiveDuration,
        state: state ?? this.state,
      );
}
