import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crown_password_studio/main.dart';

void main() {
  testWidgets('Crown home provides its four main actions', (tester) async {
    await tester.pumpWidget(const CrownApp());
    expect(find.text('Crown Password Studio'), findsOneWidget);
    expect(find.text('Unlock File'), findsOneWidget);
    expect(find.text('Protect File'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
  });
}
