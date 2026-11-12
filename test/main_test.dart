import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/main.dart';
import 'package:material_ui/material_ui.dart';

void setLogicalViewportSize(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

void main() {
  testWidgets(
    'Given light platform brightness, when MainApp builds, then the theme is light',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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
    'Given dark platform brightness, when MainApp builds, then the theme is dark',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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
    'Given a width of 400, when MainApp builds, then the phone layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));

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
    'Given a width of 600, when MainApp builds, then the phone layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(600, 800));

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
    'Given a width of 601, when MainApp builds, then the desktop layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(601, 800));

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
    'Given a width of 1200, when MainApp builds, then the desktop layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(1200, 800));

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
