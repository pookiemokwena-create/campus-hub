import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/config/vocational_streams.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/core/widgets/labeled_dropdown.dart';
import 'package:ncv_companion/features/auth/data/auth_repository.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';

/// Log-in and sign-up (onboarding) in one screen.
/// Sign-up captures NQF level and vocational stream, which drive subject
/// and past-paper filtering throughout the app.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _college = TextEditingController();

  bool _signUpMode = false;
  bool _obscurePassword = true;
  int _nqfLevel = 2;
  String? _stream;
  bool _streamMissing = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _college.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _streamMissing = _signUpMode && _stream == null);
    if (!formValid || _streamMissing) return;

    final controller = ref.read(authFormControllerProvider.notifier);
    if (_signUpMode) {
      await controller.signUp(
        SignUpRequest(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          collegeName: _college.text.trim(),
          nqfLevel: _nqfLevel,
          vocationalStream: _stream!,
        ),
      );
    } else {
      await controller.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authFormControllerProvider);
    final online = ref.watch(isOnlineProvider);
    final isBusy = form.isLoading;

    ref.listen(authFormControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(next.error!))));
      }
      if (next.value == AuthOutcome.confirmEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created. Check your email to confirm, then log in.'),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Log in'),
                          icon: Icon(Icons.login),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Sign up'),
                          icon: Icon(Icons.person_add_alt_1),
                        ),
                      ],
                      selected: {_signUpMode},
                      onSelectionChanged: isBusy
                          ? null
                          : (selection) => setState(() {
                                _signUpMode = selection.first;
                                _streamMissing = false;
                              }),
                    ),
                    const SizedBox(height: 20),
                    if (!online)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _InlineNotice(
                          icon: Icons.wifi_off,
                          text: 'No connection. Log in and sign up need internet access.',
                        ),
                      ),
                    if (_signUpMode) ...[
                      TextFormField(
                        controller: _fullName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => (value == null || value.trim().length < 2)
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _college,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'College name',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Enter your college'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('NCV level', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: [
                          for (final level in AppConstants.nqfLevels)
                            ButtonSegment(value: level, label: Text('NQF $level')),
                        ],
                        selected: {_nqfLevel},
                        onSelectionChanged: isBusy
                            ? null
                            : (selection) => setState(() => _nqfLevel = selection.first),
                      ),
                      const SizedBox(height: 16),
                      LabeledDropdown<String>(
                        label: 'Vocational stream',
                        value: _stream,
                        errorText: _streamMissing ? 'Choose your stream' : null,
                        items: [
                          for (final stream in VocationalStreams.all)
                            DropdownMenuItem(value: stream, child: Text(stream)),
                        ],
                        onChanged: isBusy
                            ? (_) {}
                            : (value) => setState(() {
                                  _stream = value;
                                  _streamMissing = false;
                                }),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        final text = value ?? '';
                        if (_signUpMode && text.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return text.isEmpty ? 'Enter your password' : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: (isBusy || !online) ? null : _submit,
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_signUpMode ? Icons.check : Icons.login),
                      label: Text(_signUpMode ? 'Create account' : 'Log in'),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.school, size: 32, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 12),
        Text('NCV Companion', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'ICASS tracking, past papers and an AI tutor for NCV Levels 2-4',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: scheme.onTertiaryContainer))),
        ],
      ),
    );
  }
}
