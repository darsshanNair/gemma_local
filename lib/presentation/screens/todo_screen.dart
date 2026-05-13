import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:gemma_local/core/di/di_container.dart';
import 'package:gemma_local/core/models/categorization_result.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/models/todo_category.dart';
import 'package:gemma_local/core/services/i_todo_repository.dart';
import 'package:gemma_local/core/services/todo_categorization_service.dart';
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
      create: (_) =>
          TodoCubit(RepositoryProvider.of<ITodoRepository>(context))
            ..loadTodos(),
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
  bool _isCategorizing = false;

  void _showAddDialog() {
    final controller = TextEditingController();
    TodoCategory? selectedCategory;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            AppStrings.newTask,
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: AppStrings.typeTask,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TodoCategory?>(
                initialValue: selectedCategory,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: AppStrings.category,
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(AppStrings.categoryGeneral),
                  ),
                  ...TodoCategory.values
                      .where((c) => c != TodoCategory.general)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.displayName),
                        ),
                      ),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedCategory = value),
              ),
            ],
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
                context
                    .read<TodoCubit>()
                    .addTodo(text, category: selectedCategory);
                Navigator.pop(ctx);
              },
              child: const Text(
                AppStrings.add,
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _categorizeTodos(BuildContext context) async {
    if (_isCategorizing) return;
    _isCategorizing = true;

    try {
      final cubit = context.read<TodoCubit>();
      final state = cubit.state;

      final generalTodos = switch (state) {
        TodoLoaded(groupedTodos: final grouped) =>
          grouped[TodoCategory.general] ?? const [],
        _ => <Todo>[],
      };

      if (generalTodos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.noTodosToCategorize)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.allTodosRemainInGeneral),
            ),
          );
          return;
        }

        cubit.loadTodos(); // refresh the UI from repository
        _showResultDialog(context, result);
      } catch (e) {
        debugPrint('Categorization failed: $e');
        if (!context.mounted) return;
        Navigator.pop(context); // dismiss overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.categorizationFailed}: $e'),
          ),
        );
      }
    } finally {
      _isCategorizing = false;
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
                AppStrings.categorizing,
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
          AppStrings.categorizationComplete,
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
                      AppStrings.skipped,
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
              AppStrings.ok,
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
      body: BlocBuilder<TodoCubit, TodoState>(
        builder: (context, state) {
          return switch (state) {
            TodoInitial() => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            TodoLoaded(groupedTodos: final groupedTodos) =>
              groupedTodos.isEmpty
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      itemCount: groupedTodos.length +
                          groupedTodos.values.fold<int>(0, (sum, t) => sum + t.length),
                      itemBuilder: (_, index) {
                        var offset = index;
                        for (final entry in groupedTodos.entries) {
                          if (offset == 0) {
                            return _buildSectionHeader(
                              entry.key,
                              entry.value.length,
                            );
                          }
                          offset--;
                          if (offset < entry.value.length) {
                            return TodoItem(todo: entry.value[offset]);
                          }
                          offset -= entry.value.length;
                        }
                        return const SizedBox.shrink();
                      },
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
                      onPressed: () =>
                          context.read<TodoCubit>().loadTodos(),
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

  Widget _buildSectionHeader(TodoCategory category, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: category.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.todosTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          BlocBuilder<TodoCubit, TodoState>(
            builder: (context, state) {
              final remaining = switch (state) {
                TodoLoaded(groupedTodos: final groupedTodos) => groupedTodos
                    .values
                    .expand((todos) => todos)
                    .where((t) => !t.isCompleted)
                    .length,
                _ => 0,
              };
              return Text(
                '$remaining remaining',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
