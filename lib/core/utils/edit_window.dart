/// Returns the instant 24 hours after [createdAt], in UTC.
DateTime editWindowDeadline(DateTime createdAt) {
  return createdAt.toUtc().add(const Duration(hours: 24));
}

/// Returns whether [now] is still inside the 24-hour window from [createdAt].
///
/// The window stays open through [editWindowDeadline] and is closed after it.
bool isWithinEditWindow({required DateTime createdAt, required DateTime now}) {
  return !now.toUtc().isAfter(editWindowDeadline(createdAt));
}
