# Todo CRUD Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal todo list screen with full CRUD alongside the existing chat screen via bottom navigation.

**Architecture:** Cubit state management with sealed states. In-memory repository behind an interface. New `HomeScreen` shell wraps `ChatScreen` and new `TodoScreen` via `BottomNavigationBar`.

**Tech Stack:** Flutter, flutter_bloc (Cubit), GetIt DI

---

### Task 1: Create feature branch

- [ ] **Step 1: Create and switch to feature branch**

```bash
git checkout -b feature/todo-crud
```

---

### Task 2: Add flutter_bloc dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_bloc to dependencies**

Add `flutter_bloc: ^9.0.0` under dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_gemma: ^0.13.2
  get_it: ^9.2.1
  flutter_bloc: ^9.0.0
```

- [ ] **Step 2: Install the package**

```bash
flutter pub get
```

Expected: exits 0, no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add flutter_bloc dependency"
```

---

### Task 3: Create Todo model

**Files:**
- Create: `lib/core/models/todo.dart`

- [ ] **Step 1: Write the model**

```dart
class Todo {
  final String title;
  final bool isCompleted;

  const Todo({
    required this.title,
    this.isCompleted = false,
  });

  Todo copyWith({String? title, bool? isCompleted}) {
    return Todo(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/models/todo.dart
git commit -m "feat: add Todo model"
```

---

### Task 4: Create ITodoRepository interface

**Files:**
- Create: `lib/core/services/i_todo_repository.dart`

- [ ] **Step 1: Write the interface**

```dart
import '../models/todo.dart';

abstract class ITodoRepository {
  List<Todo> getAll();
  void add(Todo todo);
  void update(int index, Todo todo);
  void remove(int index);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/services/i_todo_repository.dart
git commit -m "feat: add ITodoRepository interface"
```

---

### Task 5: Create TodoRepository (in-memory)

**Files:**
- Create: `lib/core/services/todo_repository.dart`

- [ ] **Step 1: Write the implementation**

```dart
import '../models/todo.dart';
import 'i_todo_repository.dart';

class TodoRepository implements ITodoRepository {
  final List<Todo> _todos = [];

  @override
  List<Todo> getAll() => List.unmodifiable(_todos);

  @override
  void add(Todo todo) => _todos.add(todo);

  @override
  void update(int index, Todo todo) => _todos[index] = todo;

  @override
  void remove(int index) => _todos.removeAt(index);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/services/todo_repository.dart
git commit -m "feat: add in-memory TodoRepository"
```

---

### Task 6: Create TodoState

**Files:**
- Create: `lib/presentation/bloc/states/todo_state.dart`

- [ ] **Step 1: Ensure directories exist and write state file**

```bash
mkdir -p lib/presentation/bloc/states lib/presentation/bloc/cubits
```

- [ ] **Step 2: Write the state classes**

```dart
import 'package:gemma_local/core/models/todo.dart';

sealed class TodoState {}

final class TodoInitial extends TodoState {}

final class TodoLoaded extends TodoState {
  final List<Todo> todos;
  const TodoLoaded(this.todos);
}

final class TodoError extends TodoState {
  final String message;
  const TodoError(this.message);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/bloc/states/todo_state.dart
git commit -m "feat: add TodoState sealed classes"
```

---

### Task 7: Create TodoCubit

**Files:**
- Create: `lib/presentation/bloc/cubits/todo_cubit.dart`

- [ ] **Step 1: Write the cubit**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/presentation/bloc/states/todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  final ITodoRepository _repository;

  TodoCubit(this._repository) : super(TodoInitial());

  void loadTodos() {
    try {
      final todos = _repository.getAll();
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void addTodo(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    try {
      _repository.add(Todo(title: trimmed));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void toggleTodo(int index) {
    try {
      final todo = _repository.getAll()[index];
      _repository.update(index, todo.copyWith(isCompleted: !todo.isCompleted));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void deleteTodo(int index) {
    try {
      _repository.remove(index);
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  void updateTodo(int index, String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    try {
      final todo = _repository.getAll()[index];
      _repository.update(index, todo.copyWith(title: trimmed));
      emit(TodoLoaded(_repository.getAll()));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/bloc/cubits/todo_cubit.dart
git commit -m "feat: add TodoCubit"
```

---

### Task 8: Register new dependencies in ServiceLocator

**Files:**
- Modify: `lib/core/di/di_container.dart`

- [ ] **Step 1: Add registrations**

Replace the file content:

```dart
import 'package:get_it/get_it.dart';
import '../services/i_model_service.dart';
import '../services/i_todo_repository.dart';
import '../services/model_service.dart';
import '../services/todo_repository.dart';
import '../../presentation/bloc/cubits/todo_cubit.dart';

final GetIt serviceLocator = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    await initServices();
    initBlocs();
  }

  static Future<void> initServices() async {
    serviceLocator.registerLazySingleton<IModelService>(
      () => ModelService(),
    );
    serviceLocator.registerLazySingleton<ITodoRepository>(
      () => TodoRepository(),
    );
  }

  static void initBlocs() {
    serviceLocator.registerFactory<TodoCubit>(
      () => TodoCubit(serviceLocator<ITodoRepository>()),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/di/di_container.dart
git commit -m "feat: register ITodoRepository and TodoCubit in DI"
```

---

### Task 9: Add string constants

**Files:**
- Modify: `lib/core/utilities/constants/app_strings.dart`

- [ ] **Step 1: Add todo strings**

```dart
class AppStrings {
  static const String todosTitle = 'Todos';
  static const String newTask = 'New Task';
  static const String editTask = 'Edit Task';
  static const String cancel = 'Cancel';
  static const String add = 'Add';
  static const String save = 'Save';
  static const String chatTab = 'Chat';
  static const String todosTab = 'Todos';
  static const String emptyTodos = 'No tasks yet. Tap + to add one.';
  static const String typeTask = 'Type a task...';
  static const String editHint = 'Edit task...';
  static const String somethingWentWrong = 'Something went wrong.';
  static const String retry = 'Retry';
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/utilities/constants/app_strings.dart
git commit -m "feat: add todo-related string constants"
```

---

### Task 10: Create TodoItem widget

**Files:**
- Create: `lib/presentation/widgets/todo_item.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/utilities/constants/app_strings.dart';
import 'package:gemma_local/presentation/bloc/cubits/todo_cubit.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';

class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.todo,
    required this.index,
  });

  final Todo todo;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${todo.title}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorText,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<TodoCubit>().deleteTodo(index),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          activeColor: AppColors.accent,
          checkColor: Colors.white,
          side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
          onChanged: (_) => context.read<TodoCubit>().toggleTodo(index),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
        ),
        onTap: () => _showEditDialog(context),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: todo.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          AppStrings.editTask,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: AppStrings.editHint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              context.read<TodoCubit>().updateTodo(index, text);
              Navigator.pop(ctx);
            },
            child: const Text(
              AppStrings.save,
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/todo_item.dart
git commit -m "feat: add TodoItem widget"
```

---

### Task 11: Create TodoScreen

**Files:**
- Create: `lib/presentation/screens/todo_screen.dart`

- [ ] **Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/core/utilities/constants/app_strings.dart';
import 'package:gemma_local/presentation/bloc/cubits/todo_cubit.dart';
import 'package:gemma_local/presentation/bloc/states/todo_state.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';
import 'package:gemma_local/presentation/widgets/todo_item.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TodoCubit(RepositoryProvider.of<ITodoRepository>(context))..loadTodos(),
      child: const _TodoScreenBody(),
    );
  }
}

class _TodoScreenBody extends StatefulWidget {
  const _TodoScreenBody();

  @override
  State<_TodoScreenBody> createState() => _TodoScreenBodyState();
}

class _TodoScreenBodyState extends State<_TodoScreenBody> {
  void _showAddDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          AppStrings.newTask,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: AppStrings.typeTask,
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              context.read<TodoCubit>().addTodo(text);
              Navigator.pop(ctx);
            },
            child: const Text(
              AppStrings.add,
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<TodoCubit, TodoState>(
        builder: (context, state) {
          return switch (state) {
            TodoInitial() =>
              const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            TodoLoaded(todos: final todos) => todos.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.emptyTodos,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: todos.length,
                    itemBuilder: (_, index) => TodoItem(
                      todo: todos[index],
                      index: index,
                    ),
                  ),
            TodoError(message: final msg) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg,
                      style: const TextStyle(
                        color: AppColors.errorText,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<TodoCubit>().loadTodos(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        AppStrings.todosTitle,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      bottom: BlocBuilder<TodoCubit, TodoState>(
        builder: (context, state) {
          final remaining = switch (state) {
            TodoLoaded(todos: final todos) =>
              todos.where((t) => !t.isCompleted).length,
            _ => 0,
          };
          return PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$remaining remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/todo_screen.dart
git commit -m "feat: add TodoScreen"
```

---

### Task 12: Modify ChatScreen — remove title parameter

**Files:**
- Modify: `lib/presentation/screens/chat_screen.dart`

- [ ] **Step 1: Remove the `title` parameter**

Change line 12 from:
```dart
  const ChatScreen({super.key, required this.title});
```
to:
```dart
  const ChatScreen({super.key});
```

- [ ] **Step 2: Remove the `title` field**

Delete line 14:
```dart
  final String title;
```

- [ ] **Step 3: Hardcode the AppBar title**

Change line 190 from:
```dart
                widget.title,
```
to:
```dart
                'Gemma AI',
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/chat_screen.dart
git commit -m "feat: remove title parameter from ChatScreen"
```

---

### Task 13: Create HomeScreen with bottom navigation

**Files:**
- Create: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/di/di_container.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/core/utilities/constants/app_strings.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';
import 'package:gemma_local/presentation/screens/chat_screen.dart';
import 'package:gemma_local/presentation/screens/todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    ChatScreen(),
    TodoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepositoryProvider<ITodoRepository>.value(
        value: serviceLocator<ITodoRepository>(),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: AppStrings.chatTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: AppStrings.todosTab,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/home_screen.dart
git commit -m "feat: add HomeScreen with bottom navigation"
```

---

### Task 14: Update GemmaLocalApp to use HomeScreen

**Files:**
- Modify: `lib/presentation/gemma_local_app.dart`

- [ ] **Step 1: Import HomeScreen and update home**

Change line 2 from:
```dart
import 'package:gemma_local/presentation/screens/chat_screen.dart';
```
to:
```dart
import 'package:gemma_local/presentation/screens/home_screen.dart';
```

Change line 13 from:
```dart
      home: const ChatScreen(title: 'Gemma AI Assistant'),
```
to:
```dart
      home: const HomeScreen(),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/gemma_local_app.dart
git commit -m "feat: wire HomeScreen as app home"
```

---

### Task 15: Verify with flutter analyze

- [ ] **Step 1: Run static analysis**

```bash
flutter analyze
```

Expected: "No issues found!" or 0 issues.

If there are errors, fix them and re-run until clean.

- [ ] **Step 2: Commit any final fixes**

```bash
git add -A
git commit -m "fix: resolve analysis issues"
```
