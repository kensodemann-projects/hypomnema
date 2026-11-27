import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/shared/ui/form_fields.dart';
import 'package:material_ui/material_ui.dart';

const _fieldKey = Key('field');
const _hint = 'Write whatever is on your mind…';
const _callerError = 'Enter a valid email address.';

class _FieldHost extends StatefulWidget {
  const _FieldHost({
    required this.isRequired,
    required this.label,
    this.hintText,
  });

  final bool isRequired;
  final String label;
  final String? hintText;

  @override
  State<_FieldHost> createState() => _FieldHostState();
}

class _FieldHostState extends State<_FieldHost> {
  final controller = TextEditingController();
  final fieldKey = GlobalKey<OutlineTextFieldState>();
  String? error;

  void showError(String? message) {
    setState(() => error = message);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: OutlineTextField(
          key: fieldKey,
          label: widget.label,
          isRequired: widget.isRequired,
          fieldKey: _fieldKey,
          controller: controller,
          error: error,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}

Future<_FieldHostState> _pumpField(
  WidgetTester tester, {
  required bool isRequired,
  required String label,
  String? hintText,
}) async {
  await tester.pumpWidget(
    _FieldHost(isRequired: isRequired, label: label, hintText: hintText),
  );
  return tester.state<_FieldHostState>(find.byType(_FieldHost));
}

Future<void> _unfocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

void _expectAsterisk(WidgetTester tester, String label, ColorScheme scheme) {
  final text = tester.widget<Text>(find.text('$label *'));
  final span = text.textSpan! as TextSpan;
  expect(span.style?.color, scheme.onSurfaceVariant);
  expect(span.style?.fontSize, 12);
  expect(span.style?.fontWeight, FontWeight.w500);
  expect(span.style?.height, isNull);
  expect(span.style?.letterSpacing, isNull);
  final asterisk = span.children!.single as TextSpan;
  expect(asterisk.text, '*');
  expect(asterisk.style?.color, scheme.error);
  expect(asterisk.style?.fontSize, isNull);
  expect(asterisk.style?.fontWeight, isNull);
}

void _expectNoTypeMetrics(TextStyle? style) {
  expect(style?.fontSize, isNull);
  expect(style?.fontWeight, isNull);
  expect(style?.height, isNull);
  expect(style?.letterSpacing, isNull);
}

void main() {
  testWidgets(
    'Given a required outline field, when it is empty or edited, then the label, semantics, and required message follow the field',
    (tester) async {
      final handle = tester.ensureSemantics();
      final host = await _pumpField(
        tester,
        isRequired: true,
        label: 'Subject',
        hintText: _hint,
      );
      final scheme = AppTheme.light.colorScheme;

      _expectAsterisk(tester, 'Subject', scheme);
      expect(
        tester.getRect(find.text('Subject *')).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(_fieldKey)).top),
      );
      expect(find.bySemanticsLabel('Subject *'), findsNothing);
      expect(find.text(_hint), findsOneWidget);

      SemanticsData fieldData() {
        return tester.getSemantics(find.byKey(_fieldKey)).getSemanticsData();
      }

      final named = fieldData();
      expect(named.label, 'Subject');
      expect(named.flagsCollection.isTextField, isTrue);
      expect(named.flagsCollection.isRequired, Tristate.isTrue);
      expect(named.hint, _hint);
      expect(named.validationResult, SemanticsValidationResult.none);
      expect(find.text('Subject is required.'), findsNothing);

      host.fieldKey.currentState!.validateRequired();
      await tester.pump();

      expect(find.text('Subject is required.'), findsOneWidget);
      expect(fieldData().hint, 'Subject is required.');
      expect(fieldData().validationResult, SemanticsValidationResult.invalid);
      final message = tester.widget<Text>(find.text('Subject is required.'));
      expect(message.style?.color, scheme.error);
      _expectNoTypeMetrics(message.style);
      expect(
        tester.getRect(find.text('Subject is required.')).top,
        greaterThanOrEqualTo(tester.getRect(find.byKey(_fieldKey)).bottom),
      );

      await tester.enterText(find.byKey(_fieldKey), 'a');
      await tester.pump();
      expect(find.text('Subject is required.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(_fieldKey)).focusNode?.hasFocus,
        isTrue,
      );

      await tester.enterText(find.byKey(_fieldKey), '');
      await tester.pump();
      expect(find.text('Subject is required.'), findsNothing);
      await _unfocus(tester);
      expect(find.text('Subject is required.'), findsOneWidget);

      await tester.tap(find.byKey(_fieldKey));
      await tester.pump();
      expect(find.text('Subject is required.'), findsOneWidget);
      final focused =
          tester
                  .widget<TextField>(find.byKey(_fieldKey))
                  .decoration!
                  .focusedBorder!
              as OutlineInputBorder;
      expect(focused.borderSide.color, scheme.error);
      expect(focused.borderSide.width, 2);

      await tester.enterText(find.byKey(_fieldKey), '   ');
      await tester.pump();
      expect(find.text('Subject is required.'), findsNothing);
      await _unfocus(tester);
      expect(find.text('Subject is required.'), findsOneWidget);
      final blurred =
          tester
                  .widget<TextField>(find.byKey(_fieldKey))
                  .decoration!
                  .enabledBorder!
              as OutlineInputBorder;
      expect(blurred.borderSide.color, scheme.error);
      expect(blurred.borderSide.width, 1);

      await tester.enterText(find.byKey(_fieldKey), 'kept');
      await tester.pump();
      await _unfocus(tester);
      expect(find.text('Subject is required.'), findsNothing);
      expect(fieldData().hint, _hint);
      expect(fieldData().validationResult, SemanticsValidationResult.none);

      await tester.enterText(find.byKey(_fieldKey), '');
      await tester.pump();
      await _unfocus(tester);
      host.showError(_callerError);
      await tester.pump();
      expect(find.text(_callerError), findsOneWidget);
      expect(find.text('Subject is required.'), findsNothing);
      expect(fieldData().hint, _callerError);

      host.showError(null);
      await tester.pump();
      expect(find.text('Subject is required.'), findsOneWidget);
      expect(find.text(_callerError), findsNothing);

      await tester.enterText(find.byKey(_fieldKey), 'a');
      await tester.pump();
      expect(find.text('Subject is required.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(_fieldKey)).focusNode?.hasFocus,
        isTrue,
      );

      handle.dispose();
    },
  );

  testWidgets(
    'Given an optional outline field, when it is empty, then it stays optional and shows only a caller message',
    (tester) async {
      final handle = tester.ensureSemantics();
      final host = await _pumpField(tester, isRequired: false, label: 'Note');
      final scheme = AppTheme.light.colorScheme;

      expect(find.text('Note *'), findsNothing);
      expect(find.text('Note'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Note')).style?.fontSize, 12);
      expect(
        tester.widget<Text>(find.text('Note')).style?.fontWeight,
        FontWeight.w500,
      );
      expect(find.bySemanticsLabel('Note *'), findsNothing);

      final field = tester
          .getSemantics(find.byKey(_fieldKey))
          .getSemanticsData();
      expect(field.label, 'Note');
      expect(field.flagsCollection.isTextField, isTrue);
      expect(field.flagsCollection.isRequired, Tristate.isFalse);
      expect(field.validationResult, SemanticsValidationResult.none);

      host.fieldKey.currentState!.validateRequired();
      await tester.pump();
      await tester.tap(find.byKey(_fieldKey));
      await tester.pump();
      await _unfocus(tester);
      expect(find.text('Note is required.'), findsNothing);

      host.showError(_callerError);
      await tester.pump();
      expect(find.text(_callerError), findsOneWidget);
      expect(
        (tester.widget<TextField>(find.byKey(_fieldKey)).decoration!.border!
                as OutlineInputBorder)
            .borderSide
            .color,
        scheme.error,
      );
      expect(
        tester.getSemantics(find.byKey(_fieldKey)).getSemanticsData().hint,
        _callerError,
      );

      await tester.enterText(find.byKey(_fieldKey), 'a');
      await tester.pump();
      expect(find.text(_callerError), findsOneWidget);

      handle.dispose();
    },
  );

  testWidgets(
    'Given a labeled field, when it is required or optional, then the asterisk and the label semantics follow that flag',
    (tester) async {
      final handle = tester.ensureSemantics();
      final scheme = AppTheme.light.colorScheme;

      Future<void> pump({required bool isRequired}) {
        return tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: LabeledField(
                label: 'Mood',
                isRequired: isRequired,
                child: const SizedBox(key: Key('mood'), height: 20),
              ),
            ),
          ),
        );
      }

      await pump(isRequired: true);
      _expectAsterisk(tester, 'Mood', scheme);
      expect(
        tester.getSemantics(find.text('Mood *')).getSemanticsData().label,
        'Mood *',
      );

      await pump(isRequired: false);
      expect(find.text('Mood *'), findsNothing);
      expect(find.text('Mood'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Mood')).getSemanticsData().label,
        'Mood',
      );

      handle.dispose();
    },
  );
}
