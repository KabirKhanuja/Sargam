import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

class AuthState {
  final UserProfile? profile;

  const AuthState({this.profile});

  bool get isSignedIn => profile != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void signIn({required String email, String? name}) {
    final displayName = _resolveName(name, email);
    state = AuthState(
      profile: UserProfile(
        name: displayName,
        email: email.trim(),
        joinedAt: DateTime.now(),
      ),
    );
  }

  void signUp({required String name, required String email}) {
    state = AuthState(
      profile: UserProfile(
        name: name.trim(),
        email: email.trim(),
        joinedAt: DateTime.now(),
      ),
    );
  }

  void signOut() {
    state = const AuthState();
  }

  String _resolveName(String? name, String email) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final handle = email.split('@').first;
    if (handle.isEmpty) return 'Sargam User';
    return handle
        .split(RegExp(r'[._-]+'))
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) => chunk[0].toUpperCase() + chunk.substring(1))
        .join(' ');
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
