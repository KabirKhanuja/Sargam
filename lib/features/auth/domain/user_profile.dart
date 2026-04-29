class UserProfile {
  final String name;
  final String email;
  final DateTime joinedAt;

  const UserProfile({
    required this.name,
    required this.email,
    required this.joinedAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}
