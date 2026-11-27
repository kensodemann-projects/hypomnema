import 'package:flutter/services.dart';
import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/auth/ui/hypomnema_logo.dart';
import 'package:hypomnema/features/auth/ui/login_snackbar.dart';
import 'package:hypomnema/shared/ui/form_fields.dart';
import 'package:material_ui/material_ui.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _emailFormatError(String text) {
  final email = text.trim();
  if (email.isEmpty || _emailPattern.hasMatch(email)) {
    return null;
  }
  return 'Enter a valid email address.';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailField = GlobalKey<OutlineTextFieldState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _forgotPasswordAnchor = GlobalKey();

  String? _emailError;
  var _submitting = false;
  LoginNotice? _notice;
  var _noticeId = 0;

  bool get _emailIsValid {
    final email = _emailController.text.trim();
    return email.isNotEmpty && _emailPattern.hasMatch(email);
  }

  bool get _canSignIn =>
      !_submitting &&
      _emailIsValid &&
      _passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocus);
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onEmailFocus);
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
    setState(() => _emailError = _emailFormatError(_emailController.text));
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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailField.currentState?.validateRequired();
      return;
    }
    final emailError = _emailFormatError(email);
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
    final colors = Theme.of(context).extension<AppColors>()!;
    _showSnackBar(
      message: message,
      icon: Icons.info_outline,
      background: colors.infoContainer,
      foreground: colors.info,
    );
  }

  void _showErrorSnackBar(String message) {
    final scheme = Theme.of(context).colorScheme;
    _showSnackBar(
      message: message,
      icon: Icons.error_outline,
      background: scheme.errorContainer,
      foreground: scheme.error,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    setState(() {
      _noticeId += 1;
      _notice = LoginNotice(
        id: _noticeId,
        message: message,
        icon: icon,
        background: background,
        foreground: foreground,
      );
    });
  }

  Widget _form() {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlineTextField(
            key: _emailField,
            label: 'Email',
            isRequired: true,
            fieldKey: const Key('login-email'),
            controller: _emailController,
            focusNode: _emailFocus,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() => _emailError = null),
            onSubmitted: _submitEmailField,
          ),
          const SizedBox(height: 16),
          OutlineTextField(
            label: 'Password',
            isRequired: true,
            fieldKey: const Key('login-password'),
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => setState(() {}),
            onSubmitted: _submitPasswordField,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login-sign-in'),
            onPressed: _canSignIn ? _signIn : null,
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _forgotPasswordAnchor,
            child: TextButton(
              key: const Key('login-forgot-password'),
              onPressed: _submitting ? null : _forgotPassword,
              child: const Text('Forgot password'),
            ),
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
      child: Material(
        type: MaterialType.transparency,
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
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _brandContent(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scaffold({required Widget body}) {
    final notice = _notice;
    return Scaffold(
      body: Stack(
        children: [
          body,
          if (notice != null)
            Positioned.fill(
              child: ClipRect(
                child: LoginSnackBar(
                  key: ValueKey(notice.id),
                  anchorKey: _forgotPasswordAnchor,
                  message: notice.message,
                  icon: notice.icon,
                  background: notice.background,
                  foreground: notice.foreground,
                  onDismissed: () {
                    if (mounted) {
                      setState(() => _notice = null);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _phoneLayout() {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return _scaffold(
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

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(child: _brandPanel()),
        SizedBox(
          key: const Key('login-form-side'),
          width: 520,
          child: _scaffold(
            body: CustomScrollView(
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (desktopLayoutFor(context)) {
      return _desktopLayout();
    }
    return _phoneLayout();
  }
}
