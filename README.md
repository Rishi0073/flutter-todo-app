# Flutter Todo App — Senior-Level Structure

A task manager app built the way a senior developer would structure it:
clean layers, testable logic, local persistence, and CI.

## Features (v3)

- Add tasks with title, notes, priority (Low / Medium / High),
  category (Work / Study / Personal / Other) and an optional due date
- Tap a task to edit it, swipe it to delete it, undo a delete
- Mark tasks done, clear all completed tasks in one tap
- Search tasks by title and notes
- Filter: All / Pending / Done, plus filter by category
- Sort: newest first, priority, due date, or title A-Z
- Overdue tasks are highlighted in red
- Progress bar + counts: total, done, pending, overdue
- Dark mode toggle, saved on the device
- Tasks are saved on the device with SharedPreferences, so they
  survive closing the app
- Old tasks saved by v2 still load: new fields default safely

## Architecture

```
lib/
  main.dart                  Thin entry point, wires layers together
  theme/app_theme.dart       Light + dark themes in one place
  models/task.dart           Task model + JSON, no Flutter dependency
  data/task_repository.dart  Repository pattern (task storage)
  data/settings_repository.dart  Settings storage (dark mode)
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
  for a backend API only touches the repository files.
- The controller is tested with fake repositories, so tests need
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

- Add reminders / notifications for due dates
- Replace the local repository with a REST API repository
  to make it a true full-stack app
- Add sign-in and sync tasks across devices
