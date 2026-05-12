import '../models/todo.dart';
import '../models/todo_category.dart';
import 'i_todo_repository.dart';

class TodoRepository implements ITodoRepository {
  final List<Todo> _todos = [];

  @override
  Todo? getById(String id) {
    final idx = _todos.indexWhere((t) => t.id == id);
    return idx == -1 ? null : _todos[idx];
  }

  @override
  List<Todo> getAll() => List.unmodifiable(_todos);

  @override
  List<Todo> getByCategory(TodoCategory category) =>
      _todos.where((t) => (t.category ?? TodoCategory.general) == category).toList();

  @override
  void add(Todo todo) => _todos.add(todo);

  @override
  void update(String id, Todo todo) {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx != -1) _todos[idx] = todo;
  }

  @override
  void remove(String id) => _todos.removeWhere((t) => t.id == id);
}
