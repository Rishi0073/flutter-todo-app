# Flutter Todo App — Senior-Level Structure

A task manager app built the way a senior developer would structure it:
clean layers, testable logic, local persistence, and CI.

## Features

- Add tasks with a priority (Low / Medium / High)
- Mark tasks done, delete tasks
- Search tasks by title
- Filter: All / Pending / Done
- Tasks are saved on the device with SharedPreferences, so they
  survive closing the app
- Pending-task count at the top

## Architecture

```
lib/
  main.dart                  Thin entry point, wires layers together
  theme/app_theme.dart       App theme in one place
  models/task.dart           Task model + JSON, no Flutter dependency
  data/task_repository.dart  Repository pattern (storage abstraction)
  controllers/task_controller.dart  All business logic, ChangeNotifier
  screens/home_screen.dart   UI only, no business logic
  widgets/task_tile.dart     Reusable task row
test/
  task_test.dart             Unit tests for model + controller
.github/workflows/
  flutter.yml                CI: flutter analyze + flutter test
```

Why this structure matters for a job:

- The UI never talks to storage directly. Swapping SharedPreferences
  for a backend API only touches `task_repository.dart`.
- The controller is tested with a fake repository, so tests need
  no phone and no real storage.
- `flutter analyze` and `flutter test` run on every push via
  GitHub Actions.

## How to run it

1. Install the Flutter SDK, then check it with `flutter doctor`
2. Open this folder in VS Code (or a terminal inside it)
3. `flutter pub get`
4. `flutter run`

## How to check quality

```
flutter analyze
flutter test
```

## Next steps (good interview talking points)

- Add due dates and reminders
- Add categories and sorting by priority
- Replace the local repository with a REST API repository
  to make it a true full-stack app
