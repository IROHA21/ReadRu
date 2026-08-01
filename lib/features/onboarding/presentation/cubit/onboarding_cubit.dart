import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:read_ru/features/onboarding/domain/onboarding_settings.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';

/// Drives all 3 onboarding screens. State is the settings themselves (same
/// shape as SettingsCubit) - starts at defaults, then on first load
/// pre-selects a spoken language from the device locale if nothing's been
/// chosen yet, falling back to English when the device language isn't one
/// of the ones offered.
class OnboardingCubit extends Cubit<OnboardingSettings> {
  OnboardingCubit(this._dataSource) : super(OnboardingSettings.defaults) {
    _load();
  }

  final OnboardingLocalDataSource _dataSource;

  Future<void> _load() async {
    final loaded = await _dataSource.getSettings();
    if (isClosed) return;

    if (loaded.spokenLanguage == null) {
      final detected = translateLanguageFromCode(PlatformDispatcher.instance.locale.languageCode);
      final preselected =
          (detected != null && popularSpokenLanguages.contains(detected)) ? detected : TranslateLanguage.english;
      emit(loaded.copyWith(spokenLanguage: preselected));
    } else {
      emit(loaded);
    }
  }

  Future<void> _persist(OnboardingSettings updated) async {
    emit(updated);
    await _dataSource.saveSettings(updated);
  }

  Future<void> setSpokenLanguage(TranslateLanguage language) =>
      _persist(state.copyWith(spokenLanguage: language));

  Future<void> toggleBookLanguage(TranslateLanguage language) {
    final current = Set<TranslateLanguage>.from(state.bookLanguages);
    if (current.contains(language)) {
      current.remove(language);
    } else {
      current.add(language);
    }
    return _persist(state.copyWith(bookLanguages: current.toList()));
  }

  Future<void> completeOnboarding() => _persist(state.copyWith(onboardingComplete: true));
}
