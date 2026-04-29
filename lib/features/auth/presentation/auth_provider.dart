import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

class AuthState {
  final UserProfile? profile;
  final Map<String, _AuthUser> users;
  final String? lastError;

  const AuthState({
    this.profile,
    this.users = const {},
    this.lastError,
  });

  bool get isSignedIn => profile != null;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  bool signIn({required String email, required String password}) {
    final normalized = email.trim().toLowerCase();
    final user = state.users[normalized];
    if (user == null || user.password != password) {
      state = AuthState(
        profile: null,
        users: state.users,
        lastError: 'Email or password is incorrect.',
      );
      return false;
    }

    state = AuthState(
      profile: user.profile,
      users: state.users,
      lastError: null,
    );
    return true;
  }

  bool signUp({
    required String name,
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    if (state.users.containsKey(normalized)) {
      state = AuthState(
        profile: null,
        users: state.users,
        lastError: 'An account with this email already exists.',
      );
      return false;
    }

    final profile = UserProfile(
      name: name.trim(),
      email: email.trim(),
      joinedAt: DateTime.now(),
    );

    final users = Map<String, _AuthUser>.from(state.users)
      ..[normalized] = _AuthUser(profile: profile, password: password);

    state = AuthState(profile: profile, users: users, lastError: null);
    return true;
  }

  void signOut() {
    state = AuthState(users: state.users);
  }

  void clearError() {
    if (state.lastError == null) return;
    state = AuthState(profile: state.profile, users: state.users);
  }

}

class _AuthUser {
  final UserProfile profile;
  final String password;

  const _AuthUser({required this.profile, required this.password});
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
