# LLM Todo Categorization — Design Spec

**Date**: 2026-05-13
**Branch**: `feature/llm-categorization`

## Overview

Use the on-device LLM to categorize todos currently under the General category. The LLM accesses `getByCategory` and `updateTodo` via function calling (tool use). A second FAB on the TodoScreen triggers the workflow.

## Architecture

### Tool Definitions

Two tools registered with the LLM:

**`getByCategory`**
- Parameter: `category` (string — one of: work, personal, health, finances, general)
- Returns: array of `{id, title}` for todos in that category

**`updateTodoCategory`**
- Parameters: `id` (string), `category` (string)
- Returns: `{success: true/false}` — validates that category is valid before updating

### TodoCategorizationService (`lib/core/services/todo_categorization_service.dart`)

Creates a dedicated `InferenceChat` from the existing `InferenceModel` with:
- `supportsFunctionCalls: true`
- `toolChoice: ToolChoice.required`
- Tools: `getByCategory`, `updateTodoCategory`

Single method:
```dart
Future<CategorizationResult> categorizeGeneralTodos()
```

Flow:
1. Fetch General todos via `ITodoRepository.getByCategory(TodoCategory.general)`
2. If empty, return `CategorizationResult.empty`
3. Build prompt: list of General todos (id + title), list of target categories
4. Send prompt to LLM, handle tool calls in a turn loop
5. For each valid `updateTodoCategory` call, execute via `TodoCubit.updateTodo`
6. Return `CategorizationResult` with counts per target category

### CategorizationResult

```dart
class CategorizationResult {
  final Map<TodoCategory, int> categorized; // how many moved to each category
  final int skipped; // left as General
}
```

## System Instruction Update

`AppConstants.systemInstruction` changes to:

```
You are a todo list assistant. You can help categorize tasks.

When asked to categorize todos:
1. Read each todo's title carefully
2. Assign it to the most appropriate category based on the task content
3. Only use the available categories provided to you
4. If you are unsure which category fits, leave it as General
5. Do not make up new categories
```

## UI

### TodoScreen — Second FAB

Two FABs stacked vertically on the right side:
- Bottom: existing add (+) FAB (unchanged)
- Above: categorize FAB — psychology icon (`Icons.psychology`), same `AppColors.accent` background

Implementation: a `Column` with two `FloatingActionButton.small` widgets, spaced by a `SizedBox(height: 12)`.

### Categorization Flow

1. User taps categorize FAB
2. If no General todos → `SnackBar`: "No todos to categorize"
3. If General todos exist → overlay with `CircularProgressIndicator` + "Categorizing..." text
4. Service runs LLM categorization
5. On success → `AlertDialog` showing category breakdown (e.g., "Work: 2, Personal: 1, Health: 0, Finances: 1, Skipped: 1")
6. Dismiss dialog → `TodoCubit.loadTodos()` refreshes the list

## Error Handling

| Case | Behavior |
|------|----------|
| No General todos | SnackBar "No todos to categorize" |
| LLM makes no tool calls | SnackBar "Categorization could not be completed" |
| LLM provides invalid category | `updateTodoCategory` rejects, tool response reports error |
| Repository error during tool | Caught, returned as tool error response |

## Out of Scope

- Categorizing non-General todos
- Multi-turn LLM conversations about categorization
- Streaming display of LLM reasoning
- Configurable system instruction (hardcoded)
- Categorization from Chat tab

## Dependencies

No new packages needed. Uses existing:
- `flutter_gemma` (function calling, `Tool`, `ToolChoice`, `FunctionCallResponse`)
- `uuid` (already in pubspec)
- `flutter_bloc` (already in pubspec)
