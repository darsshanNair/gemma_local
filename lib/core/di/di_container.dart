import 'package:get_it/get_it.dart';
import '../services/i_model_service.dart';
import '../services/model_service.dart';

final GetIt serviceLocator = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    await initServices();
  }

  static Future<void> initServices() async {
    serviceLocator.registerLazySingleton<IModelService>(
      () => ModelService(),
    );
  }
}