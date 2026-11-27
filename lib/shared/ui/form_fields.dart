import 'dart:ui' show SemanticsValidationResult;

import 'package:material_ui/material_ui.dart';

/// A label above [child].
///
/// The asterisk is drawn when [isRequired] is true. The label stays in the
/// semantics tree. A text field that carries its own name passes
/// [excludeLabel] so the visible label is not read again.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.child,
    this.isRequired = false,
    this.excludeLabel = false,
    super.key,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final bool excludeLabel;

  @override
  Widget build(BuildContext context) {
    final labelWidget = _FieldLabel(label: label, isRequired: isRequired);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (excludeLabel) ExcludeSemantics(child: labelWidget) else labelWidget,
        child,
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.isRequired});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    if (!isRequired) {
      return Text(label, style: style);
    }
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: style,
        children: [
          TextSpan(
            text: '*',
            style: TextStyle(color: scheme.error),
          ),
        ],
      ),
    );
  }
}

/// The shared outline text field: label above a surface box.
///
/// [hintText] is placeholder copy. [error] is the caller's validation message.
/// It colors the border, names the field's hint, and is announced under the
/// box. This field does not clear [error], and a caller [error] takes
/// precedence over the required message below.
///
/// When [isRequired] is true, the label shows an asterisk, the field is
/// marked required, and "`label` is required." appears when the trimmed text
/// is empty after the field loses focus. [OutlineTextFieldState.validateRequired]
/// shows that same message on demand.
///
/// Pass a [focusNode] to keep ownership outside this field; otherwise the
/// field creates and disposes its own.
class OutlineTextField extends StatefulWidget {
  const OutlineTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    this.focusNode,
    this.error,
    this.isRequired = false,
    this.style,
    this.hintText,
    this.minHeight,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? error;
  final bool isRequired;
  final TextStyle? style;
  final String? hintText;
  final double? minHeight;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OutlineTextField> createState() => OutlineTextFieldState();
}

class OutlineTextFieldState extends State<OutlineTextField> {
  FocusNode? _ownedFocus;
  String? _requiredError;
  late String _text;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocus!;

  /// Shows the required message when this field is required and its trimmed
  /// text is empty. Clears that message when the text is not empty.
  void validateRequired() {
    setState(_assignRequiredError);
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode();
    }
    _focusNode.addListener(_onFocus);
    _text = widget.controller.text;
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(OutlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      _text = widget.controller.text;
      widget.controller.addListener(_onText);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocus)?.removeListener(_onFocus);
      if (widget.focusNode == null) {
        _ownedFocus ??= FocusNode();
      } else {
        _ownedFocus?.dispose();
        _ownedFocus = null;
      }
      _focusNode.addListener(_onFocus);
    }
    if (!widget.isRequired) {
      _requiredError = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focusNode.removeListener(_onFocus);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    setState(() {
      if (!_focusNode.hasFocus) {
        _assignRequiredError();
      }
    });
  }

  void _onText() {
    final text = widget.controller.text;
    if (text == _text) {
      return;
    }
    _text = text;
    if (_requiredError == null) {
      return;
    }
    setState(() => _requiredError = null);
  }

  void _assignRequiredError() {
    final text = widget.controller.text.trim();
    _requiredError = widget.isRequired && text.isEmpty
        ? '${widget.label} is required.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    final error = widget.error ?? _requiredError;
    final invalid = error != null;
    final padding = focused
        ? const EdgeInsets.symmetric(horizontal: 13, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 11);
    final borderColor = invalid
        ? scheme.error
        : focused
        ? scheme.primary
        : scheme.outline;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: borderColor, width: focused ? 2 : 1),
    );
    final minLines = widget.minLines;
    final multiline = minLines != null;
    final minHeight = widget.minHeight;
    final hintText = widget.hintText;
    // The decorator merges hintText into the field label. Keep the placeholder
    // visible, and announce it as the hint only when there is no validation
    // message, so the accessible name stays the field label.
    final field = Semantics(
      container: true,
      explicitChildNodes: false,
      label: widget.label,
      isRequired: widget.isRequired,
      hint: error ?? hintText,
      validationResult: invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        style: widget.style,
        keyboardType:
            widget.keyboardType ??
            (multiline ? TextInputType.multiline : TextInputType.text),
        textInputAction:
            widget.textInputAction ??
            (multiline ? TextInputAction.newline : TextInputAction.next),
        autofillHints: widget.autofillHints,
        obscureText: widget.obscureText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        minLines: minLines,
        maxLines: multiline ? null : 1,
        textAlignVertical: multiline ? TextAlignVertical.top : null,
        decoration: InputDecoration(
          hint: hintText == null
              ? null
              : ExcludeSemantics(
                  child: Text(
                    hintText,
                    style: widget.style?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: padding,
          constraints: minHeight == null
              ? null
              : BoxConstraints(minHeight: minHeight),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          disabledBorder: border,
        ),
      ),
    );

    return LabeledField(
      label: widget.label,
      isRequired: widget.isRequired,
      excludeLabel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          field,
          if (error != null)
            Semantics(
              container: true,
              liveRegion: !MediaQuery.supportsAnnounceOf(context),
              child: Text(error, style: TextStyle(color: scheme.error)),
            ),
        ],
      ),
    );
  }
}
