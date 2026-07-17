import 'package:flutter_test/flutter_test.dart';
import 'package:esp32_alarm_clock_app/main.dart';

void main() {
  testWidgets('App loads home scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ESP32 智能闹钟'), findsOneWidget);
  });
}
