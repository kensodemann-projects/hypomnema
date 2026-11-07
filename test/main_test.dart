import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/main.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('MainApp follows the platform brightness', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    for (final brightness in [Brightness.light, Brightness.dark]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.text('Hello World!'))).brightness,
        brightness,
      );
    }
  });
}
