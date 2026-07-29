import 'package:get_it/get_it.dart';
import 'package:read_ru/features/ads/presentation/interstitial_ad_manager.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/data/datasources/library_storage_data_source.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/repositories/library_repository_impl.dart';
import 'package:read_ru/features/library/presentation/cubit/library_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_cubit.dart';
import 'package:read_ru/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:read_ru/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:read_ru/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:read_ru/features/word_bucket/data/datasources/word_bucket_local_data_source.dart';
import 'package:read_ru/features/word_bucket/data/repositories/word_bucket_repository_impl.dart';
import 'package:read_ru/features/word_bucket/domain/repositories/word_bucket_repository.dart';
import 'package:read_ru/features/word_bucket/presentation/cubit/word_bucket_cubit.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<LibraryLocalDataSource>(() => LibraryLocalDataSource());


  //getIt.registerLazySingleton<LibraryRepository>(() => LibraryRepositoryImpl(getIt<LibraryLocalDataSource>()),);


  getIt.registerFactory<LibraryCubit>(() =>  LibraryCubit(getIt<LibraryRepository>()));

  getIt.registerLazySingleton<LibraryStorageDataSource>(() => LibraryStorageDataSource());

  getIt.registerLazySingleton<LibraryRepository>(() => LibraryRepositoryImpl(
      getIt<LibraryLocalDataSource>(), getIt<LibraryStorageDataSource>(), getIt<OnboardingLocalDataSource>()),);


  // Settings - one long-lived instance shared by SettingsScreen, the reader
  // (initial font/translation defaults) and main.dart (theming).
  getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSource());
  getIt.registerLazySingleton<SettingsCubit>(() => SettingsCubit(getIt<SettingsLocalDataSource>()));

  // Onboarding - singleton so main.dart's completion gate and the flow's
  // own screens read/write the exact same state.
  getIt.registerLazySingleton<OnboardingLocalDataSource>(() => OnboardingLocalDataSource());
  getIt.registerLazySingleton<OnboardingCubit>(() => OnboardingCubit(getIt<OnboardingLocalDataSource>()));

  // Word bucket
  getIt.registerLazySingleton<WordBucketLocalDataSource>(() => WordBucketLocalDataSource());
  getIt.registerLazySingleton<WordBucketRepository>(
      () => WordBucketRepositoryImpl(getIt<WordBucketLocalDataSource>()));
  getIt.registerFactory<WordBucketCubit>(() => WordBucketCubit(getIt<WordBucketRepository>()));

  getIt.registerFactory<LibraryListCubit>(
      () => LibraryListCubit(getIt<LibraryRepository>(), getIt<WordBucketRepository>()));

  // Ads - one long-lived interstitial slot, network picked once at
  // startup (Yandex for CIS, AdMob elsewhere) and reused for every
  // "before read" prompt.
  getIt.registerLazySingleton<InterstitialAdManager>(() => InterstitialAdManager());
}
