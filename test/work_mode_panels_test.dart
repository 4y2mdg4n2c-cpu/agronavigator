import 'package:agronavigator_app/widgets/work_screen/work_side_panel.dart';
import 'package:agronavigator_app/widgets/work_screen/work_top_panel.dart';
import 'package:agronavigator_app/widgets/work_statistics_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('soil panels omit harvest-only controls and metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const WorkTopPanel(
                  area: 1.25,
                  speed: 8.4,
                  distance: 320,
                  compact: true,
                ),
                WorkSidePanel(
                  onStart: () {},
                  onPauseResume: () {},
                  onStop: () {},
                  isPaused: false,
                  hasStarted: false,
                ),
                WorkStatisticsPanel(
                  fieldName: 'Поле 1',
                  sessionArea: 1.25,
                  totalFieldArea: 4.5,
                  sessionDistance: 320,
                  workingWidth: 6,
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Урожай'), findsNothing);
    expect(find.text('Урожайность'), findsNothing);
    expect(find.text('Дистанция'), findsOneWidget);
  });

  testWidgets('harvest panels keep harvest controls and metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const WorkTopPanel(
                  area: 1.25,
                  speed: 8.4,
                  yieldValue: 32.5,
                  distance: 320,
                  compact: true,
                ),
                WorkSidePanel(
                  onStart: () {},
                  onPauseResume: () {},
                  onStop: () {},
                  onYield: () {},
                  isPaused: false,
                  hasStarted: false,
                ),
                WorkStatisticsPanel(
                  fieldName: 'Поле 1',
                  sessionArea: 1.25,
                  totalFieldArea: 4.5,
                  sessionDistance: 320,
                  workingWidth: 6,
                  yieldValue: 32.5,
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Урожай'), findsOneWidget);
    expect(find.text('Урожайность'), findsNWidgets(2));
  });
}
