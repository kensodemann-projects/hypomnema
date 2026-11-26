# Refactor notes

Input for a later intent. Taken from the review of the journal list and read work.

## [QST-002] Announce each journal row as one control

**Issue:** List rows are `InkWell` taps without custom `Semantics`. The subject and the date are separate `Text` nodes, and the mood swatch is a bare digit. A screen reader walks those pieces separately instead of announcing one journal entry.

**Suggestion:** Merge the row into one button. The label is the subject, then `journalRowWhen`, then "Mood 4". Exclude the swatch's own text so the digit is not read twice. On desktop, mark the selected row as selected.

**Why:** The journal list is a primary navigation surface on both phone and desktop. The row is the control that opens or selects the entry.

## Theme consistency

Favor `ThemeData.textTheme`, and optional `ThemeExtension`s, over ad hoc `TextStyle(fontSize: …)` and caller-supplied `titleSize` / `headingSize`. `AppTheme` sets `ColorScheme` and `AppColors` and leaves `textTheme` at the Material defaults. The journal UI is the first large consumer of fixed pixel sizes from the mock-ups.

| Area | Current pattern | Theme direction |
| ---- | ----------------- | ------------- |
| Screen titles | Phone 22px, desktop 24px, weight 400, custom letter spacing on desktop | `textTheme.headlineSmall` / `titleLarge` variants in `AppTheme` |
| Week section headings | 11–12px, w600, letter spacing 0.72 / 0.88, uppercase in widget | `labelSmall` + `letterSpacing` in theme, or a `JournalTextStyles` extension |
| Row subject / when | w500 subject; 12px when label | `titleSmall` + `labelSmall` with `onSurfaceVariant` |
| Detail “when” line | 13px `onSurfaceVariant` | `labelMedium` |
| Detail subject | 22px phone / 26px desktop, height 1.25 | Distinct headline roles rather than `subjectSize` parameters |
| Body paragraphs | 16px, height 1.75 | `bodyLarge` with explicit height in theme |
| Empty state | `titleSize` param; message hardcoded 14px | Empty-state title/message from text theme; drop per-call `titleSize` when roles are fixed |
| Phone entry bar title | 18px w400 | Same as editor bar title role |
| “No entries yet.” | Default text style + `onSurfaceVariant` color only | `bodyMedium` + color |
| Error snackbar | `TextStyle(color: scheme.error)` on `errorContainer` | `SnackBarTheme` / `onErrorContainer` for contrast per Material 3 |
| Phone FAB | Manual `primaryContainer` / `onPrimaryContainer` | `ThemeData.floatingActionButtonTheme` or `FloatingActionButtonThemeData` tied to color scheme |
| Empty state icon | `primary.withValues(alpha: 0.8)` | Optional opacity in theme extension or shared “muted primary” role |
| Layout chrome | Pane width 380, header 72 / bar 64, card radius 16 | Not typography, but a `JournalLayout` or `ThemeExtension` could hold pane width, radii, and border widths so list/detail/card match editor |
