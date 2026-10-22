import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloadProgress {
  final double fraction; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final bool isCompleted;
  final String? error;

  const ModelDownloadProgress({
    required this.fraction,
    required this.receivedBytes,
    required this.totalBytes,
    this.isCompleted = false,
    this.error,
  });

  String get receivedMb => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMb => totalBytes > 0
      ? (totalBytes / (1024 * 1024)).toStringAsFixed(1)
      : '350.0';
  int get percent => (fraction * 100).clamp(0, 100).toInt();
}

class ModelManager {
  final http.Client _client;

  // Qwen2.5-0.5B-Instruct Q4_K_M (~350MB) - High quality, lightning fast, ultralight RAM (~450MB)
  static const String defaultModelFileName =
      'qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const String defaultModelDownloadUrl =
      'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf';

  final StreamController<ModelDownloadProgress> _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  bool _isDownloading = false;

  ModelManager({http.Client? client}) : _client = client ?? http.Client();

  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;
  bool get isDownloading => _isDownloading;

  Future<String> getModelDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<String> getModelFilePath([
    String fileName = defaultModelFileName,
  ]) async {
    final dirPath = await getModelDirectoryPath();
    return '$dirPath/$fileName';
  }

  Future<bool> isModelDownloaded([
    String fileName = defaultModelFileName,
  ]) async {
    final path = await getModelFilePath(fileName);
    final file = File(path);
    if (!await file.exists()) return false;
    final length = await file.length();
    // GGUF model 0.5B should be at least 300MB
    return length > 300 * 1024 * 1024;
  }

  Future<int> getDownloadedSizeBytes([
    String fileName = defaultModelFileName,
  ]) async {
    final path = await getModelFilePath(fileName);
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<void> downloadModel({
    String url = defaultModelDownloadUrl,
    String fileName = defaultModelFileName,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;

    final targetPath = await getModelFilePath(fileName);
    final tempPath = '$targetPath.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server responded with HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 360 * 1024 * 1024;
      int receivedBytes = 0;

      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final fraction = totalBytes > 0
            ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
            : 0.0;
        _progressController.add(
          ModelDownloadProgress(
            fraction: fraction,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          ),
        );
      }

      await sink.flush();
      await sink.close();

      // Rename .part to final .gguf
      final finalFile = File(targetPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(targetPath);

      _progressController.add(
        ModelDownloadProgress(
          fraction: 1.0,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          isCompleted: true,
        ),
      );
    } catch (e) {
      _progressController.add(
        ModelDownloadProgress(
          fraction: 0.0,
          receivedBytes: 0,
          totalBytes: 0,
          error: e.toString(),
        ),
      );
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      _isDownloading = false;
    }
  }

  Future<void> deleteModel([String fileName = defaultModelFileName]) async {
    final path = await getModelFilePath(fileName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _progressController.close();
  }
}
