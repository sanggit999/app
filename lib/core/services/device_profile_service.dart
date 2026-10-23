import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum HardwareTier {
  low, // < 3.5GB RAM or < 1.5GB free storage
  standard, // 3.5GB - 6.5GB RAM & >= 1.5GB storage
  high, // >= 6.5GB RAM & >= 4GB storage
}

class DeviceProfile {
  final String deviceName;
  final String manufacturer;
  final double totalRamMb;
  final double availableRamMb;
  final double freeDiskMb;
  final HardwareTier tier;
  final String recommendedModelName;
  final String recommendationDescription;

  const DeviceProfile({
    required this.deviceName,
    required this.manufacturer,
    required this.totalRamMb,
    required this.availableRamMb,
    required this.freeDiskMb,
    required this.tier,
    required this.recommendedModelName,
    required this.recommendationDescription,
  });

  String get ramDisplay =>
      totalRamMb > 0 ? '${(totalRamMb / 1024).toStringAsFixed(1)} GB' : 'Không xác định';

  String get freeDiskDisplay =>
      freeDiskMb > 0 ? '${(freeDiskMb / 1024).toStringAsFixed(1)} GB' : 'Không xác định';

  String get deviceLabel {
    if (manufacturer.isEmpty && deviceName.isEmpty) {
      return Platform.operatingSystem.toUpperCase();
    }
    if (manufacturer.toLowerCase() == 'unknown' || manufacturer.isEmpty) {
      return deviceName;
    }
    if (deviceName.toLowerCase().contains(manufacturer.toLowerCase())) {
      return deviceName;
    }
    return '$manufacturer $deviceName';
  }

  factory DeviceProfile.fallback() {
    return const DeviceProfile(
      deviceName: 'Thiết bị di động',
      manufacturer: '',
      totalRamMb: 4096,
      availableRamMb: 2048,
      freeDiskMb: 8192,
      tier: HardwareTier.standard,
      recommendedModelName: 'qwen2.5:0.5b',
      recommendationDescription:
          'Cấu hình tiêu chuẩn. Tối ưu hoàn hảo cho Qwen 2.5 0.5B chạy On-Device.',
    );
  }
}

class DeviceProfileService {
  DeviceProfile? _cachedProfile;

  Future<DeviceProfile> refreshProfile() async {
    debugPrint('🔄 [DeviceProfileService] Yêu cầu quét mới cấu hình phần cứng...');
    _cachedProfile = null;
    return getDeviceProfile();
  }

  Future<DeviceProfile> getDeviceProfile() async {
    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    try {
      if (Platform.isAndroid) {
        _cachedProfile = await _detectAndroidProfile();
      } else {
        _cachedProfile = _detectGenericProfile();
      }
    } catch (e) {
      debugPrint('⚠️ [DeviceProfileService] Không thể quét phần cứng, dùng profile mặc định: $e');
      _cachedProfile = DeviceProfile.fallback();
    }

    return _cachedProfile!;
  }

  Future<DeviceProfile> _detectAndroidProfile() async {
    double totalRamMb = 0;
    double availableRamMb = 0;
    double freeDiskMb = 0;
    String model = '';
    String manufacturer = '';

    // 1. Read RAM via /proc/meminfo
    try {
      final memFile = File('/proc/meminfo');
      if (await memFile.exists()) {
        final lines = await memFile.readAsLines();
        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            totalRamMb = _parseKbToMb(line);
          } else if (line.startsWith('MemAvailable:')) {
            availableRamMb = _parseKbToMb(line);
          }
        }
      }
      debugPrint('   -> /proc/meminfo: MemTotal=${totalRamMb.toStringAsFixed(0)}MB, MemAvailable=${availableRamMb.toStringAsFixed(0)}MB');
    } catch (e) {
      debugPrint('   -> /proc/meminfo đọc thất bại: $e');
    }

    // 2. Read Device Model & Manufacturer via getprop
    try {
      final modelRes = await Process.run('getprop', ['ro.product.model']);
      if (modelRes.exitCode == 0) {
        model = modelRes.stdout.toString().trim();
      }
    } catch (_) {}

    try {
      final brandRes = await Process.run('getprop', ['ro.product.manufacturer']);
      if (brandRes.exitCode == 0) {
        manufacturer = brandRes.stdout.toString().trim();
      }
    } catch (_) {}

    // Clean up emulator names for better UX
    if (model.toLowerCase().contains('sdk_gphone') || model.toLowerCase().contains('emulator')) {
      model = 'Android Emulator';
    }
    debugPrint('   -> Thiết bị phát hiện: $manufacturer $model');

    // 3. Read Free Storage on app document path
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dfRes = await Process.run('df', ['-k', appDir.path]);
      if (dfRes.exitCode == 0) {
        final lines = dfRes.stdout.toString().trim().split('\n');
        if (lines.length >= 2) {
          // Format: Filesystem 1K-blocks Used Available Use% Mounted
          final parts = lines.last.trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final availKb = double.tryParse(parts[3]) ?? 0;
            freeDiskMb = availKb / 1024;
          }
        }
      }
      debugPrint('   -> Bộ nhớ trong trống: ${freeDiskMb.toStringAsFixed(0)}MB');
    } catch (e) {
      debugPrint('   -> df storage đọc thất bại: $e');
    }

    // If detection failed to get RAM, fallback safely
    if (totalRamMb <= 0) totalRamMb = 4096;
    if (freeDiskMb <= 0) freeDiskMb = 5120;

    return _buildProfile(
      deviceName: model.isNotEmpty ? model : 'Android Device',
      manufacturer: manufacturer.isNotEmpty ? manufacturer : 'Android',
      totalRamMb: totalRamMb,
      availableRamMb: availableRamMb,
      freeDiskMb: freeDiskMb,
    );
  }

  DeviceProfile _detectGenericProfile() {
    final os = Platform.operatingSystem;
    final totalRamMb = 8192.0; // Desktop/Generic estimate
    final freeDiskMb = 32768.0;

    return _buildProfile(
      deviceName: os.toUpperCase(),
      manufacturer: Platform.operatingSystemVersion,
      totalRamMb: totalRamMb,
      availableRamMb: 4096.0,
      freeDiskMb: freeDiskMb,
    );
  }

  DeviceProfile _buildProfile({
    required String deviceName,
    required String manufacturer,
    required double totalRamMb,
    required double availableRamMb,
    required double freeDiskMb,
  }) {
    HardwareTier tier;
    String recModel;
    String recDesc;

    if (totalRamMb < 3500 || freeDiskMb < 1500) {
      tier = HardwareTier.low;
      recModel = 'Máy chủ Ollama';
      recDesc =
          'Bộ nhớ RAM hoặc ROM khá khiêm tốn. Khuyên dùng Máy chủ Ollama (trên PC) để tránh làm chậm máy.';
    } else if (totalRamMb >= 6500 && freeDiskMb >= 4000) {
      tier = HardwareTier.high;
      recModel = 'Qwen 2.5 0.5B / Ollama 3B';
      recDesc =
          'Cấu hình mạnh mẽ. Thiết bị của bạn chạy rất mượt On-Device lẫn các mô hình lớn qua Ollama.';
    } else {
      tier = HardwareTier.standard;
      recModel = 'Qwen 2.5 0.5B (On-Device)';
      recDesc =
          'Cấu hình tiêu chuẩn. Tối ưu hoàn hảo cho Qwen 2.5 0.5B chạy trực tiếp trên máy không cần mạng.';
    }

    return DeviceProfile(
      deviceName: deviceName,
      manufacturer: manufacturer,
      totalRamMb: totalRamMb,
      availableRamMb: availableRamMb,
      freeDiskMb: freeDiskMb,
      tier: tier,
      recommendedModelName: recModel,
      recommendationDescription: recDesc,
    );
  }

  double _parseKbToMb(String memLine) {
    try {
      final parts = memLine.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final kb = double.tryParse(parts[1]) ?? 0;
        return kb / 1024;
      }
    } catch (_) {}
    return 0;
  }
}
