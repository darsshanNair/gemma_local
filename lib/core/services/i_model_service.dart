import 'package:flutter_gemma/flutter_gemma.dart';

abstract class IModelService {
  Future<void> init(String hfToken, String url);
  Future<InferenceModel> createAndSetupModel(
    int maxTokens,
    String instructions,
  );
  Future<void> closeModel();
}
