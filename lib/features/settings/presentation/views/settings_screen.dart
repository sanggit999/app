import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/di/injection.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
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
            title: Text('Cấu hình Local LLM & Voice', style: AppTypography.heading2),
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

    switch (state.connectionStatus) {
      case ConnectionStatus.connected:
        statusColor = AppColors.success;
        statusText = 'Đã kết nối thành công với Local LLM';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ConnectionStatus.checking:
        statusColor = AppColors.accent;
        statusText = 'Đang kiểm tra kết nối...';
        statusIcon = Icons.sync_rounded;
        break;
      case ConnectionStatus.failed:
      default:
        statusColor = AppColors.error;
        statusText = 'Chưa kết nối. Hãy khởi động Ollama trên máy.';
        statusIcon = Icons.error_outline_rounded;
        break;
    }

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
                  state.ollamaBaseUrl,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
            Text('Mô hình Local AI (Ollama)', style: AppTypography.heading3),
            const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  Widget _buildQuickModelChip(String model, String subtitle, SettingsCubit cubit) {
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
                Text('Giọng Đọc & Phát Âm (TTS)', style: AppTypography.heading3),
                IconButton(
                  tooltip: 'Nghe thử giọng mẫu',
                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.secondary),
                  onPressed: () {
                    sl<AudioRepository>().speak(
                      'Hello! I am your AI English tutor. Nice to meet you!',
                      locale: state.currentLanguage.ttsLocale,
                      rate: state.speechRate,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tốc độ đọc: ${state.speechRate.toStringAsFixed(1)}x (${state.speechRate < 0.5 ? "Chậm" : state.speechRate == 0.5 ? "Chuẩn" : "Nhanh"})',
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
                leading: Text(profile.flagEmoji, style: const TextStyle(fontSize: 24)),
                title: Text(profile.name, style: AppTypography.label),
                subtitle: Text(profile.nativeName, style: AppTypography.bodySmall),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
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
                const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
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
