import 'package:flutter/material.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/features/settings/presentation/views/settings_screen.dart';
import 'package:echo_lingua/features/translation/presentation/views/translation_screen.dart';
import 'package:echo_lingua/features/voice_chat/presentation/views/voice_chat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VoiceChatScreen(),
    TranslationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: isKeyboardOpen ? 0.0 : 80.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.18),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.record_voice_over_outlined),
                selectedIcon: Icon(
                  Icons.record_voice_over,
                  color: AppColors.primary,
                ),
                label: 'Luyện Nói',
              ),
              NavigationDestination(
                icon: Icon(Icons.translate_outlined),
                selectedIcon: Icon(Icons.translate, color: AppColors.primary),
                label: 'Dịch Thuật',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                label: 'Cài Đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
