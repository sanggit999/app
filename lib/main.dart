import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/audio/domain/services/stt_service.dart';
import 'features/home/presentation/views/main_navigation_screen.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/translation/presentation/cubit/translation_cubit.dart';
import 'features/voice_chat/presentation/cubit/voice_chat_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  // Warm-up STT service in background
  unawaited(sl<SttService>().initialize());

  runApp(const EchoLinguaApp());
}

class EchoLinguaApp extends StatelessWidget {
  const EchoLinguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>(),
        ),
        BlocProvider<VoiceChatCubit>(
          create: (_) => sl<VoiceChatCubit>(),
        ),
        BlocProvider<TranslationCubit>(
          create: (_) => sl<TranslationCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'EchoLingua AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Senior aesthetic: Sleek Slate Dark mode by default
        home: const MainNavigationScreen(),
      ),
    );
  }
}
