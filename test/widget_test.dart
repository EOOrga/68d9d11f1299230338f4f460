import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scp_breux_ops/operations_app.dart';
import 'package:scp_breux_ops/operations_data.dart';

void main() {
  testWidgets('shows seeded operations and navigates by workstream', (
    tester,
  ) async {
    await tester.pumpWidget(
      SCPBreuxOpsApp(
        repository: MemoryOperationsRepository(seedOperations()),
        screenshotMode: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations hub'), findsOneWidget);
    expect(find.text('Open records'), findsOneWidget);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Work orders'), findsWidgets);
    expect(find.text('Kitchen equipment service'), findsOneWidget);
  });

  testWidgets('creates a local work order record', (tester) async {
    await tester.pumpWidget(
      SCPBreuxOpsApp(
        repository: MemoryOperationsRepository(),
        screenshotMode: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-work_order')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('titleField')),
      'Boiler room inspection',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ownerField')),
      'Operations desk',
    );
    await tester.enterText(
      find.byKey(const ValueKey('notesField')),
      'Check valves, update the service board, and close the work order.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('saveRecordButton')),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('saveRecordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Boiler room inspection'), findsOneWidget);
    expect(find.text('Operations desk'), findsOneWidget);
  });
}
