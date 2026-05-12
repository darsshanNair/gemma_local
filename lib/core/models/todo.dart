import 'package:uuid/uuid.dart';
import 'todo_category.dart';

class Todo {
  final String id;
  final String title;
  final bool isCompleted;
  final TodoCategory? category;

  const Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.category,
  });

  factory Todo.create({
    required String title,
    TodoCategory? category,
  }) {
    return Todo(
      id: const Uuid().v4(),
      title: title,
      category: category,
    );
  }

  Todo copyWith({
    String? title,
    bool? isCompleted,
    TodoCategory? category,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }
}
