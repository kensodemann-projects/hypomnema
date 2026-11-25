import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/ui/journal_entry_detail.dart';
import 'package:hypomnema/features/journal/ui/journal_screen.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_journal_entry_repository.dart';
import '../../../helpers/viewport.dart';

const _saveFailed = 'The entry could not be saved.';
const _loadFailed = 'The entries could not be loaded.';
const _emptyTitle = 'Start your journal';
const _emptyAction = 'Write your first entry';
const _emptyMessage =
    "Write about anything: how today went, something on your mind, or one good thing. If you're not sure where to start, I'm Stuck gives you a prompt.";
const _writeKey = Key('journal-write');
const _editorKey = Key('journal-editor');
const _saveKey = Key('journal-save');
const _closeKey = Key('journal-close');
const _cancelKey = Key('journal-cancel');
const _subjectKey = Key('journal-subject');
const _textKey = Key('journal-text');
const _phone = Size(400, 800);
const _desktop = Size(1200, 800);

Future<FakeJournalEntryRepository> _pumpJournalScreen(
  WidgetTester tester, {
  required Size size,
  FakeJournalEntryRepository? repository,
  ThemeData? theme,
  DateTime Function()? clock,
  bool settle = true,
}) async {
  final entries = repository ?? FakeJournalEntryRepository();
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: clock == null
          ? JournalScreen(repository: entries)
          : JournalScreen(repository: entries, clock: clock),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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

JournalEntry _entry({
  required String id,
  required String subject,
  required int mood,
  required String text,
  required String localDateTime,
  bool private = false,
}) {
  return JournalEntry.restore(
    id: id,
    subject: subject,
    mood: mood,
    text: text,
    private: private,
    localDateTime: localDateTime,
    createdAt: DateTime.parse(localDateTime),
  );
}

FakeJournalEntryRepository _seededJournal() {
  return FakeJournalEntryRepository(
    entries: [
      _entry(
        id: 'today',
        subject: 'Early run',
        mood: 4,
        text: 'Moved early.',
        localDateTime: '2026-11-14T08:02:00',
      ),
      _entry(
        id: 'private',
        subject: 'Quiet thought',
        mood: 2,
        text: 'Line one\nstill one.\n\nLine two.',
        localDateTime: '2026-11-12T22:15:00',
        private: true,
      ),
      _entry(
        id: 'last-week',
        subject: 'Long call',
        mood: 4,
        text: 'Talked for an hour.',
        localDateTime: '2026-11-06T21:50:00',
      ),
    ],
  );
}

void main() {
  testWidgets(
    'Given an empty phone journal, when Write your first entry is tapped, then the full-screen editor opens and Close returns to the empty journal',
    (tester) async {
      await _pumpJournalScreen(tester, size: _phone);

      expect(find.byKey(const Key('journal-title')), findsOneWidget);
      expect(find.text(_emptyTitle), findsOneWidget);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text(_emptyAction), findsOneWidget);
      expect(find.byKey(_writeKey), findsNothing);
      expect(find.byType(AppBar), findsNothing);

      await tester.tap(find.text(_emptyAction));
      await tester.pumpAndSettle();

      expect(find.text('New entry'), findsOneWidget);
      expect(find.byKey(_closeKey), findsOneWidget);
      expect(find.byKey(_saveKey), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.byKey(_writeKey), findsNothing);
      expect(tester.getSize(find.byKey(_editorKey)), _phone);

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(find.text(_emptyTitle), findsOneWidget);
      expect(find.byKey(_writeKey), findsNothing);
    },
  );

  testWidgets(
    'Given the journal screen above 600px, when Write is tapped, then the dialog opens and Cancel returns to Write',
    (tester) async {
      await _pumpJournalScreen(tester, size: _desktop);

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
      await _pumpJournalScreen(tester, size: _desktop);
      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given a subject, mood, and text, when Save is tapped from the empty journal, then the trimmed public entry replaces the empty state and Write is shown',
    (tester) async {
      final entries = await _pumpJournalScreen(tester, size: _phone);
      await tester.tap(find.text(_emptyAction));
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
      expect(find.text(_emptyTitle), findsNothing);
      expect(find.text('Note'), findsOneWidget);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given a save that fails, when Save is tapped from the empty journal, then the editor stays open and the failure snackbar is shown',
    (tester) async {
      final entries = FakeJournalEntryRepository()
        ..saveError = Exception('offline');
      await _pumpJournalScreen(tester, size: _phone, repository: entries);
      await tester.tap(find.text(_emptyAction));
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

  testWidgets(
    'Given entries across this week and last week, when the phone journal is shown, then headings and rows are newest first',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: _seededJournal(),
        clock: () => DateTime(2026, 11, 14, 12),
      );

      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('LAST WEEK'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('THIS WEEK')).dy,
        lessThan(tester.getTopLeft(find.text('Early run')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Early run')).dy,
        lessThan(tester.getTopLeft(find.text('Quiet thought')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Quiet thought')).dy,
        lessThan(tester.getTopLeft(find.text('LAST WEEK')).dy),
      );
      expect(find.text('Today · 8:02 AM'), findsOneWidget);
      expect(find.text('Thu, Nov 12 · 10:15 PM'), findsOneWidget);
      expect(find.text('Fri, Nov 6 · 9:50 PM'), findsOneWidget);
      expect(find.text('Quiet thought'), findsOneWidget);
      expect(find.byKey(_writeKey), findsOneWidget);

      final heading = tester.widget<Text>(find.text('THIS WEEK'));
      expect(heading.style?.fontSize, 12);
      expect(heading.style?.fontWeight, FontWeight.w600);
      expect(heading.style?.letterSpacing, 0.72);
      final subject = tester.widget<Text>(find.text('Early run'));
      expect(subject.style?.fontWeight, FontWeight.w500);
      expect(subject.maxLines, 1);
      expect(subject.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets(
    'Given a private entry, when its row is tapped, then the phone entry shows its subject and text and Back returns to the list',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: _seededJournal(),
        clock: () => DateTime(2026, 11, 14, 12),
      );

      await tester.tap(find.byKey(const Key('journal-entry-today')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-entry-screen')), findsOneWidget);
      expect(find.text('Sat, Nov 14'), findsOneWidget);
      expect(find.text('Saturday, November 14 · 8:02 AM'), findsOneWidget);
      expect(find.text('Early run'), findsOneWidget);
      expect(find.text('Moved early.'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      final todaySwatch = tester.widget<MoodSwatch>(
        find.descendant(
          of: find.byKey(const Key('journal-entry-screen')),
          matching: find.byType(MoodSwatch),
        ),
      );
      expect(todaySwatch.mood, 4);
      expect(todaySwatch.size, MoodSwatchSize.large);
      expect(
        tester.getSize(find.byKey(const Key('journal-back'))),
        const Size(48, 48),
      );

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-entry-screen')), findsNothing);
      expect(find.byKey(const Key('journal-list')), findsOneWidget);

      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      expect(find.text('Quiet thought'), findsOneWidget);
      expect(find.text('Line one\nstill one.'), findsOneWidget);
      expect(find.text('Line two.'), findsOneWidget);
      expect(find.text('Thursday, November 12 · 10:15 PM'), findsOneWidget);
      final detail = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(JournalEntryDetail),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(detail.spacing, 14);
    },
  );

  testWidgets(
    'Given the first watch event is held, when the phone journal is shown, then loading hides the empty journal',
    (tester) async {
      final hold = Completer<void>();
      final repository = FakeJournalEntryRepository()..holdWatch = hold;
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: repository,
        settle: false,
      );

      expect(find.byKey(const Key('journal-loading')), findsOneWidget);
      expect(find.text(_emptyTitle), findsNothing);
      expect(find.byKey(const Key('journal-list')), findsNothing);

      hold.complete();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-loading')), findsNothing);
      expect(find.text(_emptyTitle), findsOneWidget);
    },
  );

  testWidgets(
    'Given watch fails, when the phone journal is shown, then the load snackbar is shown and the list and empty journal stay hidden',
    (tester) async {
      final repository = FakeJournalEntryRepository()
        ..watchError = Exception('offline');
      await _pumpJournalScreen(tester, size: _phone, repository: repository);

      expect(find.text(_loadFailed), findsOneWidget);
      expect(find.byKey(const Key('journal-list')), findsNothing);
      expect(find.text(_emptyTitle), findsNothing);
      expect(find.byKey(_writeKey), findsNothing);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final scheme = AppTheme.light.colorScheme;
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, scheme.errorContainer);
      expect(
        tester.widget<Text>(find.text(_loadFailed)).style?.color,
        scheme.error,
      );
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} phone journal with entries, when it is shown, then the row, heading, and Write use the scheme colors',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _phone,
          theme: theme,
          repository: FakeJournalEntryRepository(
            entries: [
              _entry(
                id: 'today',
                subject: 'Early run',
                mood: 4,
                text: 'Moved early.',
                localDateTime: '2026-11-14T08:02:00',
              ),
            ],
          ),
          clock: () => DateTime(2026, 11, 14, 12),
        );

        final scheme = theme.colorScheme;
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const Key('journal-entry-decoration-today')),
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.border, Border.all(color: scheme.outlineVariant));
        expect(
          tester.widget<Text>(find.text('THIS WEEK')).style?.color,
          scheme.onSurfaceVariant,
        );
        expect(
          tester.widget<Text>(find.text('Today · 8:02 AM')).style?.color,
          scheme.onSurfaceVariant,
        );
        final button = tester.widget<FloatingActionButton>(
          find.byKey(_writeKey),
        );
        expect(button.backgroundColor, scheme.primaryContainer);
        expect(button.foregroundColor, scheme.onPrimaryContainer);
      },
    );
  }
}
