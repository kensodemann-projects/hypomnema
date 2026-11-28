import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';
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
const _phone = Size(kDesktopLayoutMinWidth - 200, 800);
const _desktop = Size(kDesktopLayoutMinWidth + 400, 800);

void _expectRole(TextStyle? style, TextStyle? role) {
  expect(style?.fontSize, role?.fontSize);
  expect(style?.fontWeight, role?.fontWeight);
  expect(style?.height, role?.height);
  expect(style?.letterSpacing, role?.letterSpacing);
}

void _expectTextRole(WidgetTester tester, Finder finder, TextStyle? role) {
  _expectRole(tester.widget<Text>(finder).style, role);
}

const _phoneCoverBody =
    "Showing it is for this viewing only and won't change the private setting.";
const _desktopCoverBody =
    "The subject and text are hidden. Showing them is for this viewing only and won't change the private setting.";
const _revealSentence = ' · Showing private content for this viewing';

void _expectPrivateHeadline(WidgetTester tester, Finder scope, Color color) {
  final headline = find.descendant(
    of: scope,
    matching: find.text('Private entry'),
  );
  expect(headline, findsOneWidget);
  _expectTextRole(
    tester,
    headline,
    Theme.of(tester.element(headline)).textTheme.headlineSmall,
  );
  expect(tester.widget<Text>(headline).style?.color, color);
  final lock = tester.widget<Icon>(
    find.descendant(of: scope, matching: find.byIcon(Icons.lock)),
  );
  expect(lock.size, 24);
  expect(lock.color, color);
}

void _expectPrivateCover(
  WidgetTester tester, {
  required Finder scope,
  required bool desktop,
  required ColorScheme scheme,
}) {
  final cover = find.descendant(
    of: scope,
    matching: find.byKey(const Key('journal-private-cover')),
  );
  expect(cover, findsOneWidget);
  final decoration =
      tester.widget<DecoratedBox>(cover).decoration as BoxDecoration;
  expect(decoration.color, scheme.surface);
  final metrics = Theme.of(tester.element(cover)).extension<AppMetrics>()!;
  final painter =
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: cover,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is DashedRoundedBorderPainter,
                  ),
                ),
              )
              .painter!
          as DashedRoundedBorderPainter;
  expect(painter.color, scheme.outline);
  expect(painter.strokeWidth, metrics.borderWidth);
  expect(painter.radius, metrics.cardRadius);
  final title = find.descendant(
    of: cover,
    matching: find.text('This entry is private'),
  );
  final body = find.descendant(
    of: cover,
    matching: find.text(desktop ? _desktopCoverBody : _phoneCoverBody),
  );
  final textTheme = Theme.of(tester.element(title)).textTheme;
  _expectTextRole(tester, title, textTheme.titleMedium);
  expect(tester.widget<Text>(title).style?.color, scheme.onSurface);
  _expectTextRole(tester, body, textTheme.bodyMedium);
  expect(tester.widget<Text>(body).style?.color, scheme.onSurfaceVariant);
  final icon = tester.widget<Icon>(
    find.descendant(of: cover, matching: find.byIcon(Icons.visibility_off)),
  );
  expect(icon.size, 44);
  expect(icon.color, scheme.onSurfaceVariant.withValues(alpha: 0.6));
  expect(
    find.descendant(
      of: cover,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding ==
                (desktop
                    ? const EdgeInsets.symmetric(horizontal: 32, vertical: 48)
                    : const EdgeInsets.symmetric(horizontal: 20, vertical: 36)),
      ),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: cover,
      matching: find.byKey(const Key('journal-show-content')),
    ),
    findsOneWidget,
  );
  expect(find.byKey(const Key('journal-detail-card')), findsNothing);
}

void _expectPrivateBanner(
  WidgetTester tester, {
  required Finder scope,
  required bool desktop,
  required String subject,
  required ColorScheme scheme,
}) {
  final banner = find.descendant(
    of: scope,
    matching: find.byKey(const Key('journal-private-banner')),
  );
  expect(banner, findsOneWidget);
  final decoration =
      tester.widget<DecoratedBox>(banner).decoration as BoxDecoration;
  expect(decoration.color, scheme.surfaceContainerHigh);
  expect(
    decoration.borderRadius,
    BorderRadius.circular(
      Theme.of(tester.element(banner)).extension<AppMetrics>()!.rowRadius,
    ),
  );
  final subjectText = find.descendant(of: banner, matching: find.text(subject));
  final textTheme = Theme.of(tester.element(subjectText)).textTheme;
  _expectTextRole(tester, subjectText, textTheme.titleSmall);
  expect(
    tester.widget<Text>(subjectText).style?.color,
    scheme.onSurfaceVariant,
  );
  final sentence = find.descendant(
    of: banner,
    matching: find.text(_revealSentence),
  );
  if (desktop) {
    _expectTextRole(tester, sentence, textTheme.bodyMedium);
    expect(tester.widget<Text>(sentence).style?.color, scheme.onSurfaceVariant);
  } else {
    expect(sentence, findsNothing);
  }
  final icon = tester.widget<Icon>(
    find.descendant(of: banner, matching: find.byIcon(Icons.visibility)),
  );
  expect(icon.size, 20);
  expect(icon.color, scheme.onSurfaceVariant);
  expect(
    find.descendant(
      of: banner,
      matching: find.byKey(const Key('journal-hide')),
    ),
    findsOneWidget,
  );
  expect(find.byKey(const Key('journal-private-cover')), findsNothing);
}

void _expectPrivateListRow(
  WidgetTester tester, {
  required Key rowKey,
  required Color labelColor,
}) {
  final row = find.byKey(rowKey);
  expect(
    find.descendant(of: row, matching: find.text('Quiet thought')),
    findsNothing,
  );
  final label = find.descendant(of: row, matching: find.text('Private entry'));
  expect(label, findsOneWidget);
  final textTheme = Theme.of(tester.element(label)).textTheme;
  _expectTextRole(tester, label, textTheme.titleMedium);
  final title = tester.widget<Text>(label);
  expect(title.maxLines, 1);
  expect(title.overflow, TextOverflow.ellipsis);
  expect(title.style?.color, labelColor);
  final lock = tester.widget<Icon>(
    find.descendant(of: row, matching: find.byIcon(Icons.lock)),
  );
  expect(lock.size, 16);
  expect(lock.color, labelColor);
  expect(
    tester
        .widget<MoodSwatch>(
          find.descendant(of: row, matching: find.byType(MoodSwatch)),
        )
        .mood,
    2,
  );
}

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
  DateTime? createdAt,
}) {
  return JournalEntry.restore(
    id: id,
    subject: subject,
    mood: mood,
    text: text,
    private: private,
    localDateTime: localDateTime,
    createdAt: createdAt ?? DateTime.parse(localDateTime),
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

      final title = find.byKey(const Key('journal-title'));
      expect(title, findsOneWidget);
      _expectTextRole(
        tester,
        title,
        Theme.of(tester.element(title)).textTheme.titleLarge,
      );
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
    'Given the journal screen above the desktop layout minimum, when Write is tapped, then the dialog opens and Cancel returns to Write',
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
        lessThan(tester.getTopLeft(find.text('Private entry')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Private entry')).dy,
        lessThan(tester.getTopLeft(find.text('LAST WEEK')).dy),
      );
      expect(find.text('Today · 8:02 AM'), findsOneWidget);
      expect(find.text('Thu, Nov 12 · 10:15 PM'), findsOneWidget);
      expect(find.text('Fri, Nov 6 · 9:50 PM'), findsOneWidget);
      expect(find.text('Quiet thought'), findsNothing);
      expect(find.text('Private entry'), findsOneWidget);
      expect(find.byKey(_writeKey), findsOneWidget);

      final heading = find.text('THIS WEEK');
      final subjectFinder = find.text('Early run');
      final when = find.text('Today · 8:02 AM');
      final textTheme = Theme.of(tester.element(heading)).textTheme;
      _expectTextRole(tester, heading, textTheme.labelSmall);
      _expectTextRole(tester, subjectFinder, textTheme.titleMedium);
      _expectTextRole(tester, when, textTheme.bodySmall);
      final subject = tester.widget<Text>(subjectFinder);
      expect(subject.maxLines, 1);
      expect(subject.overflow, TextOverflow.ellipsis);
      _expectPrivateListRow(
        tester,
        rowKey: const Key('journal-entry-private'),
        labelColor: AppTheme.light.colorScheme.onSurfaceVariant,
      );
    },
  );

  testWidgets(
    'Given a phone journal entry, when its row is tapped, then the first frame already shows the subject',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: _seededJournal(),
        clock: () => DateTime(2026, 11, 14, 12),
      );

      await tester.tap(find.byKey(const Key('journal-entry-today')));
      await tester.pump();

      final screen = find.byKey(
        const Key('journal-entry-screen'),
        skipOffstage: false,
      );
      expect(
        find.descendant(
          of: screen,
          matching: find.text('Early run', skipOffstage: false),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Given a private entry, when its row is tapped, then Show Content reveals it for that viewing and Back returns to the list',
    (tester) async {
      final repository = await _pumpJournalScreen(
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
      final entry = find.byKey(const Key('journal-entry-screen'));
      final entryTheme = Theme.of(tester.element(entry)).textTheme;
      final barTitle = find.text('Sat, Nov 14');
      final when = find.text('Saturday, November 14 · 8:02 AM');
      final subject = find.text('Early run');
      final paragraph = find.text('Moved early.');
      _expectTextRole(tester, barTitle, entryTheme.titleLarge);
      _expectTextRole(tester, when, entryTheme.labelMedium);
      expect(
        tester.widget<Text>(when).style?.color,
        AppTheme.light.colorScheme.onSurfaceVariant,
      );
      _expectTextRole(tester, subject, entryTheme.headlineSmall);
      _expectTextRole(tester, paragraph, entryTheme.bodyLarge);
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

      final screen = find.byKey(const Key('journal-entry-screen'));
      final scheme = AppTheme.light.colorScheme;
      _expectPrivateCover(
        tester,
        scope: screen,
        desktop: false,
        scheme: scheme,
      );
      _expectPrivateHeadline(tester, screen, scheme.onSurfaceVariant);
      expect(find.text('Quiet thought'), findsNothing);
      expect(find.text('Line one\nstill one.'), findsNothing);
      expect(find.text('Line two.'), findsNothing);
      expect(find.text('Thursday, November 12 · 10:15 PM'), findsOneWidget);
      final swatch = tester.widget<MoodSwatch>(
        find.descendant(of: screen, matching: find.byType(MoodSwatch)),
      );
      expect(swatch.mood, 2);
      expect(swatch.size, MoodSwatchSize.large);
      final detail = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(JournalEntryDetail),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(detail.spacing, 14);

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();

      _expectPrivateBanner(
        tester,
        scope: screen,
        desktop: false,
        subject: 'Quiet thought',
        scheme: scheme,
      );
      expect(find.text('Line one\nstill one.'), findsOneWidget);
      expect(find.text('Line two.'), findsOneWidget);
      expect(repository.updates, isEmpty);
      expect(repository.saves, isEmpty);

      await tester.tap(find.byKey(const Key('journal-hide')));
      await tester.pumpAndSettle();

      _expectPrivateCover(
        tester,
        scope: screen,
        desktop: false,
        scheme: scheme,
      );
      expect(find.text('Quiet thought'), findsNothing);
      expect(find.text('Line one\nstill one.'), findsNothing);
      expect(repository.updates, isEmpty);

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      _expectPrivateCover(
        tester,
        scope: find.byKey(const Key('journal-entry-screen')),
        desktop: false,
        scheme: scheme,
      );
      expect(find.text('Quiet thought'), findsNothing);
      expect(repository.updates, isEmpty);
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
      final message = find.text(_loadFailed);
      final theme = Theme.of(tester.element(find.byType(SnackBar)));
      final scheme = theme.colorScheme;
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, isNull);
      expect(tester.widget<Text>(message).style, isNull);
      expect(theme.snackBarTheme.backgroundColor, scheme.errorContainer);
      final effective = DefaultTextStyle.of(tester.element(message)).style;
      expect(effective.color, scheme.onErrorContainer);
      _expectRole(effective, theme.textTheme.bodyMedium);
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
              _entry(
                id: 'private',
                subject: 'Quiet thought',
                mood: 2,
                text: 'Hidden line.',
                localDateTime: '2026-11-12T22:15:00',
                private: true,
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
        _expectPrivateListRow(
          tester,
          rowKey: const Key('journal-entry-private'),
          labelColor: scheme.onSurfaceVariant,
        );
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
        final fabTheme = Theme.of(tester.element(find.byKey(_writeKey)))
            .floatingActionButtonTheme;
        expect(button.backgroundColor, isNull);
        expect(button.foregroundColor, isNull);
        expect(fabTheme.backgroundColor, scheme.primaryContainer);
        expect(fabTheme.foregroundColor, scheme.onPrimaryContainer);
      },
    );
  }

  Finder inPane(Key pane, String text) {
    return find.descendant(of: find.byKey(pane), matching: find.text(text));
  }

  testWidgets(
    'Given an empty desktop journal, when either Write action is tapped, then the editor dialog opens and dismissing it returns to the header',
    (tester) async {
      await _pumpJournalScreen(tester, size: _desktop);

      final headerTitle = find.descendant(
        of: find.byKey(const Key('journal-header')),
        matching: find.byKey(const Key('journal-title')),
      );
      final emptyList = find.text('No entries yet.');
      expect(find.byKey(const Key('journal-header')), findsOneWidget);
      expect(emptyList, findsOneWidget);
      _expectTextRole(
        tester,
        headerTitle,
        Theme.of(tester.element(headerTitle)).textTheme.titleLarge,
      );
      _expectTextRole(
        tester,
        emptyList,
        Theme.of(tester.element(emptyList)).textTheme.bodyMedium,
      );
      expect(
        tester.widget<Text>(emptyList).style?.color,
        AppTheme.light.colorScheme.onSurfaceVariant,
      );
      expect(find.text(_emptyTitle), findsOneWidget);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text(_emptyAction), findsOneWidget);
      expect(find.byKey(_writeKey), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('journal-list-pane'))).width,
        380,
      );
      expect(
        tester.getSize(find.byKey(const Key('journal-header'))).height,
        greaterThanOrEqualTo(72),
      );

      await tester.tap(find.text(_emptyAction));
      await tester.pumpAndSettle();
      expect(find.text('New journal entry'), findsOneWidget);
      await tester.tap(find.byKey(_cancelKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);

      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();
      expect(find.text('New journal entry'), findsOneWidget);
      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_editorKey), findsNothing);
      expect(find.byKey(_writeKey), findsOneWidget);
    },
  );

  testWidgets(
    'Given desktop entries, when an older row is selected and a newer entry is saved, then the older detail stays and the new subject leads the list',
    (tester) async {
      final repository = await _pumpJournalScreen(
        tester,
        size: _desktop,
        repository: _seededJournal(),
        clock: () => DateTime(2026, 11, 14, 12),
      );

      expect(
        inPane(
          const Key('journal-detail-pane'),
          'Saturday, November 14, 2026 · 8:02 AM',
        ),
        findsOneWidget,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Early run'),
        findsOneWidget,
      );
      final subject = inPane(const Key('journal-detail-pane'), 'Early run');
      final heading = inPane(const Key('journal-list-pane'), 'THIS WEEK');
      final textTheme = Theme.of(tester.element(subject)).textTheme;
      _expectTextRole(tester, subject, textTheme.headlineSmall);
      _expectTextRole(tester, heading, textTheme.labelSmall);
      final swatch = tester.widget<MoodSwatch>(
        find.descendant(
          of: find.byKey(const Key('journal-detail-pane')),
          matching: find.byType(MoodSwatch),
        ),
      );
      expect(swatch.size, MoodSwatchSize.large);
      expect(find.text('Moved early.'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('journal-detail-card'))).width,
        tester.getSize(find.byKey(const Key('journal-detail-pane'))).width - 64,
      );
      expect(
        inPane(const Key('journal-list-pane'), 'Quiet thought'),
        findsNothing,
      );
      _expectPrivateListRow(
        tester,
        rowKey: const Key('journal-entry-private'),
        labelColor: AppTheme.light.colorScheme.onSurfaceVariant,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('journal-entry-private')),
          matching: find.text('Thu, Nov 12 · 10:15 PM'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      final detailPane = find.byKey(const Key('journal-detail-pane'));
      final scheme = AppTheme.light.colorScheme;
      _expectPrivateCover(
        tester,
        scope: detailPane,
        desktop: true,
        scheme: scheme,
      );
      _expectPrivateHeadline(tester, detailPane, scheme.onSurfaceVariant);
      expect(
        inPane(const Key('journal-detail-pane'), 'Quiet thought'),
        findsNothing,
      );
      expect(find.text('Line one\nstill one.'), findsNothing);
      expect(find.text('Line two.'), findsNothing);
      expect(
        inPane(
          const Key('journal-detail-pane'),
          'Thursday, November 12, 2026 · 10:15 PM',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<MoodSwatch>(
              find.descendant(
                of: detailPane,
                matching: find.byType(MoodSwatch),
              ),
            )
            .mood,
        2,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Early run'),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();

      _expectPrivateBanner(
        tester,
        scope: detailPane,
        desktop: true,
        subject: 'Quiet thought',
        scheme: scheme,
      );
      expect(find.text('Line one\nstill one.'), findsOneWidget);
      expect(find.text('Line two.'), findsOneWidget);
      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(repository.updates, isEmpty);
      expect(repository.saves, isEmpty);

      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      _expectPrivateCover(
        tester,
        scope: detailPane,
        desktop: true,
        scheme: scheme,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Quiet thought'),
        findsNothing,
      );
      expect(repository.updates, isEmpty);

      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_writeKey));
      await tester.pumpAndSettle();
      await _enterEntry(tester, subject: 'Later note', text: 'hello', mood: 3);
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repository.saves, [
        (subject: 'Later note', mood: 3, text: 'hello', private: false),
      ]);
      expect(
        inPane(const Key('journal-detail-pane'), 'Long call'),
        findsOneWidget,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Later note'),
        findsNothing,
      );
      expect(
        tester
            .getTopLeft(inPane(const Key('journal-list-pane'), 'Later note'))
            .dy,
        lessThan(
          tester
              .getTopLeft(inPane(const Key('journal-list-pane'), 'Early run'))
              .dy,
        ),
      );
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} desktop journal with entries, when the newest row is selected, then the row and detail card use the scheme colors',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _desktop,
          theme: theme,
          repository: FakeJournalEntryRepository(
            entries: [
              _entry(
                id: 'private',
                subject: 'Quiet thought',
                mood: 2,
                text: 'Hidden line.',
                localDateTime: '2026-11-14T10:15:00',
                private: true,
              ),
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
                      find.byKey(const Key('journal-entry-decoration-private')),
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, scheme.primaryContainer);
        expect(decoration.border, Border.all(color: scheme.primary, width: 2));
        _expectPrivateListRow(
          tester,
          rowKey: const Key('journal-entry-private'),
          labelColor: scheme.onSurfaceVariant,
        );
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(const Key('journal-entry-private')),
                  matching: find.text('Today · 10:15 AM'),
                ),
              )
              .style
              ?.color,
          scheme.onPrimaryContainer,
        );
        final publicSubject = find.descendant(
          of: find.byKey(const Key('journal-entry-today')),
          matching: find.text('Early run'),
        );
        expect(
          tester.widget<Text>(publicSubject).style?.color,
          Theme.of(tester.element(publicSubject)).textTheme.titleMedium?.color,
        );
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byKey(const Key('journal-entry-today')),
                  matching: find.text('Today · 8:02 AM'),
                ),
              )
              .style
              ?.color,
          scheme.onSurfaceVariant,
        );
        final detailPane = find.byKey(const Key('journal-detail-pane'));
        _expectPrivateCover(
          tester,
          scope: detailPane,
          desktop: true,
          scheme: scheme,
        );
        _expectPrivateHeadline(tester, detailPane, scheme.onSurfaceVariant);

        await tester.tap(find.byKey(const Key('journal-show-content')));
        await tester.pumpAndSettle();

        _expectPrivateBanner(
          tester,
          scope: detailPane,
          desktop: true,
          subject: 'Quiet thought',
          scheme: scheme,
        );
        final card =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const Key('journal-detail-card')),
                    )
                    .decoration
                as BoxDecoration;
        expect(card.color, scheme.surface);
        expect(card.border, Border.all(color: scheme.outlineVariant));
      },
    );
  }

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} private phone entry, when it opens and Show Content is tapped, then the cover and banner use the scheme colors',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _phone,
          theme: theme,
          repository: FakeJournalEntryRepository(
            entries: [
              _entry(
                id: 'private',
                subject: 'Quiet thought',
                mood: 2,
                text: 'Hidden line.',
                localDateTime: '2026-11-12T22:15:00',
                private: true,
              ),
            ],
          ),
          clock: () => DateTime(2026, 11, 14, 12),
        );
        await tester.tap(find.byKey(const Key('journal-entry-private')));
        await tester.pumpAndSettle();

        final screen = find.byKey(const Key('journal-entry-screen'));
        _expectPrivateCover(
          tester,
          scope: screen,
          desktop: false,
          scheme: theme.colorScheme,
        );
        _expectPrivateHeadline(
          tester,
          screen,
          theme.colorScheme.onSurfaceVariant,
        );

        await tester.tap(find.byKey(const Key('journal-show-content')));
        await tester.pumpAndSettle();

        _expectPrivateBanner(
          tester,
          scope: screen,
          desktop: false,
          subject: 'Quiet thought',
          scheme: theme.colorScheme,
        );
      },
    );
  }

  const openNote = 'Editable until 8:02 AM tomorrow';
  final noon = DateTime(2026, 11, 14, 12);

  void expectNoDelete() {
    expect(find.text('Delete'), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  }

  Finder inScreen(Key screen, Finder matching) {
    return find.descendant(of: find.byKey(screen), matching: matching);
  }

  testWidgets(
    'Given the November 14 entry viewed at noon, when the phone detail opens, then Edit and the note are shown, and a November 12 entry has neither',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: _seededJournal(),
        clock: () => noon,
      );

      await tester.tap(find.byKey(const Key('journal-entry-today')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsOneWidget);
      expect(find.byKey(const Key('journal-edit')), findsOneWidget);
      expectNoDelete();

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsNothing);
      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
      expectNoDelete();

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('journal-entry-screen')),
          matching: find.text('Quiet thought'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Given the wall clock and the creation timestamp disagree, when the phone detail opens, then Edit follows the creation timestamp',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _phone,
        clock: () => noon,
        repository: FakeJournalEntryRepository(
          entries: [
            _entry(
              id: 'old-wall',
              subject: 'Old wall',
              mood: 3,
              text: 'Still new.',
              localDateTime: '2026-11-01T08:00:00',
              createdAt: DateTime(2026, 11, 14, 8, 2),
            ),
            _entry(
              id: 'fresh-wall',
              subject: 'Fresh wall',
              mood: 3,
              text: 'Already old.',
              localDateTime: '2026-11-14T08:02:00',
              createdAt: DateTime(2026, 11, 1, 8),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('journal-entry-old-wall')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsOneWidget);
      expect(find.byKey(const Key('journal-edit')), findsOneWidget);

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-fresh-wall')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsNothing);
      expect(find.byKey(const Key('journal-edit')), findsNothing);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} phone detail inside the window, when it is shown, then the note and Edit use the scheme colors',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _phone,
          theme: theme,
          repository: _seededJournal(),
          clock: () => noon,
        );
        await tester.tap(find.byKey(const Key('journal-entry-today')));
        await tester.pumpAndSettle();

        final scheme = theme.colorScheme;
        final note = find.text(openNote);
        _expectTextRole(
          tester,
          note,
          Theme.of(tester.element(note)).textTheme.bodySmall,
        );
        expect(tester.widget<Text>(note).style?.color, scheme.onSurfaceVariant);
        final schedule = tester.widget<Icon>(
          inScreen(
            const Key('journal-editable-until'),
            find.byIcon(Icons.schedule),
          ),
        );
        expect(schedule.size, 16);
        expect(schedule.color, scheme.onSurfaceVariant);
        final edit = tester.widget<Icon>(
          inScreen(const Key('journal-edit'), find.byIcon(Icons.edit)),
        );
        expect(edit.color, scheme.onSurfaceVariant);
        expect(
          tester.getSize(find.byKey(const Key('journal-edit'))),
          const Size(48, 48),
        );
      },
    );
  }

  testWidgets(
    'Given a private phone entry inside the window, when Edit saves new fields, then the detail updates and the original time and private flag stay',
    (tester) async {
      const when = 'Saturday, November 14 · 8:02 AM';
      final repository = FakeJournalEntryRepository(
        entries: [
          _entry(
            id: 'private-open',
            subject: 'Quiet thought',
            mood: 2,
            text: 'Hidden line.',
            localDateTime: '2026-11-14T08:02:00',
            private: true,
          ),
        ],
      );
      await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: repository,
        clock: () => noon,
      );
      await tester.tap(find.byKey(const Key('journal-entry-private-open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(find.text(openNote), findsOneWidget);
      expect(find.text('Hidden line.'), findsNothing);

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();
      expect(repository.updates, isEmpty);
      await tester.tap(find.byKey(const Key('journal-edit')));
      await tester.pumpAndSettle();

      expect(find.text('New entry'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(_subjectKey)).controller?.text,
        'Quiet thought',
      );
      expect(
        tester.widget<TextField>(find.byKey(_textKey)).controller?.text,
        'Hidden line.',
      );
      expectNoDelete();

      await _enterEntry(
        tester,
        subject: 'Revised',
        text: 'Updated line.',
        mood: 5,
      );
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repository.saves, isEmpty);
      expect(repository.updates, [
        (subject: 'Revised', mood: 5, text: 'Updated line.', private: true),
      ]);
      expect(find.byKey(const Key('journal-entry-screen')), findsOneWidget);
      expect(
        inScreen(const Key('journal-entry-screen'), find.text('Private entry')),
        findsOneWidget,
      );
      expect(
        inScreen(const Key('journal-private-banner'), find.text('Revised')),
        findsOneWidget,
      );
      expect(find.text(when), findsOneWidget);
      expect(find.text('Updated line.'), findsOneWidget);
      final swatch = tester.widget<MoodSwatch>(
        inScreen(const Key('journal-entry-screen'), find.byType(MoodSwatch)),
      );
      expect(swatch.mood, 5);
    },
  );

  testWidgets(
    'Given the November 14 entry viewed at noon, when the desktop detail is shown, then Edit and the note are shown, and a November 6 entry has neither',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _desktop,
        repository: _seededJournal(),
        clock: () => noon,
      );

      expect(
        inPane(const Key('journal-detail-pane'), openNote),
        findsOneWidget,
      );
      expect(inPane(const Key('journal-detail-pane'), 'Edit'), findsOneWidget);
      expectNoDelete();

      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsNothing);
      expect(inPane(const Key('journal-detail-pane'), 'Edit'), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
      expectNoDelete();
    },
  );

  testWidgets(
    'Given the wall clock and the creation timestamp disagree, when the desktop detail is shown, then Edit follows the creation timestamp',
    (tester) async {
      await _pumpJournalScreen(
        tester,
        size: _desktop,
        clock: () => noon,
        repository: FakeJournalEntryRepository(
          entries: [
            _entry(
              id: 'old-wall',
              subject: 'Old wall',
              mood: 3,
              text: 'Still new.',
              localDateTime: '2026-11-01T08:00:00',
              createdAt: DateTime(2026, 11, 14, 8, 2),
            ),
            _entry(
              id: 'fresh-wall',
              subject: 'Fresh wall',
              mood: 3,
              text: 'Already old.',
              localDateTime: '2026-11-14T08:02:00',
              createdAt: DateTime(2026, 11, 1, 8),
            ),
          ],
        ),
      );

      expect(
        inPane(const Key('journal-detail-pane'), openNote),
        findsOneWidget,
      );
      expect(find.byKey(const Key('journal-edit')), findsOneWidget);

      await tester.tap(find.byKey(const Key('journal-entry-fresh-wall')));
      await tester.pumpAndSettle();

      expect(find.text(openNote), findsNothing);
      expect(find.byKey(const Key('journal-edit')), findsNothing);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} desktop detail inside the window, when it is shown, then the note and Edit use the scheme colors',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _desktop,
          theme: theme,
          repository: _seededJournal(),
          clock: () => noon,
        );

        final scheme = theme.colorScheme;
        final note = inPane(const Key('journal-detail-pane'), openNote);
        _expectTextRole(
          tester,
          note,
          Theme.of(tester.element(note)).textTheme.bodySmall,
        );
        expect(tester.widget<Text>(note).style?.color, scheme.onSurfaceVariant);
        final schedule = tester.widget<Icon>(
          inScreen(
            const Key('journal-editable-until'),
            find.byIcon(Icons.schedule),
          ),
        );
        expect(schedule.size, 16);
        expect(schedule.color, scheme.onSurfaceVariant);
        final button = tester.widget<OutlinedButton>(
          find.byKey(const Key('journal-edit')),
        );
        expect(button.style?.foregroundColor?.resolve({}), scheme.primary);
        expect(button.style?.side?.resolve({})?.color, scheme.outline);
      },
    );
  }

  testWidgets(
    'Given a private desktop entry inside the window, when Edit saves new fields, then the detail updates and the original time and private flag stay',
    (tester) async {
      const when = 'Saturday, November 14, 2026 · 8:02 AM';
      final repository = FakeJournalEntryRepository(
        entries: [
          _entry(
            id: 'private-open',
            subject: 'Quiet thought',
            mood: 2,
            text: 'Hidden line.',
            localDateTime: '2026-11-14T08:02:00',
            private: true,
          ),
        ],
      );
      await _pumpJournalScreen(
        tester,
        size: _desktop,
        repository: repository,
        clock: () => noon,
      );

      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(
        inPane(const Key('journal-detail-pane'), openNote),
        findsOneWidget,
      );
      expect(find.text('Hidden line.'), findsNothing);

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();
      expect(repository.updates, isEmpty);
      await tester.tap(find.byKey(const Key('journal-edit')));
      await tester.pumpAndSettle();

      expect(find.text('New journal entry'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(_subjectKey)).controller?.text,
        'Quiet thought',
      );
      expect(
        tester.widget<TextField>(find.byKey(_textKey)).controller?.text,
        'Hidden line.',
      );
      expectNoDelete();

      await _enterEntry(
        tester,
        subject: 'Revised',
        text: 'Updated line.',
        mood: 5,
      );
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repository.saves, isEmpty);
      expect(repository.updates, [
        (subject: 'Revised', mood: 5, text: 'Updated line.', private: true),
      ]);
      expect(find.byKey(_editorKey), findsNothing);
      expect(
        inPane(const Key('journal-detail-pane'), 'Private entry'),
        findsOneWidget,
      );
      expect(
        inPane(const Key('journal-private-banner'), 'Revised'),
        findsOneWidget,
      );
      expect(inPane(const Key('journal-detail-pane'), when), findsOneWidget);
      expect(find.text('Updated line.'), findsOneWidget);
      final swatch = tester.widget<MoodSwatch>(
        inScreen(const Key('journal-detail-pane'), find.byType(MoodSwatch)),
      );
      expect(swatch.mood, 5);
    },
  );

  const phoneToday = 'Saturday, November 14 · 8:02 AM';
  const desktopToday = 'Saturday, November 14, 2026 · 8:02 AM';
  const phonePrivateWhen = 'Thursday, November 12 · 10:15 PM';
  const desktopPrivateWhen = 'Thursday, November 12, 2026 · 10:15 PM';
  const phonePastWhen = 'Friday, November 6 · 9:50 PM';
  const desktopPastWhen = 'Friday, November 6, 2026 · 9:50 PM';

  testWidgets(
    'Given a phone entry inside or past the window, when privacy is toggled, then the flag flips and the writing hides or shows',
    (tester) async {
      final repository = await _pumpJournalScreen(
        tester,
        size: _phone,
        repository: _seededJournal(),
        clock: () => noon,
      );

      await tester.tap(find.byKey(const Key('journal-entry-today')));
      await tester.pumpAndSettle();
      expect(find.text('Make Private'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsWidgets);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates, [
        (subject: 'Early run', mood: 4, text: 'Moved early.', private: true),
      ]);
      expect(find.text(phoneToday), findsOneWidget);
      _expectPrivateCover(
        tester,
        scope: find.byKey(const Key('journal-entry-screen')),
        desktop: false,
        scheme: AppTheme.light.colorScheme,
      );
      expect(find.text('Early run'), findsNothing);
      expect(find.text('Moved early.'), findsNothing);

      expect(find.text('Make Public'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();
      expect(find.text('Make Public'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-hide')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates, [
        (subject: 'Early run', mood: 4, text: 'Moved early.', private: true),
        (subject: 'Early run', mood: 4, text: 'Moved early.', private: false),
      ]);
      expect(find.text('Early run'), findsOneWidget);
      expect(find.text('Moved early.'), findsOneWidget);
      expect(find.text(phoneToday), findsOneWidget);
      expect(find.byKey(const Key('journal-private-cover')), findsNothing);

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();

      expect(find.text('Make Public'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text('Quiet thought'), findsNothing);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates.last.private, isFalse);
      expect(repository.updates.last.subject, 'Quiet thought');
      expect(repository.updates.last.text, 'Line one\nstill one.\n\nLine two.');
      expect(repository.updates.last.mood, 2);
      expect(find.text('Quiet thought'), findsOneWidget);
      expect(find.text('Line one\nstill one.'), findsOneWidget);
      expect(find.text('Line two.'), findsOneWidget);
      expect(find.text(phonePrivateWhen), findsOneWidget);
      expect(find.byKey(const Key('journal-private-cover')), findsNothing);

      await tester.tap(find.byKey(const Key('journal-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(find.text('Make Private'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates.last.private, isTrue);
      expect(repository.updates.last.subject, 'Long call');
      expect(find.text(phonePastWhen), findsOneWidget);
      expect(find.text('Long call'), findsNothing);
      expect(find.byKey(const Key('journal-private-cover')), findsOneWidget);
    },
  );

  testWidgets(
    'Given a desktop entry inside or past the window, when privacy is toggled, then the flag flips and the writing hides or shows',
    (tester) async {
      final repository = await _pumpJournalScreen(
        tester,
        size: _desktop,
        repository: _seededJournal(),
        clock: () => noon,
      );
      final detail = find.byKey(const Key('journal-detail-pane'));

      expect(find.text('Make Private'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates, [
        (subject: 'Early run', mood: 4, text: 'Moved early.', private: true),
      ]);
      expect(
        inPane(const Key('journal-detail-pane'), desktopToday),
        findsOneWidget,
      );
      _expectPrivateCover(
        tester,
        scope: detail,
        desktop: true,
        scheme: AppTheme.light.colorScheme,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Early run'),
        findsNothing,
      );

      expect(find.text('Make Public'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates.last.private, isFalse);
      expect(
        inPane(const Key('journal-detail-pane'), 'Early run'),
        findsOneWidget,
      );
      expect(find.text('Moved early.'), findsOneWidget);
      expect(
        inPane(const Key('journal-detail-pane'), desktopToday),
        findsOneWidget,
      );
      expect(find.byKey(const Key('journal-private-cover')), findsNothing);

      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();
      expect(find.text('Make Public'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();
      expect(find.text('Make Public'), findsOneWidget);

      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-entry-private')));
      await tester.pumpAndSettle();
      expect(find.text('Quiet thought'), findsNothing);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates.last.private, isFalse);
      expect(repository.updates.last.subject, 'Quiet thought');
      expect(
        inPane(const Key('journal-detail-pane'), 'Quiet thought'),
        findsOneWidget,
      );
      expect(find.text('Line one\nstill one.'), findsOneWidget);
      expect(find.text('Line two.'), findsOneWidget);
      expect(
        inPane(const Key('journal-detail-pane'), desktopPrivateWhen),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('journal-entry-last-week')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('journal-edit')), findsNothing);
      expect(find.text('Make Private'), findsOneWidget);
      await tester.tap(find.byKey(const Key('journal-privacy')));
      await tester.pumpAndSettle();

      expect(repository.updates.last.private, isTrue);
      expect(repository.updates.last.subject, 'Long call');
      expect(
        inPane(const Key('journal-detail-pane'), desktopPastWhen),
        findsOneWidget,
      );
      expect(
        inPane(const Key('journal-detail-pane'), 'Long call'),
        findsNothing,
      );
      expect(find.byKey(const Key('journal-private-cover')), findsOneWidget);
    },
  );

  for (final desktop in [false, true]) {
    testWidgets(
      'Given a ${desktop ? 'desktop' : 'phone'} entry, when the privacy update fails, then the snackbar shows and the writing stays',
      (tester) async {
        final repository = FakeJournalEntryRepository(
          entries: [
            _entry(
              id: 'today',
              subject: 'Early run',
              mood: 4,
              text: 'Moved early.',
              localDateTime: '2026-11-14T08:02:00',
            ),
          ],
        )..updateError = Exception('offline');
        await _pumpJournalScreen(
          tester,
          size: desktop ? _desktop : _phone,
          repository: repository,
          clock: () => noon,
        );
        if (!desktop) {
          await tester.tap(find.byKey(const Key('journal-entry-today')));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.byKey(const Key('journal-privacy')));
        await tester.pumpAndSettle();

        expect(repository.updates, [
          (subject: 'Early run', mood: 4, text: 'Moved early.', private: true),
        ]);
        expect(find.text('The entry could not be updated.'), findsOneWidget);
        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
          SnackBarBehavior.floating,
        );
        final writing = desktop
            ? find.byKey(const Key('journal-detail-pane'))
            : find.byKey(const Key('journal-entry-screen'));
        expect(
          find.descendant(of: writing, matching: find.text('Early run')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: writing, matching: find.text('Moved early.')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('journal-private-cover')), findsNothing);
        expect(find.text('Make Private'), findsOneWidget);
      },
    );
  }

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Given a ${theme.brightness.name} journal, when an entry is open, then the privacy button uses primary',
      (tester) async {
        final repository = FakeJournalEntryRepository(
          entries: [
            _entry(
              id: 'today',
              subject: 'Early run',
              mood: 4,
              text: 'Moved early.',
              localDateTime: '2026-11-14T08:02:00',
            ),
          ],
        );
        final scheme = theme.colorScheme;
        await _pumpJournalScreen(
          tester,
          size: _phone,
          theme: theme,
          repository: repository,
          clock: () => noon,
        );
        await tester.tap(find.byKey(const Key('journal-entry-today')));
        await tester.pumpAndSettle();

        final outlined = tester.widget<OutlinedButton>(
          find.byKey(const Key('journal-privacy')),
        );
        expect(outlined.style?.foregroundColor?.resolve({}), scheme.primary);
        expect(outlined.style?.side?.resolve({})?.color, scheme.outline);
      },
    );

    testWidgets(
      'Given a ${theme.brightness.name} desktop entry, when it is shown, then Make Private uses primary',
      (tester) async {
        await _pumpJournalScreen(
          tester,
          size: _desktop,
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
          clock: () => noon,
        );
        final textButton = tester.widget<TextButton>(
          find.byKey(const Key('journal-privacy')),
        );
        expect(
          textButton.style?.foregroundColor?.resolve({}),
          theme.colorScheme.primary,
        );
      },
    );
  }

  testWidgets(
    'Given a new phone entry, when Private is saved on and later turned off, then the row starts covered and the edit shows the subject',
    (tester) async {
      const subject = 'Morning note';
      const text = 'Kept it.';
      final saved = JournalEntry.create(
        id: 'entry-1',
        subject: subject,
        mood: 4,
        text: text,
        private: true,
        now: DateTime.utc(2026, 11, 24, 18),
      );
      final when = journalDetailWhen(saved, includeYear: false);
      final repository = await _pumpJournalScreen(
        tester,
        size: _phone,
        clock: () => DateTime.utc(2026, 11, 24, 20),
      );
      await tester.tap(find.text(_emptyAction));
      await tester.pumpAndSettle();
      await _enterEntry(tester, subject: subject, text: text, mood: 4);
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repository.saves, [
        (subject: subject, mood: 4, text: text, private: true),
      ]);
      expect(find.text(_emptyTitle), findsNothing);
      expect(find.text(subject), findsNothing);
      expect(find.text('Private entry'), findsOneWidget);

      await tester.tap(find.byKey(const Key('journal-entry-entry-1')));
      await tester.pumpAndSettle();

      _expectPrivateCover(
        tester,
        scope: find.byKey(const Key('journal-entry-screen')),
        desktop: false,
        scheme: AppTheme.light.colorScheme,
      );
      expect(find.text(when), findsOneWidget);
      expect(find.text(subject), findsNothing);
      expect(find.text(text), findsNothing);

      await tester.tap(find.byKey(const Key('journal-show-content')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('journal-edit')));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.byKey(_saveKey));
      await tester.pumpAndSettle();

      expect(repository.updates, [
        (subject: subject, mood: 4, text: text, private: false),
      ]);
      expect(find.text(subject), findsOneWidget);
      expect(find.text(text), findsOneWidget);
      expect(find.text(when), findsOneWidget);
      expect(find.byKey(const Key('journal-private-cover')), findsNothing);
    },
  );
}
