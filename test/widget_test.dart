import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mineviewer/app.dart';

void main() {
  testWidgets('App boots and shows dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MineViewerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MineViewer'), findsOneWidget);
  });
}
