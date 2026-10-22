import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:llamadart/llamadart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/services/llm_service.dart';
import 'model_manager.dart';

class OnDeviceLlmService implements LlmService {
  final ModelManager modelManager;
  LlamaEngine? _engine;
  bool _isLoading = false;

  OnDeviceLlmService({required this.modelManager});

  bool get isModelLoaded => _engine != null;
  bool get isLoading => _isLoading;

  Future<LlamaEngine> _getOrLoadEngine() async {
    if (_engine != null) return _engine!;

    final isDownloaded = await modelManager.isModelDownloaded();
    if (!isDownloaded) {
      throw const ServerException(
        message: 'Mô hình On-Device chưa được tải về máy. Vui lòng vào Cài đặt để tải model (~350MB).',
      );
    }

    final modelPath = await modelManager.getModelFilePath();
    final cpuThreads = math.max(1, (Platform.numberOfProcessors / 2).floor());

    // Capped Context Size: 1024 tokens to keep RAM consumption ultralow (~450MB) and prevent OOM
    final params = ModelParams(
      contextSize: 1024,
      numberOfThreads: cpuThreads,
      useMmap: true,
    );

    try {
      _isLoading = true;
      _engine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(modelPath)),
        params: params,
      );
      return _engine!;
    } catch (e) {
      throw ServerException(message: 'Không thể khởi động On-Device LLM: $e');
    } finally {
      _isLoading = false;
    }
  }

  @override
  Stream<String> streamChat({
    required List<Map<String, String>> messages,
    String? model,
    Map<String, dynamic>? options,
  }) async* {
    final engine = await _getOrLoadEngine();

    final llamaMessages = <LlamaChatMessage>[];
    for (final m in messages) {
      final roleStr = m['role'] ?? 'user';
      final content = m['content'] ?? '';
      final LlamaChatRole role;
      if (roleStr == 'system') {
        role = LlamaChatRole.system;
      } else if (roleStr == 'assistant') {
        role = LlamaChatRole.assistant;
      } else {
        role = LlamaChatRole.user;
      }
      llamaMessages.add(LlamaChatMessage.fromText(role: role, text: content));
    }

    await for (final chunk in engine.create(llamaMessages)) {
      if (chunk.text.isNotEmpty) {
        yield chunk.text;
      }
    }
  }

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    String? model,
  }) async {
    final engine = await _getOrLoadEngine();
    final llamaMessages = <LlamaChatMessage>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      llamaMessages.add(
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: systemPrompt,
        ),
      );
    }
    llamaMessages.add(
      LlamaChatMessage.fromText(role: LlamaChatRole.user, text: prompt),
    );

    final reply = await engine.complete(llamaMessages);
    return reply.text;
  }

  @override
  Future<bool> checkHealth() async {
    return await modelManager.isModelDownloaded();
  }

  Future<void> unloadModel() async {
    await _engine?.dispose();
    _engine = null;
  }

  Future<void> dispose() async {
    await unloadModel();
  }
}
