import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/services/device_profile_service.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/llm/domain/entities/real_model_spec.dart';
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
              // Local LLM Host & Model Settings (All-in-one AI Engine Center)
              _buildModelConfigCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Audio TTS Settings
              _buildAudioSettingsCard(context, state, cubit, isDark),
              const SizedBox(height: 16),

              // Target Language Selection
              _buildLanguageSelectionCard(context, state, cubit, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelConfigCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    final isOnDevice = state.isOnDevice;
    final isChecking = state.connectionStatus == ConnectionStatus.checking;

    // Status resolution for header badge
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOnDevice) {
      if (state.isModelDownloaded) {
        statusColor = AppColors.success;
        statusText = 'Sẵn sàng Offline';
        statusIcon = Icons.check_circle_rounded;
      } else if (state.isDownloadingModel) {
        statusColor = AppColors.primary;
        statusText = 'Đang tải ${(state.downloadProgress * 100).toInt()}%';
        statusIcon = Icons.downloading_rounded;
      } else if (state.hasPartialDownload) {
        statusColor = AppColors.warning;
        statusText = 'Tạm dừng (${state.partialDownloadedMb} MB)';
        statusIcon = Icons.pause_circle_rounded;
      } else {
        statusColor = AppColors.accent;
        statusText = 'Chưa tải mô hình';
        statusIcon = Icons.cloud_download_rounded;
      }
    } else {
      switch (state.connectionStatus) {
        case ConnectionStatus.connected:
          statusColor = AppColors.success;
          statusText = 'Đã kết nối';
          statusIcon = Icons.wifi_rounded;
          break;
        case ConnectionStatus.checking:
          statusColor = AppColors.primary;
          statusText = 'Đang kiểm tra...';
          statusIcon = Icons.sync_rounded;
          break;
        case ConnectionStatus.failed:
        default:
          statusColor = AppColors.error;
          statusText = 'Chưa kết nối';
          statusIcon = Icons.wifi_off_rounded;
          break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Live Status & Refresh Action
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ hoạt động LLM',
                        style: AppTypography.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trung tâm điều khiển mô hình AI & Kết nối',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live Status Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: AppTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Quick Refresh IconButton
                IconButton(
                  tooltip: 'Kiểm tra kết nối lại',
                  visualDensity: VisualDensity.compact,
                  icon: isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: isChecking ? null : () => cubit.testConnection(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Mode Switcher (2 Tabs: On-Device vs Ollama Server)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModernModeTab(
                      icon: Icons.offline_bolt_rounded,
                      title: 'Chạy trên máy',
                      isSelected: isOnDevice,
                      onTap: () => cubit.updateExecutionMode('on_device'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildModernModeTab(
                      icon: Icons.dns_rounded,
                      title: 'Máy chủ Ollama',
                      isSelected: !isOnDevice,
                      onTap: () => cubit.updateExecutionMode('ollama'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Smart Hardware Profiling & Recommendation Banner
            if (state.deviceProfile != null) ...[
              _buildDeviceProfilingCard(state.deviceProfile!, isDark),
              const SizedBox(height: 14),
            ],

            // Content Switcher with Smooth Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: isOnDevice
                  ? _buildOnDeviceSettings(context, state, cubit, isDark)
                  : _buildOllamaSettings(context, state, cubit, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernModeTab({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
      key: const ValueKey('on_device_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model Identity Hero Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.secondary.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Qwen 2.5 0.5B Instruct',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (state.deviceProfile != null &&
                                state.deviceProfile!.tier != HardwareTier.low) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 10,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Khuyên dùng',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Định dạng GGUF 4-bit • Tối ưu CPU thiết bị di động',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Small state badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: state.isModelDownloaded
                          ? AppColors.success.withValues(alpha: 0.12)
                          : (state.isDownloadingModel
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.isModelDownloaded
                          ? 'Đã tải'
                          : (state.isDownloadingModel
                              ? 'Đang tải'
                              : (state.hasPartialDownload ? 'Tạm dừng' : 'Chưa tải')),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: state.isModelDownloaded
                            ? AppColors.success
                            : (state.isDownloadingModel
                                ? AppColors.primary
                                : (state.hasPartialDownload ? AppColors.warning : Colors.grey)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 3-Pillar Specifications Ribbon
              Row(
                children: [
                  Expanded(
                    child: _buildSpecItem(
                      Icons.bolt_rounded,
                      '0ms Trễ',
                      'Offline 100%',
                      AppColors.primary,
                      isDark,
                    ),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildSpecItem(
                      Icons.sd_storage_rounded,
                      '~350 MB',
                      'Dung lượng nhẹ',
                      AppColors.secondary,
                      isDark,
                    ),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildSpecItem(
                      Icons.shield_outlined,
                      '100% Riêng tư',
                      'Không rời máy',
                      AppColors.success,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Action / Progress State Area
        if (state.isDownloadingModel) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang tải mô hình về máy (${(state.downloadProgress * 100).toInt()}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => cubit.pauseOrCancelModelDownload(),
                      child: const Text('Tạm dừng', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.downloadProgress > 0 ? state.downloadProgress : null,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.downloadStatusText.isNotEmpty
                      ? state.downloadStatusText
                      : 'Đang tải gói dữ liệu Qwen GGUF (~360MB)...',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ] else if (state.isModelDownloaded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mô hình đã sẵn sàng hoạt động',
                        style: AppTypography.label.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Đã lưu an toàn trong máy • Luyện nói không cần Internet',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa mô hình giải phóng dung lượng',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDeleteModel(context, cubit),
                ),
              ],
            ),
          ),
        ] else if (state.hasPartialDownload) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang tạm dừng: ${state.partialDownloadedMb} MB (~${(state.downloadProgress * 100).toInt()}%)',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.downloadProgress > 0 ? state.downloadProgress : null,
                    minHeight: 6,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => cubit.startModelDownload(),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text('Tiếp tục tải (${state.partialDownloadedMb} MB)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _confirmDeleteModel(context, cubit),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Xóa tải lại', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: () => cubit.startModelDownload(),
            icon: const Icon(Icons.cloud_download_rounded, size: 20),
            label: const Text(
              'Tải Mô Hình On-Device ngay (~350MB)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Chỉ cần tải 1 lần qua Wi-Fi • Sử dụng trọn đời ngoại tuyến không tốn dung lượng 4G.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 9.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteModel(BuildContext context, SettingsCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa mô hình On-Device?'),
        content: const Text(
          'Mô hình sẽ bị xóa khỏi máy. Bạn sẽ cần tải lại (~350MB) nếu muốn sử dụng chế độ offline sau này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.deleteModel();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaSettings(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    final isConnected = state.connectionStatus == ConnectionStatus.connected;
    final isChecking = state.connectionStatus == ConnectionStatus.checking;
    final isFailed = state.connectionStatus == ConnectionStatus.failed;

    return Column(
      key: const ValueKey('ollama_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ollama Host URL Input
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ Host Ollama URL',
            hintText: 'http://10.0.2.2:11434 (Emulator) hoặc http://127.0.0.1:11434',
            prefixIcon: const Icon(Icons.link_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) {
            cubit.updateBaseUrl(val);
            cubit.testConnection();
          },
        ),
        const SizedBox(height: 12),

        // Model LLM Input
        TextField(
          controller: _modelController,
          decoration: InputDecoration(
            labelText: 'Tên Model LLM',
            hintText: 'qwen2.5:3b',
            prefixIcon: const Icon(Icons.memory_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) {
            cubit.updateModel(val);
            cubit.testConnection();
          },
        ),
        const SizedBox(height: 12),

        // Expandable Real Models Recommendation & Compatibility Center
        _buildExpandableModelRecommendations(context, state, cubit, isDark),
        const SizedBox(height: 14),

        // Real-Time Feedback Banner (Displays actual error if connection failed)
        if (isFailed) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chưa kết nối được máy chủ Ollama',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.connectionError != null && state.connectionError!.isNotEmpty
                            ? state.connectionError!
                            : 'Hãy đảm bảo máy chủ Ollama đang chạy trên máy tính và chấp nhận kết nối từ di động.',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (isConnected) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã kết nối thành công với ${state.ollamaBaseUrl} (${state.modelName})',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Unified Action Button
        ElevatedButton.icon(
          onPressed: isChecking
              ? null
              : () {
                  cubit.updateBaseUrl(_urlController.text);
                  cubit.updateModel(_modelController.text);
                  cubit.testConnection();
                },
          icon: isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync_rounded, size: 18),
          label: Text(
            isChecking
                ? 'Đang kiểm tra kết nối...'
                : 'Lưu cấu hình & Kiểm tra kết nối',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceProfilingCard(DeviceProfile profile, bool isDark) {
    Color tierColor;
    String tierBadge;
    IconData tierIcon;

    switch (profile.tier) {
      case HardwareTier.high:
        tierColor = AppColors.success;
        tierBadge = 'Cấu hình Cao cấp';
        tierIcon = Icons.rocket_launch_rounded;
        break;
      case HardwareTier.low:
        tierColor = AppColors.warning;
        tierBadge = 'Cấu hình Tiết kiệm';
        tierIcon = Icons.info_outline_rounded;
        break;
      case HardwareTier.standard:
        tierColor = AppColors.primary;
        tierBadge = 'Tương thích Chuẩn';
        tierIcon = Icons.verified_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tierIcon, size: 16, color: tierColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${profile.deviceLabel} • ${profile.ramDisplay} RAM • ${profile.freeDiskDisplay} trống',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tierBadge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.recommendationDescription,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableModelRecommendations(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    final isExpanded = state.isSuggestedModelsExpanded;
    final isChecking = state.isCheckingDeviceCompatibility;
    final profile = state.deviceProfile;
    final availRamMb = profile?.availableRamMb ?? 2048.0;
    final freeDiskMb = profile?.freeDiskMb ?? 5120.0;

    // Use installed models from Ollama if available, otherwise full RealModelCatalog
    final List<RealModelSpec> modelsToDisplay = state.installedOllamaModels.isNotEmpty
        ? state.installedOllamaModels
            .map((name) => RealModelCatalog.findById(name))
            .toList()
        : RealModelCatalog.realModels;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Accordion trigger
          InkWell(
            onTap: () => cubit.toggleSuggestedModelsExpanded(),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Mô hình gợi ý & Đánh giá tương thích',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (state.installedOllamaModels.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${state.installedOllamaModels.length} model thật',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Đang chọn: ${state.modelName}',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Body
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action: Run Real Device Benchmark / Compatibility Check
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isChecking
                              ? null
                              : () => cubit.runDeviceHardwareCheck(),
                          icon: isChecking
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.speed_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                          label: Text(
                            isChecking
                                ? 'Đang kiểm tra phần cứng & quét model...'
                                : 'Kiểm tra máy hợp với model nào',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Real Check Summary Banner (if evaluated)
                  if (state.deviceCheckSummary != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.insights_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.deviceCheckSummary!,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    'Danh sách mô hình thực tế (Bấm để chọn):',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Render list of real models with compatibility evaluation
                  ...modelsToDisplay.map((spec) {
                    final suitability = spec.evaluate(availRamMb, freeDiskMb);
                    final isSelected =
                        state.modelName.toLowerCase() == spec.id.toLowerCase();
                    return _buildRealModelItem(
                      spec: spec,
                      suitability: suitability,
                      isSelected: isSelected,
                      onTap: () {
                        debugPrint('👉 [MODEL_SELECT] Đã chọn mô hình: ${spec.id} (${spec.displayName})');
                        _modelController.text = spec.id;
                        cubit.updateModel(spec.id);
                      },
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealModelItem({
    required RealModelSpec spec,
    required ModelSuitability suitability,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    Color suitabilityColor;
    String suitabilityLabel;

    switch (suitability) {
      case ModelSuitability.optimal:
        suitabilityColor = AppColors.success;
        suitabilityLabel = 'Rất mượt ⚡';
        break;
      case ModelSuitability.compatible:
        suitabilityColor = AppColors.primary;
        suitabilityLabel = 'Tương thích ✓';
        break;
      case ModelSuitability.demanding:
        suitabilityColor = AppColors.warning;
        suitabilityLabel = 'Nặng ⚠️';
        break;
      case ModelSuitability.insufficient:
        suitabilityColor = AppColors.error;
        suitabilityLabel = 'Thiếu RAM ✕';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            spec.displayName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 12.5,
                              color: isSelected ? AppColors.primary : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spec.parameterSize,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${spec.bestFor} • Cần ${spec.ramRequirementDisplay} (${spec.storageRequirementDisplay})',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: suitabilityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suitabilityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: suitabilityColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioSettingsCard(
    BuildContext context,
    SettingsState state,
    SettingsCubit cubit,
    bool isDark,
  ) {
    final speedLabel = state.speechRate < 0.45
        ? 'Chậm'
        : (state.speechRate <= 0.6 ? 'Chuẩn (Khuyên dùng)' : 'Nhanh');
    final isFemale = state.voiceGender == 'female';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Active Voice Persona Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giọng đọc & Phát âm',
                      style: AppTypography.heading3,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${isFemale ? "👩 Nữ" : "👨 Nam"} • ${state.speechRate.toStringAsFixed(1)}x',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Interactive Audio Sample Preview Banner
            InkWell(
              onTap: () => cubit.testVoicePlayback(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nghe thử giọng mẫu (${state.currentLanguage.name})',
                            style: AppTypography.label.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bấm để kiểm tra âm điệu và phát âm AI',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Phát âm',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section: Gender Persona
            Text(
              'Nhân vật giọng đọc AI (Voice Persona):',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildGenderChoice(
                      context,
                      title: 'Giọng Nữ',
                      subtitle: 'Trong trẻo, tự nhiên',
                      emoji: '👩',
                      isSelected: isFemale,
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
                      isSelected: !isFemale,
                      onTap: () => cubit.updateVoiceGender('male'),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section: Speech Rate with Header and Value Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tốc độ đọc hội thoại:',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.speechRate.toStringAsFixed(2)}x • $speedLabel',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Preset Buttons for 1-Tap Speed Tuning
            Row(
              children: [
                _buildSpeedPresetChip(
                  label: '0.35x Chậm',
                  targetValue: 0.35,
                  currentValue: state.speechRate,
                  onSelect: (val) => cubit.updateSpeechRate(val),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildSpeedPresetChip(
                  label: '0.50x Chuẩn',
                  targetValue: 0.5,
                  currentValue: state.speechRate,
                  onSelect: (val) => cubit.updateSpeechRate(val),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildSpeedPresetChip(
                  label: '0.75x Nhanh',
                  targetValue: 0.75,
                  currentValue: state.speechRate,
                  onSelect: (val) => cubit.updateSpeechRate(val),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildSpeedPresetChip(
                  label: '1.0x Tối đa',
                  targetValue: 1.0,
                  currentValue: state.speechRate,
                  onSelect: (val) => cubit.updateSpeechRate(val),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fine-Tuning Slider with Custom Theme
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16,
                ),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: state.speechRate.clamp(0.2, 1.0),
                min: 0.2,
                max: 1.0,
                divisions: 16,
                onChanged: (val) => cubit.updateSpeechRate(val),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.2x (Rất chậm)',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  Text(
                    '1.0x (Nhanh bản xứ)',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedPresetChip({
    required String label,
    required double targetValue,
    required double currentValue,
    required ValueChanged<double> onSelect,
    required bool isDark,
  }) {
    final isSelected = (currentValue - targetValue).abs() < 0.06;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(targetValue),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.08))
        : (isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : null,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.85)
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Always maintain a 16px slot so text width never changes between active/inactive
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 16,
              ),
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
    final current = state.currentLanguage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Active Language Indicator Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ngôn ngữ mục tiêu',
                      style: AppTypography.heading3,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        current.flagEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        current.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Compact 2-Column Responsive Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: LanguageRegistry.supportedLanguages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.35,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final profile = LanguageRegistry.supportedLanguages[index];
                final isSelected = profile.code == current.code;

                return InkWell(
                  onTap: () => cubit.selectLanguage(profile),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : AppColors.primary.withValues(alpha: 0.08))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Flag avatar container
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            profile.flagEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Name & Native Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.name,
                                style: AppTypography.label.copyWith(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white
                                          : AppColors.primary)
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                profile.nativeName,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10.5,
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.85)
                                      : (isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Selection Checkmark
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
