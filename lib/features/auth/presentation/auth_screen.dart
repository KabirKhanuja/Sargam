import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'auth_provider.dart';

enum _AuthMode { login, signup }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;

    FocusScope.of(context).unfocus();

    if (!form.validate()) return;

    setState(() => _busy = true);

    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_mode == _AuthMode.login) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        final name = _nameController.text.trim();
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = cred.user?.uid;
        if (uid == null) {
          throw StateError('User was not created.');
        }

        await firestore.collection('users').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
          'email': email,
          'name': name,
        }, SetOptions(merge: true));
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyAuthError(e));
    } catch (e) {
      _showSnack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _mode == _AuthMode.login ? 'Login' : 'Create account';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _ModeToggle(
                          mode: _mode,
                          onChanged: _busy
                              ? null
                              : (m) {
                                  setState(() => _mode = m);
                                },
                        ),
                        const SizedBox(height: 16),
                        if (_mode == _AuthMode.signup) ...[
                          TextFormField(
                            controller: _nameController,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            validator: (v) {
                              if (_mode != _AuthMode.signup) return null;
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Name is required.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required.';
                            if (!value.contains('@')) {
                              return 'Enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_busy,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _busy ? null : _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return 'Password is required.';
                            if (_mode == _AuthMode.signup && value.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(title),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final loginSelected = mode == _AuthMode.login;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onChanged == null
                  ? null
                  : () {
                      onChanged!(_AuthMode.login);
                    },
              style: TextButton.styleFrom(
                foregroundColor: loginSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              child: const Text('Login'),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: onChanged == null
                  ? null
                  : () {
                      onChanged!(_AuthMode.signup);
                    },
              style: TextButton.styleFrom(
                foregroundColor: !loginSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
