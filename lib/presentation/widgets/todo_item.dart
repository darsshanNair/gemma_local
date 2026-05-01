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
