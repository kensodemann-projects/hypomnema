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

const _resetSentMessage = 'Check your email for a password reset link.';
const _resetFailedMessage = 'A reset link could not be sent. Try again.';
const _signInFailedMessage = 'Authentication failed.';

const _lightInfo = Color(0xFF0C5DA8);
const _lightInfoContainer = Color(0xFFD4E3FF);
const _darkInfo = Color(0xFFA5C8FF);
const _darkInfoContainer = Color(0xFF00468A);

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
  var _submitting = false;

  bool get _emailIsValid =>
      _emailValidationError(_emailController.text) == null;

  bool get _canSignIn =>
      !_submitting &&
      _emailIsValid &&
      _passwordValidationError(_passwordController.text) == null;

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
    setState(() => _submitting = true);
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
      _showErrorSnackBar(_signInFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _submitEmailField(String _) {
    _passwordFocus.requestFocus();
  }

  void _submitPasswordField(String _) {
    if (_canSignIn) {
      _signIn();
    }
  }

  Future<void> _forgotPassword() async {
    final emailError = _emailValidationError(_emailController.text);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _showInfoSnackBar(_resetSentMessage);
    } on AuthException {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar(_resetFailedMessage);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showInfoSnackBar(String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      message: message,
      background: dark ? _darkInfoContainer : _lightInfoContainer,
      foreground: dark ? _darkInfo : _lightInfo,
    );
  }

  void _showErrorSnackBar(String message) {
    final scheme = Theme.of(context).colorScheme;
    _showSnackBar(
      message: message,
      background: scheme.errorContainer,
      foreground: scheme.error,
    );
  }

  void _showSnackBar({
    required String message,
    required Color background,
    required Color foreground,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Text(message, style: TextStyle(color: foreground)),
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      key: const Key('login-email'),
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
      onChanged: (_) => setState(() => _emailError = null),
      onSubmitted: _submitEmailField,
    );
  }

  Widget _form() {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _emailField(),
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
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login-sign-in'),
            onPressed: _canSignIn ? _signIn : null,
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('login-forgot-password'),
            onPressed: _submitting ? null : _forgotPassword,
            child: const Text('Forgot password'),
          ),
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
