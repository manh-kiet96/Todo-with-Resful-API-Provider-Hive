import 'package:todo_with_resfulapi/screens/home_screen.dart';
import 'package:todo_with_resfulapi/screens/add_task_screen.dart';
import 'package:todo_with_resfulapi/screens/edit_task_screen.dart';
import 'package:todo_with_resfulapi/screens/completed_task_screen.dart';
import 'package:todo_with_resfulapi/auth/auth_page.dart';
import 'package:todo_with_resfulapi/screens/settings_screen.dart';

class AppRoutes {
  static const String homeScreenRouter = 'home-screen';
  static const String addTodoScreeRouter = 'add-todo-screen';
  static const String completedTaskScreenRouter = 'completed-task-screen';
  static const String editTodoScreenRouter = 'edit-todo-screen';
  static const String authRouter = 'auth';
  static const String settingsRouter = 'settings';

  static final routes = {
    homeScreenRouter: (context) => const HomeScreen(),
    addTodoScreeRouter: (context) => const AddTaskScreen(),
    editTodoScreenRouter: (context) => const EditTaskScreen(),
    completedTaskScreenRouter: (context) => const CompletedTasksScreen(),
    authRouter: (context) => const AuthPage(),
    settingsRouter: (context) => const SettingsScreen(),
  };
}
