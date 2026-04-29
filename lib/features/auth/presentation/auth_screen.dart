import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(authControllerProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorMessage = authState.lastError;
    if (authState.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sargam',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Welcome back to your practice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.gold,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.gold,
                      indicatorWeight: 2.5,
                      tabs: const [
                        Tab(text: 'Log in'),
                        Tab(text: 'Sign up'),
                      ],
                    ),
                    SizedBox(
                      height: 420,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _LoginForm(
                            formKey: _loginKey,
                            emailController: _loginEmailController,
                            passwordController: _loginPasswordController,
                            onSubmit: _handleLogin,
                          ),
                          _SignupForm(
                            formKey: _signupKey,
                            nameController: _signupNameController,
                            emailController: _signupEmailController,
                            passwordController: _signupPasswordController,
                            onSubmit: _handleSignup,
                          ),
                        ],
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.4,
                            color: AppColors.offPitch,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your practice stats stay local to your device.',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    final ok = ref.read(authControllerProvider.notifier).signIn(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }

  void _handleSignup() {
    if (!(_signupKey.currentState?.validate() ?? false)) return;
    final ok = ref.read(authControllerProvider.notifier).signUp(
          name: _signupNameController.text,
          email: _signupEmailController.text,
          password: _signupPasswordController.text,
        );
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _AuthField(
              controller: emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            _AuthField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
              validator: _validatePassword,
            ),
            const Spacer(),
            PrimaryActionButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _SignupForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _AuthField(
              controller: nameController,
              label: 'Full name',
              textCapitalization: TextCapitalization.words,
              validator: _validateName,
            ),
            const SizedBox(height: 16),
            _AuthField(
              controller: emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            _AuthField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
              validator: _validatePassword,
            ),
            const Spacer(),
            PrimaryActionButton(
              label: 'Create profile',
              icon: Icons.check_rounded,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email.';
  if (!text.contains('@')) return 'Enter a valid email.';
  return null;
}

String? _validatePassword(String? value) {
  final text = value ?? '';
  if (text.length < 6) return 'Use at least 6 characters.';
  return null;
}

String? _validateName(String? value) {
  final text = value?.trim() ?? '';
  if (text.length < 2) return 'Enter your name.';
  return null;
}
