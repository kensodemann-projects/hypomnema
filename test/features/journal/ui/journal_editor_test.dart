import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
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

class _RecordingJournalEntries implements JournalEntryRepository {
  final saves = <({String subject, int mood, String text, bool private})>[];
  var updateCalls = 0;
  Object? saveError;
  Future<void> Function()? onSave;

  @override
  Future<JournalEntry> save({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    saves.add((subject: subject, mood: mood, text: text, private: private));
    final hook = onSave;
    if (hook != null) {
      await hook();
    }
    final error = saveError;
    if (error != null) {
      throw error;
    }
    return JournalEntry.create(
      id: 'entry-1',
      subject: subject,
      mood: mood,
      text: text,
      private: private,
      now: DateTime.utc(2026, 11, 24, 18),
    );
  }

  @override
  Future<JournalEntry> update({
    required JournalEntry entry,
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    updateCalls += 1;
    return entry.revise(
      subject: subject,
      mood: mood,
      text: text,
      private: private,
    );
  }
}

Future<_RecordingJournalEntries> _openEditor(
  WidgetTester tester, {
  required bool desktop,
  required ThemeData theme,
  required Size size,
  _RecordingJournalEntries? repository,
}) async {
  final repo = repository ?? _RecordingJournalEntries();
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
                  repository: repo,
                  desktop: desktop,
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
  return repo;
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
    final text = tester.widget<Text>(find.text('$label *'));
    final span = text.textSpan! as TextSpan;
    expect(span.style?.color, scheme.onSurfaceVariant);
    expect(span.style?.fontSize, 12);
    expect(span.style?.fontWeight, FontWeight.w500);
    final asterisk = span.children!.single as TextSpan;
    expect(asterisk.text, '*');
    expect(asterisk.style?.color, scheme.error);
  }
}

void expectDateNote(WidgetTester tester, ColorScheme scheme) {
  final note = tester.widget<Text>(find.byKey(const Key('journal-date-note')));
  expect(note.data, _dateNote);
  expect(note.style?.fontSize, 12);
  expect(note.style?.color, scheme.onSurfaceVariant);
  final title = find.textContaining('New ');
  expect(
    tester.getRect(find.byKey(const Key('journal-date-note'))).top,
    tester.getRect(title).bottom,
  );
}

void expectAbsentLaterTasks() {
  expect(find.textContaining("I'm Stuck"), findsNothing);
  expect(find.textContaining('Private'), findsNothing);
  expect(find.textContaining('Prompt'), findsNothing);
}

void expectUnfocusedSubject(WidgetTester tester, ColorScheme scheme) {
  final field = tester.widget<TextField>(find.byKey(_subjectKey));
  final border = field.decoration!.enabledBorder! as OutlineInputBorder;
  expect(field.maxLines, 1);
  expect(field.style?.fontSize, 14);
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
  final field = tester.widget<TextField>(find.byKey(_textKey));
  expect(field.style?.fontSize, 16);
  expect(field.style?.height, 1.7);
  expect(field.decoration?.hintText, _journalHint);
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
          size: const Size(400, 800),
        );

        expect(find.text('New entry'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byType(Scaffold), findsWidgets);
        final scaffold = tester.widget<Scaffold>(find.byKey(_editorKey));
        expect(scaffold.backgroundColor, scheme.surface);
        expect(tester.getSize(find.byKey(_editorKey)), const Size(400, 800));
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
        expect(tester.widget<Text>(find.text('New entry')).style?.fontSize, 18);
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
          size: const Size(1200, 800),
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
        expect(
          tester.widget<Text>(find.text('New journal entry')).style?.fontSize,
          22,
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
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );

      expectSaveDisabled(tester);
      expect(repo.saves, isEmpty);
      expect(repo.updateCalls, 0);
    },
  );

  testWidgets(
    'Given a whitespace subject, when the other fields are filled, then Save stays disabled',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );

      await enterEntry(tester, subject: '   ', text: 'hello', mood: 3);

      expectSaveDisabled(tester);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given whitespace journal text, when the other fields are filled, then Save stays disabled',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );

      await enterEntry(tester, subject: 'Note', text: '   ', mood: 4);

      expectSaveDisabled(tester);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given no mood, when subject and text are filled, then Save stays disabled',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );

      await enterEntry(tester, subject: 'Note', text: 'hello');

      expectSaveDisabled(tester);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped on the phone, then save stores the trimmed public entry and the page closes',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );
      await enterEntry(tester, subject: '  Note  ', text: '  hello  ', mood: 4);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repo.saves, [
        (subject: 'Note', mood: 4, text: 'hello', private: false),
      ]);
      expect(repo.updateCalls, 0);
      expect(find.byKey(_editorKey), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped on the desktop, then save stores the trimmed public entry and the dialog closes',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(1200, 800),
      );
      await enterEntry(tester, subject: '  Note  ', text: '  hello  ', mood: 2);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repo.saves, [
        (subject: 'Note', mood: 2, text: 'hello', private: false),
      ]);
      expect(repo.updateCalls, 0);
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save in flight, when Save is tapped again, then save is called once',
    (tester) async {
      final gate = Completer<void>();
      final repo = _RecordingJournalEntries()..onSave = () => gate.future;
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
        repository: repo,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 3);

      await tester.tap(find.byKey(_saveKey));
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pump();

      expect(repo.saves, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
      expect(repo.saves, hasLength(1));
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save in flight, when Close is tapped, then the editor stays until the save finishes',
    (tester) async {
      final gate = Completer<void>();
      final repo = _RecordingJournalEntries()..onSave = () => gate.future;
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
        repository: repo,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 1);

      await tester.tap(find.byKey(_saveKey));
      await tester.pump();
      await tester.tap(find.byKey(_closeKey));
      await tester.pump();

      expect(find.byKey(_editorKey), findsOneWidget);
      expect(repo.saves, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(_editorKey), findsNothing);
    },
  );

  testWidgets(
    'Given a save that fails, when Save is tapped, then the editor stays open and the failure snackbar is shown',
    (tester) async {
      final repo = _RecordingJournalEntries()..saveError = Exception('offline');
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
        repository: repo,
      );
      await enterEntry(tester, subject: 'Note', text: 'hello', mood: 5);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(find.text('New entry'), findsOneWidget);
      expect(find.byKey(_editorKey), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final scheme = AppTheme.light.colorScheme;
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, scheme.errorContainer);
      expect(
        tester.widget<Text>(find.text(_saveFailed)).style?.color,
        scheme.error,
      );
      expect(repo.updateCalls, 0);
    },
  );

  testWidgets(
    'Given the phone editor, when Close is tapped, then the page closes and nothing is written',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
      );

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given the desktop editor, when Cancel is tapped, then the dialog closes and nothing is written',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(1200, 800),
      );

      await tester.tap(find.byKey(const Key('journal-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given the desktop editor, when Close is tapped, then the dialog closes and nothing is written',
    (tester) async {
      final repo = await _openEditor(
        tester,
        desktop: true,
        theme: AppTheme.light,
        size: const Size(1200, 800),
      );

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(repo.saves, isEmpty);
    },
  );

  testWidgets(
    'Given journal text on several lines, when it is entered, then the line breaks stay in the field',
    (tester) async {
      await _openEditor(
        tester,
        desktop: false,
        theme: AppTheme.light,
        size: const Size(400, 800),
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
        size: const Size(400, 800),
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
}
