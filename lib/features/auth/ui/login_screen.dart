import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
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

const _snackBarEdgeInset = 16.0;
const _snackBarIconGap = 12.0;
const _snackBarHorizontalPadding = 16.0;
const _snackBarVerticalPadding = 12.0;
const _snackBarIconSize = 24.0;
const _snackBarMotion = Duration(milliseconds: 250);
const _snackBarVisible = Duration(seconds: 4);
const _snackBarGap = 16.0;

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
  final _forgotPasswordAnchor = GlobalKey();

  String? _emailError;
  String? _passwordError;
  var _submitting = false;
  _LoginNotice? _notice;
  var _noticeId = 0;

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
      _notice = _LoginNotice(
        id: _noticeId,
        message: message,
        icon: icon,
        background: background,
        foreground: foreground,
      );
    });
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
                child: _SnackBarSlot(
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

class _LoginNotice {
  const _LoginNotice({
    required this.id,
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final int id;
  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;
}

class _SnackBarSlot extends StatefulWidget {
  const _SnackBarSlot({
    super.key,
    required this.anchorKey,
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onDismissed,
  });

  final GlobalKey anchorKey;
  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onDismissed;

  @override
  State<_SnackBarSlot> createState() => _SnackBarSlotState();
}

class _SnackBarSlotState extends State<_SnackBarSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _motion;
  Timer? _hideTimer;
  double? _anchorBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _snackBarMotion);
    _motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );
    _controller.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAnchor());
  }

  void _measureAnchor() {
    if (!mounted) {
      return;
    }
    final anchor = widget.anchorKey.currentContext?.findRenderObject();
    final slot = context.findRenderObject();
    if (anchor is! RenderBox ||
        slot is! RenderBox ||
        !anchor.hasSize ||
        !slot.hasSize) {
      return;
    }
    final anchorBottom = anchor.localToGlobal(Offset(0, anchor.size.height)).dy;
    final slotTop = slot.localToGlobal(Offset.zero).dy;
    setState(() => _anchorBottom = anchorBottom - slotTop);
    if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _hideTimer != null) {
      return;
    }
    _hideTimer = Timer(_snackBarVisible, () {
      if (!mounted) {
        return;
      }
      _controller.reverse().whenComplete(() {
        if (mounted) {
          widget.onDismissed();
        }
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeStatusListener(_onStatus);
    _motion.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.foreground;
    return _SnackBarPosition(
      anchorBottom: _anchorBottom,
      animation: _motion,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Material(
          key: const Key('login-snackbar'),
          color: widget.background,
          elevation: 6,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _snackBarHorizontalPadding,
              vertical: _snackBarVerticalPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _snackBarIconGap,
              children: [
                Icon(widget.icon, size: _snackBarIconSize, color: foreground),
                Flexible(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackBarPosition extends SingleChildRenderObjectWidget {
  const _SnackBarPosition({
    required this.anchorBottom,
    required this.animation,
    required super.child,
  });

  final double? anchorBottom;
  final Animation<double> animation;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSnackBarPosition(
      anchorBottom: anchorBottom,
      animation: animation,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSnackBarPosition renderObject,
  ) {
    renderObject
      ..anchorBottom = anchorBottom
      ..animation = animation;
  }
}

class _RenderSnackBarPosition extends RenderShiftedBox {
  _RenderSnackBarPosition({
    required this._anchorBottom,
    required this._animation,
  }) : super(null);

  double? _anchorBottom;
  Animation<double> _animation;

  double? get anchorBottom => _anchorBottom;

  set anchorBottom(double? value) {
    if (value == _anchorBottom) {
      return;
    }
    _anchorBottom = value;
    markNeedsLayout();
  }

  Animation<double> get animation => _animation;

  set animation(Animation<double> value) {
    if (identical(value, _animation)) {
      return;
    }
    if (attached) {
      _animation.removeListener(markNeedsLayout);
    }
    _animation = value;
    if (attached) {
      _animation.addListener(markNeedsLayout);
    }
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    final bar = child;
    if (bar == null) {
      size = constraints.biggest;
      return;
    }

    size = constraints.biggest;
    final maxBarWidth = math.max(0.0, size.width - _snackBarEdgeInset * 2);
    bar.layout(BoxConstraints(maxWidth: maxBarWidth), parentUsesSize: true);

    final anchorBottom = _anchorBottom;
    final restTop = anchorBottom == null
        ? size.height
        : anchorBottom + _snackBarGap;
    final top = size.height + (restTop - size.height) * _animation.value;
    final parentData = bar.parentData! as BoxParentData;
    parentData.offset = Offset((size.width - bar.size.width) / 2, top);
  }
}
