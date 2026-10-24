import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_app/controllers/task_controller.dart';
import 'package:flutter_todo_app/data/task_repository.dart';
import 'package:flutter_todo_app/models/task.dart';

// Fake repository for tests: no SharedPreferences, no phone needed.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task>? seed]) : _stored = seed ?? [];

  List<Task> _stored;

  @override
  Future<List<Task>> loadTasks() async => List.of(_stored);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _stored = List.of(tasks);
  }
}

void main() {
  test('Task converts to JSON and back without losing data', () {
    const original = Task(
      id: '1',
      title: 'Write tests',
      done: true,
      priority: TaskPriority.high,
    );
    final restored = Task.fromJson(original.toJson());
    expect(restored, original);
  });

  test('Controller filters pending tasks and counts them', () async {
    final controller = TaskController(
      FakeTaskRepository([
        Task(id: '1', title: 'Done task', done: true),
        Task(id: '2', title: 'Open task', done: false),
      ]),
    );
    await controller.load();
    expect(controller.pendingCount, 1);

    controller.setFilter(TaskFilter.pending);
    expect(controller.visibleTasks.length, 1);
    expect(controller.visibleTasks.first.title, 'Open task');
  });

  test('Controller search filters by title, case-insensitive', () async {
    final controller = TaskController(
      FakeTaskRepository([
        Task(id: '1', title: 'Learn Flutter'),
        Task(id: '2', title: 'Buy groceries'),
      ]),
    );
    await controller.load();
    controller.setSearchQuery('flutter');
    expect(controller.visibleTasks.length, 1);
    expect(controller.visibleTasks.first.title, 'Learn Flutter');
  });

  test('Adding a task with an empty title does nothing', () async {
    final controller = TaskController(FakeTaskRepository());
    await controller.load();
    await controller.addTask('   ', TaskPriority.low);
    expect(controller.allTasks, isEmpty);
  });
}
