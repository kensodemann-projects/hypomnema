import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

const _edgeInset = 16.0;
const _iconGap = 12.0;
const _horizontalPadding = 16.0;
const _verticalPadding = 12.0;
const _iconSize = 24.0;
const _motionDuration = Duration(milliseconds: 250);
const _visible = Duration(seconds: 4);
const _gap = 16.0;

class LoginNotice {
  const LoginNotice({
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

class LoginSnackBar extends StatefulWidget {
  const LoginSnackBar({
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
  State<LoginSnackBar> createState() => _LoginSnackBarState();
}

class _LoginSnackBarState extends State<LoginSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _motion;
  Timer? _hideTimer;
  double? _anchorBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _motionDuration);
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
    _hideTimer = Timer(_visible, () {
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
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _iconGap,
              children: [
                Icon(widget.icon, size: _iconSize, color: foreground),
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
    final maxBarWidth = math.max(0.0, size.width - _edgeInset * 2);
    bar.layout(BoxConstraints(maxWidth: maxBarWidth), parentUsesSize: true);

    final anchorBottom = _anchorBottom;
    final restTop = anchorBottom == null ? size.height : anchorBottom + _gap;
    final top = size.height + (restTop - size.height) * _animation.value;
    final parentData = bar.parentData! as BoxParentData;
    parentData.offset = Offset((size.width - bar.size.width) / 2, top);
  }
}
