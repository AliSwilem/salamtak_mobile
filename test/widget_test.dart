import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('login validates empty fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Please enter your username.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });
}
