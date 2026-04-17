import 'package:flutter/material.dart';
import 'package:gemma_local/core/di/di_container.dart';
import 'package:gemma_local/core/services/i_model_service.dart';
import 'package:gemma_local/core/utilities/constants/app_constants.dart';
import 'package:gemma_local/presentation/gemma_local_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await ServiceLocator.init();

  // Get ModelService instance and initialize with token and model URL
  final modelService = serviceLocator<IModelService>();
  await modelService.init(AppConstants.hfToken, AppConstants.modelUrl);

  runApp(const GemmaLocalApp());
}
