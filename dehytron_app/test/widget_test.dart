import 'package:flutter_test/flutter_test.dart';
import 'package:rootery_app/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    // Use RooteryApp (your real app root class)
    await tester.pumpWidget(RooteryApp());
    await tester.pumpAndSettle();

    // basic smoke assertion
    expect(
      find.text('Welcome'),
      findsWidgets,
    ); // adjust to something your UI actually shows
  });
}

