import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/main.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'Given the platform brightness, when it is light, then MainApp matches it',
    (tester) async {
      // Given
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(
        Theme.of(tester.element(find.text('Phone'))).brightness,
        Brightness.light,
      );
    },
  );

  testWidgets(
    'Given the platform brightness, when it is dark, then MainApp matches it',
    (tester) async {
      // Given
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(
        Theme.of(tester.element(find.text('Phone'))).brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets(
    'Given a physical size, when the width is 400, then the phone layout is used',
    (tester) async {
      // Given
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
    },
  );

  testWidgets(
    'Given a physical size, when the width is 600, then the phone layout is used',
    (tester) async {
      // Given
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 800);

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
    },
  );

  testWidgets(
    'Given a physical size, when the width is 601, then the desktop layout is used',
    (tester) async {
      // Given
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(601, 800);

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Phone'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
    },
  );

  testWidgets(
    'Given a physical size, when the width is 1200, then the desktop layout is used',
    (tester) async {
      // Given
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);

      // When
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Phone'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
    },
  );
}
