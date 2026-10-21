import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/di/injection.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/language/domain/entities/language_profile.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_cubit.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_state.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  LanguageProfile _sourceLang = LanguageRegistry.english;
  LanguageProfile _targetLang = LanguageRegistry.vietnamese;
  bool _isDictating = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
    });
  }

  Future<void> _toggleDictation() async {
    final audioRepo = sl<AudioRepository>();
    if (_isDictating) {
      await audioRepo.stopListening();
      setState(() => _isDictating = false);
    } else {
      setState(() => _isDictating = true);
      audioRepo.startListening(locale: _sourceLang.sttLocale).listen((words) {
        setState(() {
          _inputController.text = words;
        });
      }, onDone: () {
        setState(() => _isDictating = false);
      }, onError: (_) {
        setState(() => _isDictating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dịch Thuật & Ngữ Pháp', style: AppTypography.heading2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Language Selector Bar with Swap button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLanguagePicker(_sourceLang, (p) => setState(() => _sourceLang = p)),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                    onPressed: _swapLanguages,
                  ),
                  _buildLanguagePicker(_targetLang, (p) => setState(() => _targetLang = p)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ vựng, câu hoặc đoạn văn...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextMuted),
                    ),
                    style: AppTypography.bodyLarge,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      IconButton(
                        tooltip: _isDictating ? 'Dừng ghi âm' : 'Nói để nhập văn bản',
                        icon: Icon(
                          _isDictating ? Icons.mic : Icons.mic_none_rounded,
                          color: _isDictating ? AppColors.micRecording : AppColors.primary,
                        ),
                        onPressed: _toggleDictation,
                      ),
                      IconButton(
                        tooltip: 'Phát âm câu gốc',
                        icon: const Icon(Icons.volume_up_outlined, color: AppColors.darkTextSecondary),
                        onPressed: () {
                          if (_inputController.text.isNotEmpty) {
                            sl<AudioRepository>().speak(
                              _inputController.text,
                              locale: _sourceLang.ttsLocale,
                            );
                          }
                        },
                      ),
                      if (_inputController.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _inputController.clear();
                            context.read<TranslationCubit>().clear();
                          },
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.translate_rounded, size: 18),
                        label: const Text('Dịch'),
                        onPressed: () {
                          final text = _inputController.text.trim();
                          if (text.isNotEmpty) {
                            context.read<TranslationCubit>().translate(
                                  text: text,
                                  sourceLang: _sourceLang.name,
                                  targetLang: _targetLang.name,
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Translation Output
            BlocBuilder<TranslationCubit, TranslationState>(
              builder: (context, state) {
                if (state is TranslationLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (state is TranslationError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lỗi dịch: ${state.message}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  );
                }

                if (state is TranslationSuccess) {
                  final res = state.result;
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                res.translatedText,
                                style: AppTypography.heading2.copyWith(color: AppColors.primaryLight),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Bấm loa để nghe phát âm',
                              icon: const Icon(Icons.volume_up_rounded, color: AppColors.secondary),
                              onPressed: () {
                                sl<AudioRepository>().speak(
                                  res.translatedText,
                                  locale: _targetLang.ttsLocale,
                                );
                              },
                            ),
                          ],
                        ),

                        // Phonetic & Part of speech tags
                        if (res.phonetic.isNotEmpty || res.partOfSpeech.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (res.phonetic.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    res.phonetic,
                                    style: AppTypography.label.copyWith(color: AppColors.secondary),
                                  ),
                                ),
                              if (res.partOfSpeech.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    res.partOfSpeech,
                                    style: AppTypography.label.copyWith(color: AppColors.accent),
                                  ),
                                ),
                            ],
                          ),
                        ],

                        // Grammar explanation
                        if (res.explanation.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text('Giải thích & Ngữ cảnh:', style: AppTypography.label),
                          const SizedBox(height: 4),
                          Text(
                            res.explanation,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],

                        // Example sentences
                        if (res.examples.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text('Ví dụ minh họa:', style: AppTypography.label),
                          const SizedBox(height: 6),
                          ...res.examples.map(
                            (eg) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.secondary)),
                                  Expanded(
                                    child: Text(eg, style: AppTypography.bodySmall),
                                  ),
                                  InkWell(
                                    child: const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.darkTextMuted),
                                    onTap: () => sl<AudioRepository>().speak(eg, locale: _targetLang.ttsLocale),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker(
    LanguageProfile current,
    ValueChanged<LanguageProfile> onChanged,
  ) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<LanguageProfile>(
        value: current,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        items: LanguageRegistry.supportedLanguages.map((profile) {
          return DropdownMenuItem<LanguageProfile>(
            value: profile,
            child: Row(
              children: [
                Text(profile.flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(profile.name, style: AppTypography.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (newVal) {
          if (newVal != null) onChanged(newVal);
        },
      ),
    );
  }
}
