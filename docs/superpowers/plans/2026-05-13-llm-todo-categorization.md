# LLM Todo Categorization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Use the on-device LLM with function calling to categorize General todos into Work/Personal/Health/Finances.

**Architecture:** A `TodoCategorizationService` creates a dedicated `InferenceChat` with tools. The LLM calls `getByCategory` and `updateTodoCategory` tools. A second FAB on TodoScreen triggers the flow with a loading overlay and result dialog.

**Tech Stack:** Flutter, flutter_gemma (function calling), flutter_bloc

---

### Task 1: Create feature branch

- [ ] **Step 1: Create and switch to branch**

```bash
git checkout -b feature/llm-categorization
```

---

### Task 2: Register InferenceModel in DI container

**Files:**
- Modify: `lib/core/di/di_container.dart`
- Modify: `lib/main.dart`
- Modify: `lib/presentation/screens/chat_screen.dart`

The `TodoCategorizationService` needs access to the `InferenceModel` to create its own chat session. We'll register the model in GetIt after main.dart creates it.

- [ ] **Step 1: Add InferencModel registration in di_container.dart**

Read the file first, then add the import and registration variable:

After the existing `serviceLocator` declaration, add a registration for `InferenceModel`:

```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../services/i_model_service.dart';
import '../services/i_todo_repository.dart';
import '../services/model_service.dart';
import '../services/todo_repository.dart';

final GetIt serviceLocator = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    await initServices();
  }

  static Future<void> initServices() async {
    serviceLocator.registerLazySingleton<IModelService>(
      () => ModelService(),
    );
    serviceLocator.registerLazySingleton<ITodoRepository>(
      () => TodoRepository(),
    );
  }

  static void registerModel(InferenceModel model) {
    serviceLocator.registerSingleton<InferenceModel>(model);
  }
}
```

- [ ] **Step 2: Register model in main.dart after setup**

Read the file first. After `await modelService.init(...)` and `createAndSetupModel(...)`, register the returned model:

In `main.dart`, change:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  final modelService = serviceLocator<IModelService>();
  await modelService.init(AppConstants.hfToken, AppConstants.modelUrl);

  runApp(const GemmaLocalApp());
}
```

To:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ServiceLocator.init();

  final modelService = serviceLocator<IModelService>();
  await modelService.init(AppConstants.hfToken, AppConstants.modelUrl);
  final model = await modelService.createAndSetupModel(
    AppConstants.maxTokens,
    AppConstants.systemInstruction,
  );
  ServiceLocator.registerModel(model);

  runApp(const GemmaLocalApp());
}
```

- [ ] **Step 3: Update ChatScreen to use model from DI**

Read the file first. Change `_setupModel` to get the model from DI instead of calling `createAndSetupModel` directly.

Replace lines 49-70 in chat_screen.dart (`_setupModel` method):

```dart
  Future<void> _setupModel() async {
    try {
      setState(() => _statusText = 'Loading model...');

      _model = serviceLocator<InferenceModel>();

      _chat = await _model!.createChat(
        systemInstruction: AppConstants.systemInstruction,
      );

      setState(() {
        _isModelReady = true;
        _statusText = 'Ready';
      });
    } catch (e) {
      setState(() => _statusText = 'Error: $e');
    }
  }
```

- [ ] **Step 4: Run flutter analyze and commit**

```bash
fvm flutter analyze
```

```bash
git add lib/core/di/di_container.dart lib/main.dart lib/presentation/screens/chat_screen.dart
git commit -m "feat: register InferenceModel in DI for shared LLM access"
```

---

### Task 3: Update system instruction

**Files:**
- Modify: `lib/core/utilities/constants/app_constants.dart`

- [ ] **Step 1: Update systemInstruction**

Read the file first. Replace the current `systemInstruction`:

```dart
  static const String systemInstruction = '''
You are a todo list assistant. You can help categorize tasks.

When asked to categorize todos:
1. Read each todo's title carefully
2. Assign it to the most appropriate category based on the task content
3. Only use the available categories provided to you
4. If you are unsure which category fits, leave it as General
5. Do not make up new categories
''';
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/utilities/constants/app_constants.dart
git commit -m "feat: update system instruction for todo categorization"
```

---

### Task 4: Create CategorizationResult model

**Files:**
- Create: `lib/core/models/categorization_result.dart`

- [ ] **Step 1: Write the model**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/models/categorization_result.dart
git commit -m "feat: add CategorizationResult model"
```

---

### Task 5: Create TodoCategorizationService

**Files:**
- Create: `lib/core/services/todo_categorization_service.dart`

- [ ] **Step 1: Write the service**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

    try {
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is FunctionCallResponse) {
          final result =
              await _handleToolCall(response, chat, categorized);
          if (result == true) {
            // categorized
          } else {
            skipped++;
          }
        } else if (response is ParallelFunctionCallResponse) {
          for (final call in response.calls) {
            final result =
                await _handleToolCall(call, chat, categorized);
            if (result != true) {
              skipped++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Categorization error: $e');
    }

    return CategorizationResult(
      categorized: Map.unmodifiable(categorized),
      skipped: skipped,
      totalProcessed: generalTodos.length,
    );
  }

  Future<bool> _handleToolCall(
    FunctionCallResponse call,
    InferenceChat chat,
    Map<TodoCategory, int> categorized,
  ) async {
    if (call.name == 'getByCategory') {
      final catName = call.args['category'] as String?;
      if (catName == null) {
        await _sendToolError(chat, 'getByCategory', 'Missing category parameter');
        return false;
      }
      final category = _parseCategory(catName);
      if (category == null) {
        await _sendToolError(chat, 'getByCategory', 'Invalid category: $catName');
        return false;
      }
      final todos = _repository.getByCategory(category);
      final result = {
        'todos': todos.map((t) => {'id': t.id, 'title': t.title}).toList(),
      };
      await chat.addQueryChunk(Message.toolResponse(
        toolName: 'getByCategory',
        response: result,
      ));
      return false;
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/services/todo_categorization_service.dart
git commit -m "feat: add TodoCategorizationService with function calling"
```

---

### Task 6: Add categorization FAB and flow to TodoScreen

**Files:**
- Modify: `lib/presentation/screens/todo_screen.dart`

- [ ] **Step 1: Read the current file first**

Read `lib/presentation/screens/todo_screen.dart`.

- [ ] **Step 2: Add imports**

Add these imports at the top of the file:

```dart
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/di/di_container.dart';
import 'package:gemma_local/core/models/categorization_result.dart';
import 'package:gemma_local/core/services/todo_categorization_service.dart';
```

- [ ] **Step 3: Replace the single FAB with stacked FABs**

Replace the `floatingActionButton:` line (from `FloatingActionButton(` to the closing `),`) with:

```dart
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'categorize',
            backgroundColor: AppColors.accent,
            onPressed: () => _categorizeTodos(context),
            child: const Icon(Icons.psychology, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: AppColors.accent,
            onPressed: _showAddDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
```

- [ ] **Step 4: Add the _categorizeTodos method to _TodoScreenBodyState**

Add these methods inside `_TodoScreenBodyState`:

```dart
  Future<void> _categorizeTodos(BuildContext context) async {
    final cubit = context.read<TodoCubit>();
    final state = cubit.state;

    final generalTodos = switch (state) {
      TodoLoaded(groupedTodos: final grouped) =>
        grouped[TodoCategory.general] ?? const [],
      _ => <Todo>[],
    };

    if (generalTodos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No todos to categorize')),
      );
      return;
    }

    _showCategorizingOverlay(context);

    final model = serviceLocator<InferenceModel>();
    final repository = RepositoryProvider.of<ITodoRepository>(context);
    final service = TodoCategorizationService(model, repository);

    try {
      final result = await service.categorizeGeneralTodos();
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss overlay

      if (result.totalProcessed == 0) {
        return;
      }

      cubit.loadTodos(); // refresh the UI from repository
      _showResultDialog(context, result);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss overlay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categorization could not be completed')),
      );
    }
  }

  void _showCategorizingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text(
                'Categorizing...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, CategorizationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Categorization Complete',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...result.categorized.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: e.key.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          e.key.displayName,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (result.skipped > 0) ...[
              const Divider(color: AppColors.textSecondary),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skipped',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${result.skipped}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 5: Add the Todo import at the top of the file**

The `_categorizeTodos` method references `Todo`. Make sure this import exists in the file:

```dart
import 'package:gemma_local/core/models/todo.dart';
```

If it's not already present, add it.

- [ ] **Step 6: Run flutter analyze and commit**

```bash
fvm flutter analyze
```

```bash
git add lib/presentation/screens/todo_screen.dart
git commit -m "feat: add LLM categorization FAB and flow to TodoScreen"
```

---

### Task 7: Verify with flutter analyze

- [ ] **Step 1: Run full static analysis**

```bash
fvm flutter analyze
```

Expected: "No issues found!" or 0 issues.

If there are errors, fix them and re-run until clean.

- [ ] **Step 2: Commit any final fixes**

```bash
git add -A
git commit -m "fix: resolve analysis issues from categorization feature"
```
