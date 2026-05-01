import 'package:get_it/get_it.dart';
import '../services/i_model_service.dart';
import '../services/i_todo_repository.dart';
import '../services/model_service.dart';
import '../services/todo_repository.dart';
import '../../presentation/bloc/cubits/todo_cubit.dart';

final GetIt serviceLocator = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    await initServices();
    initBlocs();
  }

  static Future<void> initServices() async {
    serviceLocator.registerLazySingleton<IModelService>(
      () => ModelService(),
    );
    serviceLocator.registerLazySingleton<ITodoRepository>(
      () => TodoRepository(),
    );
  }

  static void initBlocs() {
    serviceLocator.registerFactory<TodoCubit>(
      () => TodoCubit(serviceLocator<ITodoRepository>()),
    );
  }
}
