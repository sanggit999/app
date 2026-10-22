import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/llm_service.dart';
import 'ollama_llm_service.dart';
import 'on_device_llm_service.dart';

enum LlmExecutionMode {
  ollama,
  onDevice;

  static LlmExecutionMode fromString(String? value) {
    if (value == 'on_device') return LlmExecutionMode.onDevice;
    return LlmExecutionMode.ollama;
  }

  String toValue() {
    switch (this) {
      case LlmExecutionMode.onDevice:
        return 'on_device';
      case LlmExecutionMode.ollama:
        return 'ollama';
    }
  }
}

class AdaptiveLlmService implements LlmService {
  final OllamaLlmService ollamaService;
  final OnDeviceLlmService onDeviceService;
  final SharedPreferences sharedPreferences;

  static const String keyExecutionMode = 'llm_execution_mode';

  AdaptiveLlmService({
    required this.ollamaService,
    required this.onDeviceService,
    required this.sharedPreferences,
  });

  LlmExecutionMode get currentMode {
    final modeStr = sharedPreferences.getString(keyExecutionMode);
    return LlmExecutionMode.fromString(modeStr);
  }

  bool get isOnDevice => currentMode == LlmExecutionMode.onDevice;

  LlmService get _activeService => isOnDevice ? onDeviceService : ollamaService;

  @override
  Stream<String> streamChat({
    required List<Map<String, String>> messages,
    String? model,
    Map<String, dynamic>? options,
  }) {
    return _activeService.streamChat(
      messages: messages,
      model: model,
      options: options,
    );
  }

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    String? model,
  }) {
    return _activeService.generate(
      prompt: prompt,
      systemPrompt: systemPrompt,
      model: model,
    );
  }

  @override
  Future<bool> checkHealth() {
    return _activeService.checkHealth();
  }
}
