import '../models/todo.dart';

abstract class ITodoRepository {
  List<Todo> getAll();
  void add(Todo todo);
  void update(int index, Todo todo);
  void remove(int index);
}
