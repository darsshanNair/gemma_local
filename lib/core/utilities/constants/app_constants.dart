import 'package:flutter_gemma/flutter_gemma.dart';

class AppConstants {
  static const String hfToken = String.fromEnvironment('HF_TOKEN');
  static const String modelUrl =
      "https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task";
  static const String systemInstruction = "You are a helpful assistant.";
  static const int maxTokens = 1024;
  static const ModelType modelType = ModelType.qwen;
}
