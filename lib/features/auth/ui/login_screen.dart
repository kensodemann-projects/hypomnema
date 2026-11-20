import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/auth/ui/hypomnema_logo.dart';
import 'package:material_ui/material_ui.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _emailValidationError(String text) {
  final email = text.trim();
  if (email.isEmpty) {
    return 'Email is required.';
  }
  if (!_emailPattern.hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _passwordValidationError(String text) {
  if (text.trim().isEmpty) {
    return 'Password is required.';
  }
  return null;
}

const _desktopQuote =
    'A note kept so it can be found again: a reminder, a memorandum, '
    'a short record of something worth remembering.';

const _phoneQuote = 'A note kept so it can be found again.';

const _brandPadding = 64.0;

// CSS linear-gradient(150deg): 0deg points up and angles run clockwise.
const _brandBegin = Alignment(-0.5, -0.8660254037844386);
const _brandEnd = Alignment(0.5, 0.8660254037844386);

const _lightBrandGradient = LinearGradient(
  begin: _brandBegin,
  end: _brandEnd,
  colors: [Color(0xFF4A55C8), Color(0xFF2E3694)],
);

const _darkBrandGradient = LinearGradient(
  begin: _brandBegin,
  end: _brandEnd,
  colors: [Color(0xFF2B3290), Color(0xFF151A55)],
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _authError;
  String? _confirmation;
  var _submitting = false;
  var _resettingPassword = false;

  bool get _emailIsValid =>
      _emailValidationError(_emailController.text) == null;

  bool get _canSignIn =>
      !_submitting &&
      _emailIsValid &&
      _passwordValidationError(_passwordController.text) == null;

  bool get _canResetPassword => !_submitting && _emailIsValid;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocus);
    _passwordFocus.addListener(_onPasswordFocus);
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onEmailFocus);
    _passwordFocus.removeListener(_onPasswordFocus);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onEmailFocus() {
    if (!mounted || _emailFocus.hasFocus) {
      return;
    }
    setState(() => _emailError = _emailValidationError(_emailController.text));
  }

  void _onPasswordFocus() {
    if (!mounted || _passwordFocus.hasFocus) {
      return;
    }
    setState(
      () => _passwordError = _passwordValidationError(_passwordController.text),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _submitting = true;
      _authError = null;
    });
    try {
      await widget.authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      TextInput.finishAutofillContext();
    } on AuthException {
      if (!mounted) {
        return;
      }
      setState(() => _authError = 'Authentication failed.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showResetForm() {
    setState(() {
      _resettingPassword = true;
      _authError = null;
      _confirmation = null;
      _passwordError = null;
    });
  }

  void _showSignInForm() {
    setState(() {
      _resettingPassword = false;
      _authError = null;
      _confirmation = null;
      _passwordError = null;
    });
  }

  void _submitEmailField(String _) {
    if (_resettingPassword) {
      if (_canResetPassword) {
        _sendResetEmail();
      }
      return;
    }
    _passwordFocus.requestFocus();
  }

  void _submitPasswordField(String _) {
    if (_canSignIn) {
      _signIn();
    }
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _submitting = true;
      _authError = null;
      _confirmation = null;
    });
    try {
      await widget.authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(
        () => _confirmation = 'Check your email for a password reset link.',
      );
    } on AuthException {
      if (!mounted) {
        return;
      }
      setState(() => _authError = 'Failed to send password reset email.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _emailField() {
    return TextField(
      key: const Key('login-email'),
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: _resettingPassword
          ? TextInputAction.done
          : TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
      onChanged: (_) => setState(() => _emailError = null),
      onSubmitted: _submitEmailField,
    );
  }

  List<Widget> _feedback() {
    return [
      if (_authError != null) ...[
        const SizedBox(height: 16),
        Text(
          _authError!,
          key: const Key('login-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (_confirmation != null) ...[
        const SizedBox(height: 16),
        Text(_confirmation!, key: const Key('login-reset-confirmation')),
      ],
    ];
  }

  Widget _form() {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _emailField(),
          if (_resettingPassword) ...[
            ..._feedback(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login-send-reset'),
              onPressed: _canResetPassword ? _sendResetEmail : null,
              child: const Text('Send reset email'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('login-back-to-sign-in'),
              onPressed: _submitting ? null : _showSignInForm,
              child: const Text('Back to sign in'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('login-password'),
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passwordError,
              ),
              onChanged: (_) => setState(() => _passwordError = null),
              onSubmitted: _submitPasswordField,
            ),
            ..._feedback(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login-sign-in'),
              onPressed: _canSignIn ? _signIn : null,
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('login-forgot-password'),
              onPressed: _canResetPassword ? _showResetForm : null,
              child: const Text('Forgot password'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _brandContent() {
    return Padding(
      padding: const EdgeInsets.all(_brandPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HypomnemaLogo(key: Key('login-logo')),
          const SizedBox(height: 28),
          const Text(
            'Hypomnema',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 40,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _desktopQuote,
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel() {
    final gradient = Theme.of(context).brightness == Brightness.light
        ? _lightBrandGradient
        : _darkBrandGradient;
    return DecoratedBox(
      key: const Key('login-brand'),
      decoration: BoxDecoration(gradient: gradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < _brandPadding * 2 + 72;
          if (narrow) {
            return ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                maxHeight: constraints.maxHeight,
                child: _brandContent(),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: _brandContent()),
            ],
          );
        },
      ),
    );
  }

  Widget _desktopLayout() {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: _brandPanel()),
          SizedBox(
            key: const Key('login-form-side'),
            width: 520,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      key: const Key('login-form-column'),
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sign in',
                            key: Key('login-heading'),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the account you were given.',
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _form(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneLayout() {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 28,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(child: HypomnemaLogo(key: Key('login-logo'))),
                    const SizedBox(height: 10),
                    const Text(
                      'Hypomnema',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _phoneQuote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _form(),
                    const SizedBox(height: 18),
                    Text(
                      'Accounts are created for you. There is no sign-up.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _desktopLayout();
        }
        return _phoneLayout();
      },
    );
  }
}
