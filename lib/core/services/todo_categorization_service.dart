import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/models/categorization_result.dart';
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

    final chat = await _model.createChat(
      systemInstruction: AppConstants.systemInstruction,
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.required,
      tools: [
        _buildGetByCategoryTool(targetCategories),
        _buildUpdateTodoCategoryTool(targetCategories),
      ],
    );

    final todosList = generalTodos
        .map((t) => '  ID: ${t.id} — "${t.title}"')
        .join('\n');
    final categoriesList =
        targetCategories.map((c) => '  - ${c.name} (${c.displayName})').join('\n');

    final prompt = '''
Please categorize the following todos that are currently under "General".
Available categories (other than General):
$categoriesList

Todos to categorize:
$todosList

Use the getByCategory tool if you need to see what's already in each category.
Use the updateTodoCategory tool to assign a category to each todo.
Do not categorize todos that clearly belong in General. Use your best judgment.
''';

    final categorized = <TodoCategory, int>{};
    var skipped = 0;

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    await for (final response in chat.generateChatResponseAsync()) {
      if (response is FunctionCallResponse) {
        final result =
            await _handleToolCall(response, chat, categorized);
        if (result == true) {
          // categorized
        } else if (result == false) {
          skipped++;
        }
      } else if (response is ParallelFunctionCallResponse) {
        for (final call in response.calls) {
          final result =
              await _handleToolCall(call, chat, categorized);
          if (result == false) {
            skipped++;
          }
        }
      }
    }

    return CategorizationResult(
      categorized: Map.unmodifiable(categorized),
      skipped: skipped,
      totalProcessed: categorized.values.fold(0, (a, b) => a + b) + skipped,
    );
  }

  Future<bool?> _handleToolCall(
    FunctionCallResponse call,
    InferenceChat chat,
    Map<TodoCategory, int> categorized,
  ) async {
    if (call.name == 'getByCategory') {
      final catName = call.args['category'] as String?;
      if (catName == null) {
        await _sendToolError(chat, 'getByCategory', 'Missing category parameter');
        return null;
      }
      final category = _parseCategory(catName);
      if (category == null) {
        await _sendToolError(chat, 'getByCategory', 'Invalid category: $catName');
        return null;
      }
      final todos = _repository.getByCategory(category);
      final result = {
        'todos': todos.map((t) => {'id': t.id, 'title': t.title}).toList(),
      };
      await chat.addQueryChunk(Message.toolResponse(
        toolName: 'getByCategory',
        response: result,
      ));
      return null;
    }

    if (call.name == 'updateTodoCategory') {
      final id = call.args['id'] as String?;
      final catName = call.args['category'] as String?;
      if (id == null || catName == null) {
        await _sendToolError(
            chat, 'updateTodoCategory', 'Missing id or category parameter');
        return false;
      }
      final category = _parseCategory(catName);
      if (category == null) {
        await _sendToolError(
            chat, 'updateTodoCategory', 'Invalid category: $catName');
        return false;
      }

      final existing = _repository.getById(id);
      if (existing == null) {
        await _sendToolError(
            chat, 'updateTodoCategory', 'Todo not found: $id');
        return false;
      }

      _repository.update(id, existing.copyWith(category: category));
      categorized[category] = (categorized[category] ?? 0) + 1;

      await chat.addQueryChunk(Message.toolResponse(
        toolName: 'updateTodoCategory',
        response: {'success': true},
      ));
      return true;
    }

    await _sendToolError(chat, call.name, 'Unknown tool: ${call.name}');
    return false;
  }

  Future<void> _sendToolError(
      InferenceChat chat, String toolName, String error) async {
    await chat.addQueryChunk(Message.toolResponse(
      toolName: toolName,
      response: {'success': false, 'error': error},
    ));
  }

  TodoCategory? _parseCategory(String name) {
    return TodoCategory.values.cast<TodoCategory?>().firstWhere(
          (c) => c?.name == name,
          orElse: () => null,
        );
  }

  Tool _buildGetByCategoryTool(List<TodoCategory> targetCategories) {
    final categoryNames = targetCategories.map((c) => c.name).toList();
    return Tool(
      name: 'getByCategory',
      description:
          'Get todos from a specific category. Call this if you need to see what is already in a category before moving items there.',
      parameters: {
        'type': 'object',
        'properties': {
          'category': {
            'type': 'string',
            'enum': categoryNames,
            'description': 'The category name to get todos from',
          },
        },
        'required': ['category'],
      },
    );
  }

  Tool _buildUpdateTodoCategoryTool(List<TodoCategory> targetCategories) {
    final categoryNames = targetCategories.map((c) => c.name).toList();
    return Tool(
      name: 'updateTodoCategory',
      description:
          'Update the category of a todo item. Use this to move a todo from General to a more specific category.',
      parameters: {
        'type': 'object',
        'properties': {
          'id': {
            'type': 'string',
            'description': 'The ID of the todo to update',
          },
          'category': {
            'type': 'string',
            'enum': categoryNames,
            'description': 'The new category to assign to the todo',
          },
        },
        'required': ['id', 'category'],
      },
    );
  }
}
