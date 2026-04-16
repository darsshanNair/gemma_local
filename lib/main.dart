import 'package:flutter/material.dart';
import 'package:gemma_local/core/services/model_service.dart';
import 'package:gemma_local/core/utilities/constants/app_constants.dart';
import 'package:gemma_local/presentation/gemma_local_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ModelService modelService = ModelService();

  await modelService.init(AppConstants.hfToken, AppConstants.modelUrl);

  runApp(const GemmaLocalApp());
}
