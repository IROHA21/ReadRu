import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/presentation/screens/library_list_screen.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<SettingsCubit>()),
        BlocProvider.value(value: getIt<OnboardingCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, ReaderSettings>(
        builder: (context, settings) {
          return BlocBuilder<OnboardingCubit, OnboardingSettings>(
            builder: (context, onboarding) {
              return MaterialApp(
                title: 'AnyRead',
                theme: ThemeData(
                  brightness: Brightness.light,
                  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.accent),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.dark.accent,
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: AppColors.dark.background,
                ),
                themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                locale: Locale(onboarding.spokenLanguage?.bcpCode ?? 'en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: onboarding.onboardingComplete
                    ? const LibraryListScreen()
                    : OnboardingScreen(onComplete: () {}),
              );
            },
          );
        },
      ),
    );
  }
}
