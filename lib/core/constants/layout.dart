import 'package:material_ui/material_ui.dart';

/// Minimum width for the desktop (expanded) layout.
///
/// Layout is desktop when [width] is strictly greater than this value.
const double kDesktopLayoutMinWidth = 600;

bool desktopLayoutForWidth(double width) => width > kDesktopLayoutMinWidth;

bool desktopLayoutFor(BuildContext context) =>
    desktopLayoutForWidth(MediaQuery.sizeOf(context).width);
