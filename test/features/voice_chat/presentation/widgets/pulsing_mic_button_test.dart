import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_lingua/features/voice_chat/presentation/widgets/pulsing_mic_button.dart';

void main() {
  testWidgets('PulsingMicButton renders and triggers onPressed on tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PulsingMicButton(
              isListening: false,
              soundLevel: 0.0,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PulsingMicButton), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

    await tester.tap(find.byType(PulsingMicButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PulsingMicButton displays mic recording icon when listening', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PulsingMicButton(
              isListening: true,
              soundLevel: 5.0,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
