import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/services/i_model_service.dart';

class ModelService implements IModelService {
  late final InferenceModel _model;

  @override
  Future<void> init(String hfToken, String url) async {
    await FlutterGemma.initialize(huggingFaceToken: hfToken);
    await FlutterGemma.installModel(
      modelType: ModelType.qwen,
    ).fromNetwork(url).install();
  }

  @override
  Future<InferenceModel> createAndSetupModel(
    int maxTokens,
    String instructions,
  ) async {
    final backend = kDebugMode ? PreferredBackend.cpu : PreferredBackend.gpu;

    _model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend,
    );

    // Pass instructions to the model to shape base behaviour and context
    _model.createChat(systemInstruction: instructions);

    return _model;
  }

  @override
  Future<void> closeModel() async {
    await _model.close();
  }
}
