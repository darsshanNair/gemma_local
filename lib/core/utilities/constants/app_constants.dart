import 'package:flutter_gemma/flutter_gemma.dart';

class AppConstants {
  static const String hfToken = String.fromEnvironment('HF_TOKEN');
  static const String modelUrl =
      "https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task";
  static const String systemInstruction = "You are a helpful assistant.";

  static const String categorizationInstruction = '''
You are a todo list assistant. You can help categorize tasks.

When asked to categorize todos:
1. Read each todo's title carefully
2. Assign it to the most appropriate category based on the task content
3. Only use the available categories provided to you
4. If you are unsure which category fits, leave it as General
5. Do not make up new categories
''';
  static const int maxTokens = 20000;
  static const ModelType modelType = ModelType.qwen;
}
