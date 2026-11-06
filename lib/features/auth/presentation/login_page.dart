import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_bloc.dart';

/// Brand block shown at the top of the login and lock screens.
class _Brand extends StatelessWidget {
  const _Brand({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: Space.m),
        Text(
          title,
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: Space.s),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// White card that floats on the gradient (keeps text contrast high).
class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.hero),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

// =====================================================================
// Sign in / Sign up
// =====================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_isSignUp) {
      bloc.add(SignUpSubmitted(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      ));
    } else {
      bloc.add(SignInSubmitted(_email.text.trim(), _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final busy = state is AuthBusy;
                    final error = state is Unauthenticated ? state.error : null;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Brand(
                          title: 'TalentLink',
                          subtitle: 'Learn. Grow. Show up.',
                        ),
                        const SizedBox(height: Space.xl),
                        _AuthCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isSignUp ? 'Create your account' : 'Welcome back',
                                  style: text.titleLarge,
                                ),
                                const SizedBox(height: Space.xs),
                                Text(
                                  _isSignUp
                                      ? 'Use your GlobalTech work email.'
                                      : 'Sign in to continue learning.',
                                  style: text.bodyMedium,
                                ),
                                const SizedBox(height: Space.l),
                                if (_isSignUp) ...[
                                  TextFormField(
                                    controller: _name,
                                    enabled: !busy,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization: TextCapitalization.words,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: Validators.name,
                                  ),
                                  const SizedBox(height: Space.m),
                                ],
                                TextFormField(
                                  controller: _email,
                                  enabled: !busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Work email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: Space.m),
                                TextFormField(
                                  controller: _password,
                                  enabled: !busy,
                                  obscureText: _hidePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: Space.m),
                                  StatusBanner(message: error),
                                ],
                                const SizedBox(height: Space.l),
                                GradientButton(
                                  label: _isSignUp ? 'Create account' : 'Sign in',
                                  loading: busy,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: Space.s),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => setState(
                                            () => _isSignUp = !_isSignUp,
                                          ),
                                  child: Text(
                                    _isSignUp
                                        ? 'Already have an account? Sign in'
                                        : 'New here? Create an account',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Biometric lock (returning users)
// =====================================================================
class LockPage extends StatefulWidget {
  const LockPage({super.key, required this.state});
  final BiometricLocked state;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  @override
  void initState() {
    super.initState();
    // Prompt right away so returning users are one touch from the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(const BiometricRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = widget.state.user;
    final error = widget.state.error;
    final firstName = user.name.split(' ').first;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Brand(
                      title: 'TalentLink',
                      subtitle: 'Good to see you again',
                    ),
                    const SizedBox(height: Space.xl),
                    _AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppGradients.accent,
                              ),
                              child: const Icon(
                                Icons.fingerprint,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.l),
                          Text(
                            'Welcome back, $firstName',
                            textAlign: TextAlign.center,
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            'Confirm it\'s you with your fingerprint or face.',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium,
                          ),
                          if (error != null) ...[
                            const SizedBox(height: Space.m),
                            StatusBanner(message: error),
                          ],
                          const SizedBox(height: Space.l),
                          GradientButton(
                            label: 'Unlock with biometrics',
                            icon: Icons.fingerprint,
                            onPressed: () => context
                                .read<AuthBloc>()
                                .add(const BiometricRequested()),
                          ),
                          const SizedBox(height: Space.s),
                          TextButton(
                            onPressed: () => context
                                .read<AuthBloc>()
                                .add(const SignOutRequested()),
                            child: const Text('Use email & password instead'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
