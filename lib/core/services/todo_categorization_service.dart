import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/models/categorization_result.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/models/todo_category.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/core/utilities/constants/app_constants.dart';

class TodoCategorizationService {
  final InferenceModel _model;
  final ITodoRepository _repository;

  TodoCategorizationService(this._model, this._repository);

  Future<CategorizationResult> categorizeGeneralTodos() async {
    final generalTodos = _repository.getByCategory(TodoCategory.general);
    if (generalTodos.isEmpty) {
      return const CategorizationResult(
        categorized: {},
        skipped: 0,
        totalProcessed: 0,
      );
    }

    final targetCategories = TodoCategory.values
        .where((c) => c != TodoCategory.general)
        .toList();

    final categorized = <TodoCategory, int>{};
    var skipped = 0;

    for (final todo in generalTodos) {
      final result = await _categorizeSingleTodo(todo, targetCategories);
      if (result != null) {
        categorized[result] = (categorized[result] ?? 0) + 1;
      } else {
        skipped++;
      }
    }

    return CategorizationResult(
      categorized: Map.unmodifiable(categorized),
      skipped: skipped,
      totalProcessed: categorized.values.fold(0, (a, b) => a + b) + skipped,
    );
  }

  Future<TodoCategory?> _categorizeSingleTodo(
    Todo todo,
    List<TodoCategory> targetCategories,
  ) async {
    final chat = await _model.createChat(
      systemInstruction: AppConstants.categorizationInstruction,
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.required,
      tools: [_buildUpdateTodoCategoryTool(targetCategories)],
    );

    final categoriesList = targetCategories.map((c) => c.name).join(', ');

    final prompt =
        '''
          Call updateTodoCategory for this todo.

          Categories: $categoriesList

          Todo:
          {"todoId": "${todo.id}", "title": "${todo.title}"}
        ''';

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    const maxTurns = 2;
    for (var turn = 0; turn < maxTurns; turn++) {
      final pendingCalls = <FunctionCallResponse>[];

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is FunctionCallResponse) {
          pendingCalls.add(response);
        } else if (response is ParallelFunctionCallResponse) {
          pendingCalls.addAll(response.calls);
        }
      }

      if (pendingCalls.isEmpty) break;

      for (final call in pendingCalls) {
        if (call.name == 'updateTodoCategory') {
          final idArg =
              call.args['todoId'] as String? ?? call.args['id'] as String?;
          final catName = call.args['category'] as String?;

          final category = catName != null ? _parseCategory(catName) : null;
          if (category == null || idArg == null) {
            await _sendToolError(chat, 'updateTodoCategory', 'Invalid args');
            continue;
          }

          // UUID match first, title fallback
          var existing = _repository.getById(idArg);
          existing ??= _repository.getAll().cast<Todo?>().firstWhere(
            (t) => t?.title.toLowerCase() == idArg.toLowerCase(),
            orElse: () => null,
          );

          if (existing == null) {
            await _sendToolError(
              chat,
              'updateTodoCategory',
              'Not found: $idArg',
            );
            continue;
          }

          _repository.update(
            existing.id,
            existing.copyWith(category: category),
          );

          await chat.addQueryChunk(
            Message.toolResponse(
              toolName: 'updateTodoCategory',
              response: {'success': true},
            ),
          );

          return category;
        }
      }
    }

    return null;
  }

  Future<void> _sendToolError(
    InferenceChat chat,
    String toolName,
    String error,
  ) async {
    await chat.addQueryChunk(
      Message.toolResponse(
        toolName: toolName,
        response: {'success': false, 'error': error},
      ),
    );
  }

  TodoCategory? _parseCategory(String name) {
    return TodoCategory.values.cast<TodoCategory?>().firstWhere(
      (c) => c?.name == name,
      orElse: () => null,
    );
  }

  Tool _buildUpdateTodoCategoryTool(List<TodoCategory> targetCategories) {
    final categoryNames = targetCategories.map((c) => c.name).toList();
    return Tool(
      name: 'updateTodoCategory',
      description: 'Update the category of a todo item.',
      parameters: {
        'type': 'object',
        'properties': {
          'todoId': {
            'type': 'string',
            'description': 'The todoId of the todo to update (the UUID string)',
          },
          'category': {
            'type': 'string',
            'enum': categoryNames,
            'description': 'The new category to assign',
          },
        },
        'required': ['todoId', 'category'],
      },
    );
  }
}
