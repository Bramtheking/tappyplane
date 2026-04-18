import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tappyplane/main.dart';

void main() {
  testWidgets('Initial screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TappyPlaneApp());

    // Verify that our home screen shows the title.
    expect(find.text('TAPPY'), findsOneWidget);
    expect(find.textContaining('PLANE'), findsOneWidget);
    
    // Check for the play button text.
    expect(find.text('TAP TO FLY!'), findsOneWidget);

    // Verify that the play icon is present.
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
  });
}
