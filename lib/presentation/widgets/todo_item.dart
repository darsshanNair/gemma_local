import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemma_local/core/models/todo.dart';
import 'package:gemma_local/core/models/todo_category.dart';
import 'package:gemma_local/core/utilities/constants/app_strings.dart';
import 'package:gemma_local/presentation/bloc/cubits/todo_cubit.dart';
import 'package:gemma_local/presentation/theme/app_colors.dart';

class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.todo,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final category = todo.category;
    final categoryColor = category?.color;

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.errorText,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<TodoCubit>().deleteTodo(todo.id),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          activeColor: AppColors.accent,
          checkColor: Colors.white,
          side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
          onChanged: (_) => context.read<TodoCubit>().toggleTodo(todo.id),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
            if (category != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor!.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showEditDialog(context),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: todo.title);
    TodoCategory? selectedCategory = todo.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            AppStrings.editTask,
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
                  hintText: AppStrings.editHint,
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
                    .updateTodo(todo.id, text, category: selectedCategory);
                Navigator.pop(ctx);
              },
              child: const Text(
                AppStrings.save,
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
