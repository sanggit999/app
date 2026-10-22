import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloadProgress {
  final double fraction; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final bool isCompleted;
  final bool isPaused;
  final String? error;

  const ModelDownloadProgress({
    required this.fraction,
    required this.receivedBytes,
    required this.totalBytes,
    this.isCompleted = false,
    this.isPaused = false,
    this.error,
  });

  String get receivedMb => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMb => totalBytes > 0
      ? (totalBytes / (1024 * 1024)).toStringAsFixed(1)
      : '360.0';
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
  bool _cancelRequested = false;

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

  /// Trả về số byte của file part đang tải dở (nếu có)
  Future<int> getPartialDownloadedSizeBytes([
    String fileName = defaultModelFileName,
  ]) async {
    final targetPath = await getModelFilePath(fileName);
    final tempFile = File('$targetPath.part');
    if (await tempFile.exists()) {
      return await tempFile.length();
    }
    return 0;
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

  void cancelOrPauseDownload() {
    if (_isDownloading) {
      _cancelRequested = true;
    }
  }

  Future<void> downloadModel({
    String url = defaultModelDownloadUrl,
    String fileName = defaultModelFileName,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _cancelRequested = false;

    final targetPath = await getModelFilePath(fileName);
    final tempPath = '$targetPath.part';
    final tempFile = File(tempPath);

    int existingBytes = 0;
    if (await tempFile.exists()) {
      existingBytes = await tempFile.length();
    }

    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);

      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }

      final response = await _client.send(request);

      // 206: Partial Content (Resume thành công)
      // 200: Server gửi toàn bộ file từ đầu (nếu server không hỗ trợ range hoặc file chưa tải gì)
      // 416: Range Not Satisfiable (file part đã tải trọn vẹn)
      if (response.statusCode != 200 &&
          response.statusCode != 206 &&
          response.statusCode != 416) {
        throw Exception('Server responded with HTTP ${response.statusCode}');
      }

      int totalBytes = 0;
      bool isResume = response.statusCode == 206;

      if (isResume) {
        final contentRange = response.headers['content-range'];
        if (contentRange != null && contentRange.contains('/')) {
          final totalStr = contentRange.split('/').last.trim();
          totalBytes = int.tryParse(totalStr) ?? (existingBytes + (response.contentLength ?? 0));
        } else {
          totalBytes = existingBytes + (response.contentLength ?? 0);
        }
      } else if (response.statusCode == 416) {
        // Đã hoàn thành toàn bộ bytes
        totalBytes = existingBytes;
      } else {
        // Status 200: tải mới từ đầu, reset file part nếu có
        existingBytes = 0;
        totalBytes = response.contentLength ?? 360 * 1024 * 1024;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      int receivedBytes = existingBytes;

      if (response.statusCode != 416) {
        final sink = tempFile.openWrite(
          mode: isResume ? FileMode.append : FileMode.write,
        );

        await for (final chunk in response.stream) {
          if (_cancelRequested) {
            await sink.flush();
            await sink.close();
            _progressController.add(
              ModelDownloadProgress(
                fraction: totalBytes > 0
                    ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
                    : 0.0,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                isPaused: true,
              ),
            );
            return;
          }

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
      }

      if (_cancelRequested) {
        _progressController.add(
          ModelDownloadProgress(
            fraction: totalBytes > 0
                ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
                : 0.0,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            isPaused: true,
          ),
        );
        return;
      }

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
          totalBytes: totalBytes > 0 ? totalBytes : receivedBytes,
          isCompleted: true,
        ),
      );
    } catch (e) {
      if (_cancelRequested) {
        _progressController.add(
          ModelDownloadProgress(
            fraction: 0.0,
            receivedBytes: existingBytes,
            totalBytes: 0,
            isPaused: true,
          ),
        );
        return;
      }

      _progressController.add(
        ModelDownloadProgress(
          fraction: 0.0,
          receivedBytes: existingBytes,
          totalBytes: 0,
          error: e.toString(),
        ),
      );
      // Giữ lại file .part để người dùng có thể tiếp tục tải sau mà không mất dữ liệu đã tải!
      rethrow;
    } finally {
      _isDownloading = false;
      _cancelRequested = false;
    }
  }

  Future<void> deleteModel([String fileName = defaultModelFileName]) async {
    final path = await getModelFilePath(fileName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final partFile = File('$path.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  void dispose() {
    _progressController.close();
  }
}
