import 'package:flutter_gemma/flutter_gemma.dart';

class AppConstants {
  static const String hfToken = String.fromEnvironment('HF_TOKEN');
  static const String modelUrl =
      "https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task";
  static const String systemInstruction = "You are a helpful assistant.";

  static const String categorizationInstruction = '''
You are a categorization tool. Your ONLY job is to call the updateTodoCategory function for each todo you are given.

Rules:
- You MUST call updateTodoCategory for every todo in the list
- Choose the best matching category from the enum values
- Do NOT respond with text — only function calls
- Do NOT call getByCategory — the todos are already provided to you
- Process ALL todos before finishing
''';
  static const int maxTokens = 20000;
  static const ModelType modelType = ModelType.qwen;
}
