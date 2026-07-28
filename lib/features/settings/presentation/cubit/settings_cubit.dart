import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';

// Long-lived, app-wide: registered as a singleton so the same instance backs
// both the SettingsScreen and whatever reads it for theming/reader defaults.
// State is the settings themselves (no separate loading state) - starts at
// ReaderSettings.defaults so the UI never blocks, then updates once the
// persisted value (if any) has loaded.
class SettingsCubit extends Cubit<ReaderSettings> {
  SettingsCubit(this._dataSource) : super(ReaderSettings.defaults) {
    _load();
  }

  final SettingsLocalDataSource _dataSource;

  Future<void> _load() async {
    final loaded = await _dataSource.getSettings();
    if (!isClosed) emit(loaded);
  }

  Future<void> _update(ReaderSettings Function(ReaderSettings) transform) async {
    final updated = transform(state);
    emit(updated);
    await _dataSource.saveSettings(updated);
  }

  Future<void> setFontSize(double fontSize) => _update((s) => s.copyWith(fontSize: fontSize));

  Future<void> setFont(ReaderFont font) => _update((s) => s.copyWith(font: font));

  Future<void> setDarkMode(bool isDarkMode) => _update((s) => s.copyWith(isDarkMode: isDarkMode));

  Future<void> setHighlightEnabled(bool enabled) =>
      _update((s) => s.copyWith(highlightEnabled: enabled));

  Future<void> setHighlightColor(Color color) =>
      _update((s) => s.copyWith(highlightColor: color));

  Future<void> setTranslationFontSize(double size) =>
      _update((s) => s.copyWith(translationFontSize: size));

  Future<void> setTranslationColor(Color color) =>
      _update((s) => s.copyWith(translationColor: color));

  Future<void> setPageSwipeDirection(PageSwipeDirection direction) =>
      _update((s) => s.copyWith(pageSwipeDirection: direction));
}
