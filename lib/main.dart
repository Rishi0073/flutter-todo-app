import 'package:flutter/material.dart';

import 'controllers/task_controller.dart';
import 'data/settings_repository.dart';
import 'data/task_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

// Thin entry point: wire the layers together, nothing else.
void main() {
  final controller = TaskController(
    SharedPreferencesTaskRepository(),
    SharedPreferencesSettingsRepository(),
  );
  runApp(TodoApp(controller: controller));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Todo App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              controller.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(controller: controller),
        );
      },
    );
  }
}
