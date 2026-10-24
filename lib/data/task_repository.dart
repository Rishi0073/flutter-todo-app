import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

// Repository pattern: the rest of the app only talks to this
// abstract class, never directly to SharedPreferences. Swapping
// storage (for example to a backend API) only touches this file.
abstract class TaskRepository {
  Future<List<Task>> loadTasks();
  Future<void> saveTasks(List<Task> tasks);
}

class SharedPreferencesTaskRepository implements TaskRepository {
  static const String _storageKey = 'tasks_v1';

  @override
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      // First run: seed with example tasks.
      return [
        Task(
          id: 'seed-1',
          title: 'Learn Flutter widgets',
          priority: TaskPriority.high,
        ),
        Task(
          id: 'seed-2',
          title: 'Build a small app every week',
          priority: TaskPriority.medium,
        ),
        Task(
          id: 'seed-3',
          title: 'Push this project to GitHub',
          priority: TaskPriority.medium,
        ),
      ];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
