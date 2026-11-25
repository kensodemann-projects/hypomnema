import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/journal_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_journal_entry_repository.dart';
import '../../../helpers/viewport.dart';

const _saveFailed = 'The entry could not be saved.';
const _writeKey = Key('journal-write');
const _editorKey = Key('journal-editor');
const _saveKey = Key('journal-save');
const _closeKey = Key('journal-close');
const _cancelKey = Key('journal-cancel');
const _subjectKey = Key('journal-subject');
const _textKey = Key('journal-text');

Future<FakeJournalEntryRepository> _pumpJournalScreen(
  WidgetTester tester, {
  required Size size,
  FakeJournalEntryRepository? repository,
}) async {
  final entries = repository ?? FakeJournalEntryRepository();
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: JournalScreen(repository: entries),
    ),
  );
  await tester.pumpAndSettle();
  return entries;
}

Future<void> _enterEntry(
  WidgetTester tester, {
  required String subject,
  required String text,
  required int mood,
}) async {
  await tester.enterText(find.byKey(_subjectKey), subject);
  await tester.enterText(find.byKey(_textKey), text);
  await tester.tap(find.byKey(Key('mood-option-$mood')));
  await tester.pump();
}

void main() {
  testWidgets(
    'Given the journal screen at 400px, when Write is tapped, then a full-screen editor opens and Close returns to Write',
    (tester) async {
      await _pumpJournalScreen(tester, size: const Size(400, 800));
      final write = tester.getRect(find.byKey(_writeKey));
      expect(tester.widget(find.byKey(_writeKey)), isA<FilledButton>());
      expect(write.center, const Offset(200, 400));

      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();

      expect(find.text('New entry'), findsOneWidget);
      expect(find.byKey(_closeKey), findsOneWidget);
      expect(find.byKey(_saveKey), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.byKey(_writeKey), findsNothing);
      expect(tester.getSize(find.byKey(_editorKey)), const Size(400, 800));

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given the journal screen above 600px, when Write is tapped, then the dialog opens and Cancel returns to Write',
    (tester) async {
      await _pumpJournalScreen(tester, size: const Size(1200, 800));

      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();

      expect(find.text('New journal entry'), findsOneWidget);
      expect(find.byKey(_cancelKey), findsOneWidget);
      expect(find.byKey(_saveKey), findsOneWidget);
      expect(find.byKey(_closeKey), findsOneWidget);

      await tester.tap(find.byKey(_cancelKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given the desktop editor opened from Write, when Close is tapped, then Write returns',
    (tester) async {
      await _pumpJournalScreen(tester, size: const Size(1200, 800));
      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped from Write, then save stores the trimmed public entry and Write returns',
    (tester) async {
      final entries = await _pumpJournalScreen(
        tester,
        size: const Size(400, 800),
      );
      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();
      await _enterEntry(
        tester,
        subject: '  Note  ',
        text: '  hello  ',
        mood: 4,
      );

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(entries.saves, [
        (subject: 'Note', mood: 4, text: 'hello', private: false),
      ]);
      expect(entries.updateCalls, 0);
      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given a save that fails, when Save is tapped from Write, then the editor stays open and the failure snackbar is shown',
    (tester) async {
      final entries = FakeJournalEntryRepository()
        ..saveError = Exception('offline');
      await _pumpJournalScreen(
        tester,
        size: const Size(400, 800),
        repository: entries,
      );
      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();
      await _enterEntry(tester, subject: 'Note', text: 'hello', mood: 5);

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsOneWidget);
      expect(find.byKey(_writeKey), findsNothing);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final scheme = AppTheme.light.colorScheme;
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, scheme.errorContainer);
      expect(
        tester.widget<Text>(find.text(_saveFailed)).style?.color,
        scheme.error,
      );
      expect(entries.saves, hasLength(1));
      expect(entries.updateCalls, 0);
    },
  );
}
