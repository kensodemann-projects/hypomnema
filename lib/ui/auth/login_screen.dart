import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widget_previews.dart';
import 'package:hypomnema/data/services/auth_service.dart';
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
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _authError = error.message ?? error.code);
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

  Future<void> _sendResetEmail() async {
    final emailError = _emailValidationError(_emailController.text);
    if (emailError != null) {
      setState(() {
        _emailError = emailError;
        _authError = null;
        _confirmation = null;
      });
      return;
    }

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
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _authError = error.message ?? error.code);
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
      decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
      onChanged: (_) => setState(() => _emailError = null),
    );
  }

  List<Widget> _feedback() {
    return [
      if (_authError != null) ...[
        const SizedBox(height: 16),
        Text(_authError!, key: const Key('login-error')),
      ],
      if (_confirmation != null) ...[
        const SizedBox(height: 16),
        Text(_confirmation!, key: const Key('login-reset-confirmation')),
      ],
    ];
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _emailField(),
        if (_resettingPassword) ...[
          ..._feedback(),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login-send-reset'),
            onPressed: _submitting ? null : _sendResetEmail,
            child: const Text('Send reset email'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('login-back-to-sign-in'),
            onPressed: _showSignInForm,
            child: const Text('Back to sign in'),
          ),
        ] else ...[
          const SizedBox(height: 16),
          TextField(
            key: const Key('login-password'),
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _passwordError,
            ),
            onChanged: (_) => setState(() => _passwordError = null),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final form = _form();
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  key: const Key('login-form-card'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: form,
                  ),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: form),
        );
      },
    );
  }
}

class _PreviewAuthService implements AuthService {
  const _PreviewAuthService();

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class LoginScreenPreviewHarness extends StatelessWidget {
  const LoginScreenPreviewHarness({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const LoginScreen(authService: _PreviewAuthService()),
    );
  }
}

@Preview(name: 'Phone', group: 'Login screen', size: Size(400, 800))
Widget phoneLoginScreenPreview() => const LoginScreenPreviewHarness();

@Preview(name: 'Desktop', group: 'Login screen', size: Size(1200, 800))
Widget desktopLoginScreenPreview() => const LoginScreenPreviewHarness();
