import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_lingua/features/voice_chat/presentation/widgets/messenger_input_bar.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget buildTestWidget({
    bool isListening = false,
    bool isThinking = false,
    double soundLevel = 0.0,
    String partialText = '',
    ValueChanged<String>? onSend,
    VoidCallback? onStartListen,
    VoidCallback? onStopListenAndSend,
    VoidCallback? onCancelListen,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MessengerInputBar(
          controller: controller,
          focusNode: focusNode,
          isListening: isListening,
          isThinking: isThinking,
          soundLevel: soundLevel,
          partialRecognizedText: partialText,
          onStartListening: onStartListen ?? () {},
          onStopListeningAndSend: onStopListenAndSend ?? () {},
          onCancelListening: onCancelListen ?? () {},
          onSendMessage: onSend ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders Mic button when input is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.byKey(const ValueKey('mic_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('send_button')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('morphs Mic button into Send button when user types text', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.byType(TextField), 'Hello world');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('send_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('mic_button')), findsNothing);
  });

  testWidgets('tapping Send button invokes onSendMessage and clears input', (
    tester,
  ) async {
    String? sentMessage;

    await tester.pumpWidget(
      buildTestWidget(onSend: (msg) => sentMessage = msg),
    );

    await tester.enterText(find.byType(TextField), 'How are you?');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('send_button')));
    await tester.pumpAndSettle();

    expect(sentMessage, 'How are you?');
    expect(controller.text, isEmpty);
    expect(find.byKey(const ValueKey('mic_button')), findsOneWidget);
  });

  testWidgets(
    'renders recording bar with cancel and send voice in listening mode',
    (tester) async {
      bool cancelClicked = false;
      bool stopAndSendClicked = false;

      await tester.pumpWidget(
        buildTestWidget(
          isListening: true,
          partialText: 'Speaking english',
          onCancelListen: () => cancelClicked = true,
          onStopListenAndSend: () => stopAndSendClicked = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording_bar')), findsOneWidget);
      expect(find.text('Speaking english'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(cancelClicked, isTrue);

      // Tap send voice
      await tester.tap(find.byTooltip('Xong & Gửi'));
      await tester.pump();
      expect(stopAndSendClicked, isTrue);
    },
  );
}
