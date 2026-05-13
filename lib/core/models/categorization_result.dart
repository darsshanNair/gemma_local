import 'package:gemma_local/core/models/todo_category.dart';

class CategorizationResult {
  final Map<TodoCategory, int> categorized;
  final int skipped;
  final int totalProcessed;

  const CategorizationResult({
    required this.categorized,
    required this.skipped,
    required this.totalProcessed,
  });
}
