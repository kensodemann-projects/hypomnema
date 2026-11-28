import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/utils/edit_window.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 14, 14, 2);
  final deadline = DateTime.utc(2026, 11, 15, 14, 2);

  test('Given a creation instant, when the deadline is read, then it is that instant plus 24 hours in UTC', () {
    // Given, when
    final result = editWindowDeadline(createdAt);

    // Then
    expect(result, deadline);
    expect(result.isUtc, isTrue);
  });

  test('Given a local creation instant, when the deadline is read, then it is that same instant plus 24 hours in UTC', () {
    // Given
    final local = DateTime(2026, 11, 14, 8, 2);

    // When
    final result = editWindowDeadline(local);

    // Then
    expect(result, local.toUtc().add(const Duration(hours: 24)));
    expect(result.isUtc, isTrue);
  });

  test(
    'Given now equal to creation, when the window is checked, then it is open',
    () {
      expect(isWithinEditWindow(createdAt: createdAt, now: createdAt), isTrue);
    },
  );

  test('Given now equal to the deadline, when the window is checked, then it is open', () {
    expect(isWithinEditWindow(createdAt: createdAt, now: deadline), isTrue);
  });

  test('Given now one microsecond after the deadline, when the window is checked, then it is closed', () {
    final now = deadline.add(const Duration(microseconds: 1));

    expect(isWithinEditWindow(createdAt: createdAt, now: now), isFalse);
  });

  test('Given a local now at the deadline, when the window is checked, then it is open', () {
    final now = DateTime(2026, 11, 14, 8, 2);
    final created = DateTime(
      2026,
      11,
      14,
      8,
      2,
    ).toUtc().subtract(const Duration(hours: 24));

    expect(isWithinEditWindow(createdAt: created, now: now), isTrue);
  });

  test('Given a local now one microsecond after the deadline, when the window is checked, then it is closed', () {
    final now = DateTime(2026, 11, 14, 8, 2);
    final created = DateTime(
      2026,
      11,
      14,
      8,
      2,
    ).toUtc().subtract(const Duration(hours: 24, microseconds: 1));

    expect(isWithinEditWindow(createdAt: created, now: now), isFalse);
  });
}
