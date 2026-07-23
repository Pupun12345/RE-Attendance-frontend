import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartcare_app/main.dart';

void main() {
  testWidgets('App starts on the splash screen without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    // The splash screen waits 3s before navigating away; let that finish so
    // no timer is left pending when the test tears down the widget tree.
    await tester.pump(const Duration(seconds: 3));
  });
}
