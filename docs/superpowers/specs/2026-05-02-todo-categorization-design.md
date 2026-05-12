# Todo Categorization — Design Spec

**Date**: 2026-05-02
**Branch**: `feature/implement-todo-categorization`

## Overview

Add category support to the todo list. Users can assign a category when creating or editing a todo. Todos are grouped by category with colored section headers in the list view. Unassigned todos default to "General".

## Categories

| Category | Color |
|----------|-------|
| General (default) | Blue (`#64B5F6`) |
| Work | Purple (`#9D7BFF`) |
| Personal | Yellow/Amber (`#FFA040`) |
| Health | Pink (`#FF7EA0`) |
| Finances | Green (`#4CAF82`) |

## Model Changes

### TodoCategory enum (`lib/core/models/todo_category.dart`)

```dart
enum TodoCategory { general, work, personal, health, finances }
```

Extension provides `displayName` and `color` getters.

### Todo model

- Add `id` (String, UUID v4) for stable identity independent of list position
- Add `category` (TodoCategory?, nullable — null treated as General)
- `Todo.create()` factory generates UUID via `uuid` package
- `copyWith` updated to include optional `category` parameter

## State Management

### TodoLoaded state

Changed from `List<Todo>` to `Map<TodoCategory, List<Todo>>` — grouped by category, insertion order preserved. Empty categories omitted.

### TodoCubit

All operations switch from index-based to ID-based:
- `addTodo(String title, {TodoCategory? category})`
- `toggleTodo(String id)`
- `deleteTodo(String id)`
- `updateTodo(String id, String newTitle, {TodoCategory? category})`
- `_groupByCategory()` groups todos, skips empty categories, uses fixed order: General → Work → Personal → Health → Finances

## Repository

### ITodoRepository

Updated from index-based to ID-based:
- `getById(String id)`, `getByCategory(TodoCategory)`, `update(String id, ...)`, `remove(String id)`

## UI

### Add/Edit Dialogs

Both dialogs now include a `DropdownButtonFormField<TodoCategory?>` below the text field. Default selection is null (renders as "General"). Uses `StatefulBuilder` for local dialog state.

### TodoItem

- Removed `index` parameter, uses `todo.id` for all operations
- Shows a colored category chip label (category name on colored background) on the right side
- Category chip only shown when a non-null category is assigned

### TodoScreen

- `ListView.builder` now renders grouped entries: section header followed by todo items
- Section headers show: colored left bar, category name in category color, item count
- Remaining count in AppBar is computed from expanded grouped values

## Out of Scope

- User-configurable categories
- Category reordering
- Per-category filtering
- Category persistence as a separate entity

## New Dependencies

- `uuid` package — already added via `fvm flutter pub add uuid`
