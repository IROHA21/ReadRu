import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/presentation/screens/library_list_screen.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, ReaderSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'RuRead',
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
            home: const LibraryListScreen(),
          );
        },
      ),
    );
  }
}
