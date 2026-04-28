import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sargam/app/app.dart';

void main() {
  testWidgets('Sargam app boots to riyaz screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SargamApp()));
    await tester.pump();
    expect(find.text('Sargam'), findsOneWidget);
    expect(find.text('SCALE'), findsOneWidget);
    expect(find.text('Start Riyaz'), findsOneWidget);
    expect(find.text('Tanpura'), findsOneWidget);
  });
}
