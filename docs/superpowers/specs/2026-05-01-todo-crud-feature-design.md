# Todo CRUD Feature — Design Spec

**Date**: 2026-05-01
**Branch**: `feature/todo-crud`

## Overview

Add a minimal todo list screen with full CRUD operations (create, read, update, delete) to the existing Gemma Local app. The todo list lives in a separate screen accessible via a bottom navigation bar alongside the existing chat screen. AI function calling integration is deferred to a later phase.

## Architecture

### New Files

```
lib/
├── core/
│   ├── models/
│   │   └── todo.dart                          # Todo model
│   └── services/
│       ├── i_todo_repository.dart             # Repository interface
│       └── todo_repository.dart               # In-memory implementation
├── presentation/
│   ├── bloc/
│   │   ├── cubits/
│   │   │   └── todo_cubit.dart                # TodoCubit (state management)
│   │   └── states/
│   │       └── todo_state.dart                # Sealed state classes
│   ├── screens/
│   │   ├── todo_screen.dart                   # New todo list screen
│   │   └── home_screen.dart                   # Shell with BottomNavigationBar
│   └── widgets/
│       └── todo_item.dart                     # Single todo row widget
```

### Modified Files

| File | Change |
|------|--------|
| `lib/core/di/di_container.dart` | Register `ITodoRepository` and `TodoCubit` |
| `lib/core/utilities/constants/app_strings.dart` | Add todo-related string constants |
| `lib/presentation/gemma_local_app.dart` | Navigate to `HomeScreen` instead of `ChatScreen` |
| `lib/presentation/screens/chat_screen.dart` | Remove top-level title handling (deferred to shell) |

## Model

### Todo (`lib/core/models/todo.dart`)

```dart
class Todo {
  final String title;
  final bool isCompleted;

  const Todo({required this.title, this.isCompleted = false});

  Todo copyWith({String? title, bool? isCompleted});
}
```

## State Management

### TodoState (`lib/presentation/bloc/states/todo_state.dart`)

Sealed union:
- `TodoInitial` — no todos loaded yet
- `TodoLoaded(List<Todo> todos)` — current list of todos
- `TodoError(String message)` — unexpected error from repository

### TodoCubit (`lib/presentation/bloc/cubits/todo_cubit.dart`)

Depends on `ITodoRepository`. Methods:
- `loadTodos()` → emit `TodoLoaded(repo.getAll())`
- `addTodo(String title)` — validates non-empty/whitespace, calls `repo.add()`, emits `TodoLoaded`
- `toggleTodo(int index)` — flips `isCompleted`, calls `repo.update()`, emits `TodoLoaded`
- `deleteTodo(int index)` — calls `repo.remove()`, emits `TodoLoaded`
- `updateTodo(int index, String newTitle)` — validates non-empty, calls `repo.update()`, emits `TodoLoaded`

Validation failures are silently ignored (no state change). Unexpected errors emit `TodoError`.

## Repository

### ITodoRepository (`lib/core/services/i_todo_repository.dart`)

```dart
abstract class ITodoRepository {
  List<Todo> getAll();
  void add(Todo todo);
  void update(int index, Todo todo);
  void remove(int index);
}
```

### TodoRepository (`lib/core/services/todo_repository.dart`)

In-memory `List<Todo>` backing store. No persistence.

## UI

### HomeScreen (`lib/presentation/screens/home_screen.dart`)

- `Scaffold` with `BottomNavigationBar` (Chat, Todos tabs)
- Switches between `ChatScreen` and `TodoScreen`
- Stores the current tab index in local widget state

### TodoScreen (`lib/presentation/screens/todo_screen.dart`)

- `BlocProvider` provides `TodoCubit`, calls `loadTodos()` on init
- AppBar with title "Todos" and subtitle showing incomplete count (e.g., "2 remaining")
- `BlocBuilder<TodoCubit, TodoState>`:
  - `TodoInitial` → centered loading spinner
  - `TodoLoaded` → `ListView.builder` of `TodoItem` widgets, or empty state if list is empty
  - `TodoError` → centered error text with retry button
- FAB (`FloatingActionButton` with `+` icon) opens add-todo dialog

### TodoItem (`lib/presentation/widgets/todo_item.dart`)

- `Checkbox` on the left → calls `cubit.toggleTodo(index)`
- Title text → strikethrough style when completed
- `Dismissible` swipe-right-to-delete with red background + trash icon
- `onTap` → edit dialog with pre-filled text field

### Dialogs

Both dialogs are simple `AlertDialog` widgets:
- **Add dialog**: title "New Task", text field + Cancel/Add buttons
- **Edit dialog**: title "Edit Task", text field pre-filled with current title + Cancel/Save buttons

Both validate that the title is non-empty before allowing the action.

## Data Flow

```
FAB tap → Add dialog → user enters title → Cubit.addTodo(title)
  → Repository.add(Todo) → emit TodoLoaded(new list)
  → BlocBuilder rebuilds ListView

Checkbox tap → Cubit.toggleTodo(index)
  → Repository.update(index, toggled) → emit TodoLoaded(updated)

Swipe → Dismissible onDismissed → Cubit.deleteTodo(index)
  → Repository.remove(index) → emit TodoLoaded(updated)

Todo tap → Edit dialog → user changes title → Cubit.updateTodo(index, title)
  → Repository.update(index, updated) → emit TodoLoaded(updated)
```

## Error Handling

| Case | Behavior |
|------|----------|
| Empty/whitespace title on add | Dialog silently prevents submission; Cubit no-ops |
| Empty/whitespace title on update | Dialog silently prevents submission; Cubit no-ops |
| Repository throws unexpected error | Cubit catches and emits `TodoError(message)` |
| `TodoError` state in UI | Centered error text + "Retry" button that calls `loadTodos()` |

## Out of Scope

- Data persistence (todos lost on app restart)
- AI agent / function calling integration
- Sorting, filtering, categories, due dates
- Undo after delete
- Multi-select or batch operations

## Dependencies

No new packages required. Uses:
- `flutter_bloc` (Cubit, BlocProvider, BlocBuilder) — already in pubspec
- Existing `GetIt` (DI) — already in pubspec
