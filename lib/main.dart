import 'package:flutter/material.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/presentation/screens/library_list_screen.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'read_ru',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent)),
      home: const LibraryListScreen(),
    );
  }
}
