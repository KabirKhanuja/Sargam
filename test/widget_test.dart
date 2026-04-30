import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sargam/app/app.dart';

void main() {
  testWidgets('Sargam app boots to auth gate', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SargamApp()));
    await tester.pump();

    expect(
      find.text('Firebase is not configured for this platform.'),
      findsOneWidget,
    );
  });
}
