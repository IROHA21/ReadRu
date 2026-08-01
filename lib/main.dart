import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/ads/presentation/interstitial_ad_manager.dart';
import 'package:read_ru/features/library/presentation/screens/library_list_screen.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:read_ru/features/purchases/presentation/remove_ads_manager.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

// Held at the app root (rather than some specific screen's BuildContext)
// so the startup offline check - which fires before any screen is
// necessarily settled (onboarding vs library) - has somewhere to show a
// SnackBar regardless of which one ends up on screen first.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  // Must run before anything touches platform channels (ad SDKs, IAP) -
  // runApp() normally does this implicitly, but _initializeAds() below is
  // fired before runApp() so it needs the binding ready explicitly first.
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  // Fire-and-forget: don't block first frame on ad SDK init/prefetch, or
  // on the one-time store restore-purchases check.
  unawaited(_initializeAds());
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_warnIfOfflineAtStartup()));
}

// Skips loading ads at all once Remove Ads is confirmed purchased.
Future<void> _initializeAds() async {
  await getIt<RemoveAdsManager>().initialize();
  if (getIt<RemoveAdsManager>().adsRemoved) return;
  await getIt<InterstitialAdManager>().initialize();
  await getIt<InterstitialAdManager>().load();
}

// Same offline warning the reader shows again each time a book is opened
// (reader_view.dart's _warnIfOffline) - this one covers the moment the app
// itself launches, before any book has been touched.
Future<void> _warnIfOfflineAtStartup() async {
  final results = await Connectivity().checkConnectivity();
  if (results.hasConnectivity) return;
  final context = scaffoldMessengerKey.currentContext;
  if (context == null || !context.mounted) return;
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.offlineTranslationWarning)),
  );
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
                scaffoldMessengerKey: scaffoldMessengerKey,
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
                themeMode: switch (settings.themeMode) {
                  AppThemeMode.system => ThemeMode.system,
                  AppThemeMode.light => ThemeMode.light,
                  AppThemeMode.dark => ThemeMode.dark,
                },
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
