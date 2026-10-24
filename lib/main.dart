import 'package:flutter/material.dart';

import 'controllers/task_controller.dart';
import 'data/task_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

// Thin entry point: wire the layers together, nothing else.
void main() {
  final controller = TaskController(SharedPreferencesTaskRepository());
  runApp(TodoApp(controller: controller));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(controller: controller),
    );
  }
}
