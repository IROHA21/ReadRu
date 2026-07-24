import 'package:get_it/get_it.dart';
import 'package:read_ru/features/library/data/datasources/library_local_data_source.dart';
import 'package:read_ru/features/library/data/datasources/library_storage_data_source.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/library/data/repositories/library_repository_impl.dart';
import 'package:read_ru/features/library/presentation/cubit/library_cubit.dart';
import 'package:read_ru/features/library/presentation/cubit/library_list_cubit.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<LibraryLocalDataSource>(() => LibraryLocalDataSource());


  //getIt.registerLazySingleton<LibraryRepository>(() => LibraryRepositoryImpl(getIt<LibraryLocalDataSource>()),);


  getIt.registerFactory<LibraryCubit>(() =>  LibraryCubit(getIt<LibraryRepository>()));

  getIt.registerLazySingleton<LibraryStorageDataSource>(() => LibraryStorageDataSource());

  getIt.registerLazySingleton<LibraryRepository>(() => LibraryRepositoryImpl(getIt<LibraryLocalDataSource>(), getIt<LibraryStorageDataSource>()),);


  getIt.registerFactory<LibraryListCubit>(() => LibraryListCubit(getIt<LibraryRepository>()));
}