import 'dart:async';
import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/journal_editor.dart';
import 'package:hypomnema/features/journal/ui/mood_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/viewport.dart';

const _dateNote = 'Date and time are set when you save';
const _journalHint = 'Write whatever is on your mind…';
const _saveFailed = 'The entry could not be saved.';
const _editorKey = Key('journal-editor');
const _saveKey = Key('journal-save');
const _closeKey = Key('journal-close');
const _subjectKey = Key('journal-subject');
const _textKey = Key('journal-text');

class _Submissions {
  final calls = <({String subject, int mood, String text, bool private})>[];
  Object? error;
  Future<void> Function()? gate;

  Future<void> submit({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    calls.add((subject: subject, mood: mood, text: text, private: private));
    final gate = this.gate;
    if (gate != null) {
      await gate();
    }
    final error = this.error;
    if (error != null) {
      throw error;
    }
  }
}

Future<_Submissions> _openEditor(
  WidgetTester tester, {
  required bool desktop,
  required ThemeData theme,
  required Size size,
  _Submissions? submissions,
  String subject = '',
  int? mood,
  String text = '',
  bool private = false,
}) async {
  final recorder = submissions ?? _Submissions();
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                final editor = JournalEditor(
                  desktop: desktop,
                  onSubmit: recorder.submit,
                  subject: subject,
                  mood: mood,
                  text: text,
                  private: private,
                );
                if (desktop) {
                  showDialog<void>(
                    context: context,
                    barrierColor: Theme.of(context).colorScheme.scrim,
                    builder: (context) => editor,
                  );
                  return;
                }
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (context) => editor));
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return recorder;
}

Future<void> enterEntry(
  WidgetTester tester, {
  required String subject,
  required String text,
  int? mood,
}) async {
  await tester.enterText(find.byKey(_subjectKey), subject);
  await tester.enterText(find.byKey(_textKey), text);
  if (mood != null) {
    await tester.tap(find.byKey(Key('mood-option-$mood')));
  }
  await tester.pump();
}

void expectSaveDisabled(WidgetTester tester) {
  expect(
    tester.widget<ButtonStyleButton>(find.byKey(_saveKey)).onPressed,
    isNull,
  );
}

void expectRequiredLabels(WidgetTester tester, ColorScheme scheme) {
  for (final label in ['Subject', 'Mood', 'Journal']) {
    final finder = find.text('$label *');
    final text = tester.widget<Text>(finder);
    final span = text.textSpan! as TextSpan;
    final role = Theme.of(tester.element(finder)).textTheme.labelMedium;
    expect(span.style?.color, scheme.onSurfaceVariant);
    expect(span.style?.fontSize, role?.fontSize);
    expect(span.style?.fontWeight, role?.fontWeight);
    expect(span.style?.height, role?.height);
    expect(span.style?.letterSpacing, role?.letterSpacing);
    final asterisk = span.children!.single as TextSpan;
    expect(asterisk.text, '*');
    expect(asterisk.style?.color, scheme.error);
  }
}

void _expectRole(TextStyle? style, TextStyle? role) {
  expect(style?.fontSize, role?.fontSize);
  expect(style?.fontWeight, role?.fontWeight);
  expect(style?.height, role?.height);
  expect(style?.letterSpacing, role?.letterSpacing);
}

void expectDateNote(WidgetTester tester, ColorScheme scheme) {
  final noteFinder = find.byKey(const Key('journal-date-note'));
  final note = tester.widget<Text>(noteFinder);
  expect(note.data, _dateNote);
  _expectRole(
    note.style,
    Theme.of(tester.element(noteFinder)).textTheme.bodySmall,
  );
  expect(note.style?.color, scheme.onSurfaceVariant);
  final title = find.textContaining('New ');
  expect(
    tester.getRect(find.byKey(const Key('journal-date-note'))).top,
    tester.getRect(title).bottom,
  );
}

void expectAbsentLaterTasks() {
  expect(find.textContaining("I'm Stuck"), findsNothing);
  expect(find.textContaining('Prompt'), findsNothing);
}

const _phonePrivateSupport = 'Hide subject and text until Show Content';
const _desktopPrivateSupport =
    'Hide the subject and text until you choose Show Content';

Finder _privateSwitch() {
  return find.descendant(
    of: find.byKey(const Key('journal-private')),
    matching: find.byType(Switch),
  );
}

void expectPrivateSwitch(
  WidgetTester tester, {
  required bool desktop,
  required bool value,
  required ColorScheme scheme,
}) {
  final row = find.byKey(const Key('journal-private'));
  final title = find.descendant(of: row, matching: find.text('Private'));
  final support = find.descendant(
    of: row,
    matching: find.text(
      desktop ? _desktopPrivateSupport : _phonePrivateSupport,
    ),
  );
  final textTheme = Theme.of(tester.element(title)).textTheme;
  _expectRole(tester.widget<Text>(title).style, textTheme.titleMedium);
  final supportText = tester.widget<Text>(support);
  _expectRole(supportText.style, textTheme.bodySmall);
  expect(supportText.style?.color, scheme.onSurfaceVariant);
  expect(tester.widget<Switch>(_privateSwitch()).value, value);
  expect(
    tester.getTopLeft(_privateSwitch()).dx,
    lessThan(tester.getTopLeft(title).dx),
  );
  expect(
    tester.getTopLeft(row).dy,
    greaterThan(tester.getBottomLeft(find.byKey(_textKey)).dy),
  );
}

void expectUnfocusedSubject(WidgetTester tester, ColorScheme scheme) {
  final fieldFinder = find.byKey(_subjectKey);
  final field = tester.widget<TextField>(fieldFinder);
  final border = field.decoration!.enabledBorder! as OutlineInputBorder;
  expect(field.maxLines, 1);
  _expectRole(
    field.style,
    Theme.of(tester.element(fieldFinder)).textTheme.titleMedium,
  );
  expect(field.decoration?.hintText, isNull);
  expect(border.borderRadius, const BorderRadius.all(Radius.circular(8)));
  expect(border.borderSide.color, scheme.outline);
  expect(border.borderSide.width, 1);
  expect(
    field.decoration?.contentPadding,
    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  );
}

void expectJournalText(WidgetTester tester, {required double minHeight}) {
  final fieldFinder = find.byKey(_textKey);
  final field = tester.widget<TextField>(fieldFinder);
  _expectRole(
    field.style,
    Theme.of(tester.element(fieldFinder)).textTheme.bodyLarge,
  );
  expect(field.decoration?.hintText, isNull);
  expect(find.text(_journalHint), findsOneWidget);
  expect(field.minLines, greaterThan(1));
  expect(field.maxLines, isNull);
  expect(field.keyboardType, TextInputType.multiline);
  expect(field.textInputAction, TextInputAction.newline);
  expect(field.textAlignVertical, TextAlignVertical.top);
  expect(
    tester.getSize(find.byKey(_textKey)).height,
    greaterThanOrEqualTo(minHeight),
  );
}

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness.name;
    final scheme = theme.colorScheme;

    testWidgets(
      'Given the $themeName phone editor, when it opens, then the page shows the contract copy on a surface',
      (tester) async {
        await _openEditor(
          tester,
          desktop: false,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth - 200, 800),
        );

        expect(find.text('New entry'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byType(Scaffold), findsWidgets);
        final scaffold = tester.widget<Scaffold>(find.byKey(_editorKey));
        expect(scaffold.backgroundColor, scheme.surface);
        expect(
          tester.getSize(find.byKey(_editorKey)),
          const Size(kDesktopLayoutMinWidth - 200, 800),
        );
        expect(
          tester.getSize(find.byKey(const Key('journal-top-bar'))).height,
          greaterThanOrEqualTo(64),
        );
        expect(tester.getTopLeft(find.byKey(_closeKey)).dx, 4);
        expect(tester.getSize(find.byKey(_closeKey)), const Size(48, 48));
        expect(
          tester.widget<Icon>(find.byIcon(Icons.close)).color,
          scheme.onSurfaceVariant,
        );
        expect(
          tester.widget<IconButton>(find.byKey(_closeKey)).tooltip,
          'Close',
        );
        final save = tester.widget<TextButton>(find.byKey(_saveKey));
        expect(
          save.style?.foregroundColor?.resolve(<WidgetState>{}),
          scheme.primary,
        );
        final title = find.text('New entry');
        _expectRole(
          tester.widget<Text>(title).style,
          Theme.of(tester.element(title)).textTheme.titleLarge,
        );
        expectDateNote(tester, scheme);
        expectRequiredLabels(tester, scheme);
        expectUnfocusedSubject(tester, scheme);
        expectJournalText(tester, minHeight: 220);
        expect(
          tester
              .widget<SingleChildScrollView>(
                find.byKey(const Key('journal-form')),
              )
              .padding,
          const EdgeInsets.fromLTRB(20, 8, 20, 24),
        );
        expect(
          tester
              .widget<Column>(find.byKey(const Key('journal-fields')))
              .spacing,
          14,
        );
        expect(
          tester.widget<MoodPicker>(find.byType(MoodPicker)).value,
          isNull,
        );
        expectAbsentLaterTasks();
        expectSaveDisabled(tester);
      },
    );

    testWidgets(
      'Given the $themeName desktop editor, when it opens, then the dialog shows the contract copy on a surface',
      (tester) async {
        await _openEditor(
          tester,
          desktop: true,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth + 600, 800),
        );

        expect(find.text('New journal entry'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
        final dialog = tester.widget<Dialog>(find.byKey(_editorKey));
        expect(dialog.backgroundColor, scheme.surface);
        final shape = dialog.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(28)));
        final material = find.descendant(
          of: find.byKey(_editorKey),
          matching: find.byType(Material),
        );
        expect(tester.getSize(material.first).width, 720);
        expect(tester.getSize(find.byKey(_closeKey)), const Size(36, 36));
        expect(
          tester.widget<Icon>(find.byIcon(Icons.close)).color,
          scheme.onSurfaceVariant,
        );
        final save = tester.widget<FilledButton>(find.byKey(_saveKey));
        expect(
          save.style?.backgroundColor?.resolve(<WidgetState>{}),
          scheme.primary,
        );
        expect(
          save.style?.foregroundColor?.resolve(<WidgetState>{}),
          scheme.onPrimary,
        );
        expect(
          tester.widget<Row>(find.byKey(const Key('journal-actions'))).spacing,
          8,
        );
        final title = find.text('New journal entry');
        _expectRole(
          tester.widget<Text>(title).style,
          Theme.of(tester.element(title)).textTheme.titleLarge,
        );
        expectDateNote(tester, scheme);
        expectRequiredLabels(tester, scheme);
        expectUnfocusedSubject(tester, scheme);
        expectJournalText(tester, minHeight: 260);
        expect(
          tester
              .widget<ListView>(find.byKey(const Key('journal-form')))
              .padding,
          const EdgeInsets.all(24),
        );
        expect(
          tester
              .widgetList<ModalBarrier>(find.byType(ModalBarrier))
              .map((barrier) => barrier.color),
          contains(scheme.scrim),
        );
        expect(
          tester.widget<MoodPicker>(find.byType(MoodPicker)).value,
          isNull,
        );
        expectAbsentLaterTasks();
        expectSaveDisabled(tester);
      },
    );
  }

  testWidgets(
    'Given an empty editor, when Save is read, then it is disabled and nothing is written',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      expectSaveDisabled(tester);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given a whitespace subject, when the other fields are filled, then Save stays disabled',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await enterEntry(tester, subject: '   ', text: 'hello', mood: 3);

      expectSaveDisabled(tester);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given whitespace journal text, when the other fields are filled, then Save stays disabled',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await enterEntry(tester, subject: 'Note', text: '   ', mood: 4);

      expectSaveDisabled(tester);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given no mood, when subject and text are filled, then Save stays disabled',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await enterEntry(tester, subject: 'Note', text: 'hello');

      expectSaveDisabled(tester);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped on the phone, then onSubmit receives the trimmed values and the page closes',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      await enterEntry(tester, subject: '  Note  ', text: '  hello  ', mood: 4);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 4, text: 'hello', private: false),
      ]);
      expect(find.byKey(_editorKey), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped on the desktop, then onSubmit receives the trimmed values and the dialog closes',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
      );
      await enterEntry(tester, subject: '  Note  ', text: '  hello  ', mood: 2);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 2, text: 'hello', private: false),
      ]);
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given an entry already filled in, when Save is tapped, then onSubmit receives those trimmed values',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
        subject: '  Note  ',
        mood: 3,
        text: '  hello  ',
      );

      expect(
        tester.widget<TextField>(find.byKey(_subjectKey)).controller?.text,
        '  Note  ',
      );
      expect(
        tester.widget<TextField>(find.byKey(_textKey)).controller?.text,
        '  hello  ',
      );
      expect(tester.widget<MoodPicker>(find.byType(MoodPicker)).value, 3);
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_saveKey)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 3, text: 'hello', private: false),
      ]);
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save in flight, when Save is tapped again, then save is called once',
    (tester) async {
      final gate = Completer<void>();
      final submissions = _Submissions()..gate = () => gate.future;
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
        submissions: submissions,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 3);

      await tester.tap(find.byKey(_saveKey));
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pump();

      expect(submissions.calls, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
      expect(submissions.calls, hasLength(1));
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save in flight, when Close is tapped, then it does nothing and a failed save stays on the editor',
    (tester) async {
      final gate = Completer<void>();
      final submissions = _Submissions();
      submissions.gate = () => gate.future;
      submissions.error = Exception('offline');
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
        submissions: submissions,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 1);

      await tester.tap(find.byKey(_saveKey));
      await tester.pump();

      expect(
        tester.widget<IconButton>(find.byKey(_closeKey)).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(_closeKey));
      await tester.pump();

      expect(find.byKey(_editorKey), findsOneWidget);
      expect(submissions.calls, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsOneWidget);
      expect(find.text(_saveFailed), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byKey(_closeKey)).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Given a save in flight on the desktop, when Cancel and Close are read, then they are disabled',
    (tester) async {
      final gate = Completer<void>();
      final submissions = _Submissions()..gate = () => gate.future;
      await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
        submissions: submissions,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 2);

      await tester.tap(find.byKey(_saveKey));
      await tester.pump();

      expect(
        tester.widget<IconButton>(find.byKey(_closeKey)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('journal-cancel')))
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save that fails, when Save is tapped, then the editor stays open and the failure snackbar is shown',
    (tester) async {
      final submissions = _Submissions()..error = Exception('offline');
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
        submissions: submissions,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 5);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(find.text('New entry'), findsOneWidget);
      expect(find.byKey(_editorKey), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final message = find.text(_saveFailed);
      final theme = Theme.of(tester.element(find.byType(SnackBar)));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, isNull);
      expect(tester.widget<Text>(message).style, isNull);
      expect(
        theme.snackBarTheme.backgroundColor,
        theme.colorScheme.errorContainer,
      );
      final effective = DefaultTextStyle.of(tester.element(message)).style;
      expect(effective.color, theme.colorScheme.onErrorContainer);
      _expectRole(effective, theme.textTheme.bodyMedium);
      expect(submissions.calls, hasLength(1));
    },
  );

  testWidgets(
    'Given the phone editor, when Close is tapped, then the page closes and nothing is written',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given the desktop editor, when Cancel is tapped, then the dialog closes and nothing is written',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
      );

      await tester.tap(find.byKey(const Key('journal-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given the desktop editor, when Close is tapped, then the dialog closes and nothing is written',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
      );

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given journal text on several lines, when it is entered, then the line breaks stay in the field',
    (tester) async {
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await tester.enterText(find.byKey(_textKey), 'First line\nSecond line');
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byKey(_textKey)).controller?.text,
        'First line\nSecond line',
      );
    },
  );

  testWidgets(
    'Given the subject field, when it is focused, then the border is primary and 2px with the tighter padding',
    (tester) async {
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await tester.tap(find.byKey(_subjectKey));
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(_subjectKey));
      final border = field.decoration!.focusedBorder! as OutlineInputBorder;
      expect(border.borderSide.color, AppTheme.light.colorScheme.primary);
      expect(border.borderSide.width, 2);
      expect(
        field.decoration?.contentPadding,
        const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      );
    },
  );

  testWidgets(
    'Given the editor fields, when they render, then each text field carries its name and the journal hint stays the placeholder',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      SemanticsData fieldData(Key key) {
        return tester.getSemantics(find.byKey(key)).getSemanticsData();
      }

      final subject = fieldData(_subjectKey);
      expect(subject.label, 'Subject');
      expect(subject.flagsCollection.isTextField, isTrue);
      expect(subject.flagsCollection.isRequired, Tristate.isTrue);
      expect(subject.hint, isEmpty);
      expect(subject.validationResult, SemanticsValidationResult.none);

      final journal = fieldData(_textKey);
      expect(journal.label, 'Journal');
      expect(journal.flagsCollection.isTextField, isTrue);
      expect(journal.flagsCollection.isRequired, Tristate.isTrue);
      expect(journal.hint, _journalHint);
      expect(journal.validationResult, SemanticsValidationResult.none);

      final mood = tester.getSemantics(find.text('Mood *')).getSemanticsData();
      expect(mood.label, 'Mood *');

      handle.dispose();
    },
  );

  testWidgets(
    'Given an empty Subject or Journal, when the field loses focus, then its required message appears',
    (tester) async {
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await tester.tap(find.byKey(_subjectKey));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.text('Subject is required.'), findsOneWidget);

      await tester.enterText(find.byKey(_subjectKey), 'a');
      await tester.pump();
      expect(find.text('Subject is required.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(_subjectKey)).focusNode?.hasFocus,
        isTrue,
      );

      await tester.tap(find.byKey(_textKey));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.text('Journal is required.'), findsOneWidget);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness.name;
    final scheme = theme.colorScheme;

    testWidgets(
      'Given a new $themeName phone editor, when it opens, then Private starts off with the phone support line',
      (tester) async {
        await _openEditor(
          tester,
          desktop: false,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth - 200, 800),
        );

        expectPrivateSwitch(
          tester,
          desktop: false,
          value: false,
          scheme: scheme,
        );
        expect(find.text(_desktopPrivateSupport), findsNothing);
      },
    );

    testWidgets(
      'Given a new $themeName desktop editor, when it opens, then Private starts off with the desktop support line',
      (tester) async {
        await _openEditor(
          tester,
          desktop: true,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth + 600, 800),
        );

        expectPrivateSwitch(
          tester,
          desktop: true,
          value: false,
          scheme: scheme,
        );
        expect(find.text(_phonePrivateSupport), findsNothing);
      },
    );

    testWidgets(
      'Given private is on for a $themeName phone edit, when the editor opens, then the switch starts on',
      (tester) async {
        await _openEditor(
          tester,
          desktop: false,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth - 200, 800),
          private: true,
        );

        expectPrivateSwitch(
          tester,
          desktop: false,
          value: true,
          scheme: scheme,
        );
      },
    );

    testWidgets(
      'Given private is on for a $themeName desktop edit, when the editor opens, then the switch starts on',
      (tester) async {
        await _openEditor(
          tester,
          desktop: true,
          theme: theme,
          size: const Size(kDesktopLayoutMinWidth + 600, 800),
          private: true,
        );

        expectPrivateSwitch(tester, desktop: true, value: true, scheme: scheme);
      },
    );
  }

  testWidgets(
    'Given an empty phone editor, when Private is toggled, then Save stays disabled',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      await tester.tap(_privateSwitch());
      await tester.pump();

      expect(tester.widget<Switch>(_privateSwitch()).value, isTrue);
      expectSaveDisabled(tester);
      expect(submissions.calls, isEmpty);
    },
  );

  testWidgets(
    'Given a filled phone editor, when Private is turned on and Save is tapped, then onSubmit receives private true',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 4);
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_saveKey)).onPressed,
        isNotNull,
      );

      await tester.tap(_privateSwitch());
      await tester.pump();
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_saveKey)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 4, text: 'hello', private: true),
      ]);
    },
  );

  testWidgets(
    'Given a filled desktop editor, when Private is turned on and Save is tapped, then onSubmit receives private true',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 2);

      await tester.tap(_privateSwitch());
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 2, text: 'hello', private: true),
      ]);
    },
  );

  testWidgets(
    'Given a phone edit that starts private, when the switch is turned off and Save is tapped, then onSubmit receives private false',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
        subject: 'Note',
        mood: 3,
        text: 'hello',
        private: true,
      );

      expect(tester.widget<Switch>(_privateSwitch()).value, isTrue);
      await tester.tap(_privateSwitch());
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 3, text: 'hello', private: false),
      ]);
    },
  );

  testWidgets(
    'Given a desktop edit that starts private, when the switch is turned off and Save is tapped, then onSubmit receives private false',
    (tester) async {
      final submissions = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(kDesktopLayoutMinWidth + 125, 800),
        subject: 'Note',
        mood: 3,
        text: 'hello',
        private: true,
      );

      expect(tester.widget<Switch>(_privateSwitch()).value, isTrue);
      await tester.tap(_privateSwitch());
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(submissions.calls, [
        (subject: 'Note', mood: 3, text: 'hello', private: false),
      ]);
    },
  );
}
