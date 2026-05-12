import '../models/todo.dart';
import '../models/todo_category.dart';

abstract class ITodoRepository {
  Todo? getById(String id);
  List<Todo> getAll();
  List<Todo> getByCategory(TodoCategory category);
  void add(Todo todo);
  void update(String id, Todo todo);
  void remove(String id);
}
