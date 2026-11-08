import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/main.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Given the platform brightness, When light or dark, Then the MainApp matches the platform

  // Given a physical size, when width is less than 600, Then the Phone layout is used
  // Given a physical size, when width is 600, Then the Phone layout is used
  // Given a physical size, when width is 601, Then the Desktop layout is used
  // Given a physical size, when width is greater than 601, Then the Desktop layout is used

  testWidgets('MainApp follows the platform brightness', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final brightness in [Brightness.light, Brightness.dark]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;

      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
      expect(
        Theme.of(tester.element(find.text('Phone'))).brightness,
        brightness,
      );

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Phone'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Desktop'))).brightness,
        brightness,
      );
    }
  });
}
