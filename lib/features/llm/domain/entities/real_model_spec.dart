enum ModelSuitability {
  optimal, // Máy chạy rất mượt, dư dả tài nguyên
  compatible, // Máy chạy tốt, tải trung bình
  demanding, // Nặng đối với máy, có thể chậm hoặc nóng
  insufficient, // Không đủ RAM hoặc ROM
}

class RealModelSpec {
  final String id;
  final String displayName;
  final String parameterSize;
  final double requiredRamMb;
  final double requiredStorageMb;
  final String description;
  final String bestFor;
  final bool isSupportedOnDevice;

  const RealModelSpec({
    required this.id,
    required this.displayName,
    required this.parameterSize,
    required this.requiredRamMb,
    required this.requiredStorageMb,
    required this.description,
    required this.bestFor,
    this.isSupportedOnDevice = false,
  });

  String get ramRequirementDisplay =>
      '${(requiredRamMb / 1024).toStringAsFixed(1)} GB RAM';

  String get storageRequirementDisplay => requiredStorageMb >= 1024
      ? '${(requiredStorageMb / 1024).toStringAsFixed(1)} GB'
      : '${requiredStorageMb.toInt()} MB';

  ModelSuitability evaluate(double availableRamMb, double freeDiskMb) {
    if (freeDiskMb < requiredStorageMb || availableRamMb < (requiredRamMb * 0.7)) {
      return ModelSuitability.insufficient;
    }
    if (availableRamMb < requiredRamMb) {
      return ModelSuitability.demanding;
    }
    if (availableRamMb >= requiredRamMb * 1.4) {
      return ModelSuitability.optimal;
    }
    return ModelSuitability.compatible;
  }
}

class RealModelCatalog {
  static const List<RealModelSpec> realModels = [
    RealModelSpec(
      id: 'qwen2.5:0.5b',
      displayName: 'Qwen 2.5 0.5B Instruct',
      parameterSize: '0.5B',
      requiredRamMb: 450,
      requiredStorageMb: 360,
      description: 'Siêu nhẹ, phản hồi tức thì, tiết kiệm pin & RAM tối đa.',
      bestFor: 'Thiết bị di động, On-Device, máy cấu hình thấp',
      isSupportedOnDevice: true,
    ),
    RealModelSpec(
      id: 'qwen2.5:1.5b',
      displayName: 'Qwen 2.5 1.5B Instruct',
      parameterSize: '1.5B',
      requiredRamMb: 1200,
      requiredStorageMb: 980,
      description: 'Cân bằng hoàn hảo giữa ngữ pháp tự nhiên và tốc độ sinh từ.',
      bestFor: 'Thiết bị tầm trung, đàm thoại thông dụng',
      isSupportedOnDevice: true,
    ),
    RealModelSpec(
      id: 'qwen2.5:3b',
      displayName: 'Qwen 2.5 3B Instruct',
      parameterSize: '3.1B',
      requiredRamMb: 2500,
      requiredStorageMb: 1950,
      description: 'Chuyên gia Tiếng Việt & Anh, sửa lỗi ngữ pháp và văn phong xuất sắc.',
      bestFor: 'Máy chủ Ollama / Flagship di động (RAM >= 8GB)',
      isSupportedOnDevice: false,
    ),
    RealModelSpec(
      id: 'llama3.2:3b',
      displayName: 'Llama 3.2 3B Instruct',
      parameterSize: '3.2B',
      requiredRamMb: 2600,
      requiredStorageMb: 2050,
      description: 'Kiến trúc Meta Llama 3 mới nhất, đàm thoại tiếng Anh bản ngữ mượt mà.',
      bestFor: 'Học tiếng Anh chuyên sâu qua Ollama',
      isSupportedOnDevice: false,
    ),
    RealModelSpec(
      id: 'qwen2.5:7b',
      displayName: 'Qwen 2.5 7B Instruct',
      parameterSize: '7.6B',
      requiredRamMb: 5500,
      requiredStorageMb: 4700,
      description: 'Mô hình lớn độ thông minh cao cấp, phân tích câu và giải thích chuyên sâu.',
      bestFor: 'Máy chủ PC/Mac có GPU hoặc 16GB RAM',
      isSupportedOnDevice: false,
    ),
  ];

  static RealModelSpec findById(String id) {
    final normalized = id.trim().toLowerCase();
    return realModels.firstWhere(
      (m) => m.id.toLowerCase() == normalized,
      orElse: () => RealModelSpec(
        id: id,
        displayName: id,
        parameterSize: 'Tùy chỉnh',
        requiredRamMb: 2048,
        requiredStorageMb: 2048,
        description: 'Mô hình tùy chỉnh trên máy chủ.',
        bestFor: 'Sử dụng linh hoạt',
      ),
    );
  }
}
