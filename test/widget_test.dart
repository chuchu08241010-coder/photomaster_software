import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photomaster/features/auth/login_page.dart';

void main() {
  testWidgets('登录页正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('PhotoMaster'), findsOneWidget);
    expect(find.text('进入圈子'), findsOneWidget);
  });
}
