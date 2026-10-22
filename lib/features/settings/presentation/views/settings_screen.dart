import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsCubit>().state;
    _urlController = TextEditingController(text: state.ollamaBaseUrl);
    _modelController = TextEditingController(text: state.modelName);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (_urlController.text != state.ollamaBaseUrl) {
          _urlController.text = state.ollamaBaseUrl;
        }
        if (_modelController.text != state.modelName) {
          _modelController.text = state.modelName;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Cấu hình Local LLM & Voice',
              style: AppTypography.heading2,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Connection Status Banner
              _buildConnectionCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Local LLM Host & Model Settings
              _buildModelConfigCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Audio TTS Settings
              _buildAudioSettingsCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Target Language Selection
              _buildLanguageSelectionCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Instructions / Guide
              _buildSetupGuideCard(context, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (state.isOnDevice) {
      if (state.isModelDownloaded) {
        statusColor = AppColors.success;
        statusText = 'On-Device AI: Sẵn sàng Offline 100%';
        statusIcon = Icons.check_circle_rounded;
      } else {
        statusColor = AppColors.accent;
        statusText = 'On-Device AI: Chưa tải model (~350MB)';
        statusIcon = Icons.cloud_download_rounded;
      }
    } else {
      switch (state.connectionStatus) {
        case ConnectionStatus.connected:
          statusColor = AppColors.success;
          statusText = 'Đã kết nối thành công với Local Ollama';
          statusIcon = Icons.check_circle_rounded;
          break;
        case ConnectionStatus.checking:
          statusColor = AppColors.accent;
          statusText = 'Đang kiểm tra kết nối Ollama...';
          statusIcon = Icons.sync_rounded;
          break;
        case ConnectionStatus.failed:
        default:
          statusColor = AppColors.error;
          statusText = 'Chưa kết nối. Hãy kiểm tra Ollama Host.';
          statusIcon = Icons.error_outline_rounded;
          break;
      }
    }

    final subtitleText = state.isOnDevice
        ? (state.isModelDownloaded
              ? 'Mô hình: Qwen 2.5 0.5B Instruct • Tiết kiệm RAM'
              : 'Nhấn Tải Model bên dưới để sử dụng không cần mạng')
        : state.ollamaBaseUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTypography.label.copyWith(color: statusColor),
                ),
                Text(
                  subtitleText,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kiểm tra lại',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => cubit.testConnection(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelConfigCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chế độ hoạt động LLM', style: AppTypography.heading3),
            const SizedBox(height: 12),

            // Execution Mode Switcher
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      title: '📱 On-Device (Offline)',
                      subtitle: 'Không cần mạng • ~350MB',
                      isSelected: state.isOnDevice,
                      onTap: () => cubit.updateExecutionMode('on_device'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildModeTab(
                      title: '🖥️ Ollama (Local Host)',
                      subtitle: 'Qua Wifi / Mạng nội bộ',
                      isSelected: !state.isOnDevice,
                      onTap: () => cubit.updateExecutionMode('ollama'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (state.isOnDevice)
              _buildOnDeviceSettings(context, state, cubit, isDark)
            else
              _buildOllamaSettings(context, state, cubit, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnDeviceSettings(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mô hình: Qwen 2.5 0.5B Nano (Q4_K_M)',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tối ưu hóa chạy trực tiếp trên chip thiết bị (CPU/GPU) qua engine GGUF nén 4-bit. '
                'Tiêu thụ chỉ ~450MB RAM, không nóng máy, không phụ thuộc vào kết nối mạng.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (state.isDownloadingModel) ...[
          Text(
            'Tiến trình tải mô hình:',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.downloadProgress > 0 ? state.downloadProgress : null,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.downloadStatusText,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.primary,
            ),
          ),
        ] else if (state.isModelDownloaded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã cài đặt sẵn sàng (~350MB)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => cubit.deleteModel(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  label: Text(
                    'Xóa',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: () => cubit.startModelDownload(),
            icon: const Icon(Icons.cloud_download_rounded, size: 20),
            label: const Text('Tải Mô Hình On-Device ngay (~350MB)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Chỉ cần tải 1 lần duy nhất, sau đó sử dụng vĩnh viễn không cần mạng.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOllamaSettings(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ Host Ollama URL',
            hintText: 'http://127.0.0.1:11434',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          onSubmitted: (val) => cubit.updateBaseUrl(val),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: 'Tên Model',
            hintText: 'qwen2.5:3b',
            prefixIcon: Icon(Icons.memory_rounded),
          ),
          onSubmitted: (val) => cubit.updateModel(val),
        ),
        const SizedBox(height: 10),
        Text('Model gợi ý tối ưu:', style: AppTypography.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickModelChip('qwen2.5:3b', 'Tối ưu Tiếng Việt ⭐', cubit),
            _buildQuickModelChip('qwen2.5:1.5b', 'Siêu nhẹ', cubit),
            _buildQuickModelChip('llama3.2:3b', 'Luyện nói tiếng Anh', cubit),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickModelChip(
    String model,
    String subtitle,
    SettingsCubit cubit,
  ) {
    return ActionChip(
      label: Text('$model ($subtitle)', style: AppTypography.bodySmall),
      onPressed: () {
        _modelController.text = model;
        cubit.updateModel(model);
      },
    );
  }

  Widget _buildAudioSettingsCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Giọng Đọc & Phát Âm (TTS)',
                    style: AppTypography.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => cubit.testVoicePlayback(),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: const Text('Nghe thử'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: AppColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'Chọn Giới tính Giọng đọc (AI Voice):',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGenderChoice(
                    context,
                    title: 'Giọng Nữ',
                    subtitle: 'Trong trẻo, tự nhiên',
                    emoji: '👩',
                    isSelected: state.voiceGender == 'female',
                    onTap: () => cubit.updateVoiceGender('female'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGenderChoice(
                    context,
                    title: 'Giọng Nam',
                    subtitle: 'Trầm ấm, đĩnh đạc',
                    emoji: '👨',
                    isSelected: state.voiceGender == 'male',
                    onTap: () => cubit.updateVoiceGender('male'),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Tốc độ đọc: ${state.speechRate.toStringAsFixed(1)}x (${state.speechRate < 0.5
                  ? "Chậm"
                  : state.speechRate == 0.5
                  ? "Chuẩn"
                  : "Nhanh"})',
              style: AppTypography.bodyMedium,
            ),
            Slider(
              value: state.speechRate,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              activeColor: AppColors.primary,
              onChanged: (val) => cubit.updateSpeechRate(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChoice(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.12)
        : (isDark ? AppColors.darkCard : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngôn ngữ mục tiêu đang học', style: AppTypography.heading3),
            const SizedBox(height: 12),
            ...LanguageRegistry.supportedLanguages.map((profile) {
              final isSelected = profile.code == state.currentLanguage.code;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  profile.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(profile.name, style: AppTypography.label),
                subtitle: Text(
                  profile.nativeName,
                  style: AppTypography.bodySmall,
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => cubit.selectLanguage(profile),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupGuideCard(BuildContext context, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF131E30) : const Color(0xFFF1F5F9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Hướng dẫn chạy Local LLM', style: AppTypography.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1. Mở terminal trên máy tính và chạy:\n   ollama run qwen2.5:3b\n\n'
              '2. Nếu chạy trên Android Emulator, chỉnh URL thành:\n   http://10.0.2.2:11434\n\n'
              '3. Nếu chạy Desktop hoặc iOS Simulator:\n   http://127.0.0.1:11434',
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
