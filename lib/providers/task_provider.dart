import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  List<Task> _tasks = [];
  // Filtering & sorting
  String _filterStatus = 'pendiente'; // changed default from 'all' to 'pendiente'
  String? _filterCategory;
  String _sortOption = 'created_desc';
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get visibleTasks {
    var list = List<Task>.from(_tasks);

    // Apply status filter
    if (_filterStatus != 'all') {
      list = list.where((t) => t.status == _filterStatus).toList();
    }

    // Apply category filter
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      list = list.where((t) => t.category == _filterCategory).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case 'title_asc':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'created_asc':
        list.sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));
        break;
      case 'created_desc':
      default:
        list.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    }

    return list;
  }
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  bool get isSyncing => _isSyncing;

  /// Getters for filtered tasks
  List<Task> get pendingTasks =>
    _tasks.where((task) => task.isPending).toList();
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  int get totalTasks => _tasks.length;

  /// Initialize Provider
  Future<void> init() async {
    try {
      _setLoading(true);
      await _taskRepository.init();
      await _checkConnectivity();
      await getAllTasks();
      await _updatePendingSyncCount();
    } catch (e) {
      _setError('Failed to initialize Provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set filter and sort options
  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setSortOption(String option) {
    _sortOption = option;
    notifyListeners();
  }

  String get currentSortOption => _sortOption;

  String get currentFilterStatus => _filterStatus;

  /// Get all tasks from Repository
  Future<void> getAllTasks() async {
    try {
      _setLoading(true);
      _clearError();

      _tasks = await _taskRepository.getAllTasks();
      await _checkConnectivity();
      await _updatePendingSyncCount();

      debugPrint('Tasks loaded: ${_tasks.length} tasks');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new task
  Future<void> createTask(String title, String description, {String? imagePath, String? category, int? dueAt}) async {
    try {
      _clearError();
      _setLoading(true);

  final newTask = await _taskRepository.createTask(
        title,
        description,
        imagePath: imagePath,
        category: category,
        dueAt: dueAt,
      );

      // Add new task to local list (for immediate UI update)
  _tasks.add(newTask);
      await _updatePendingSyncCount();

      debugPrint('Task created successfully: ${newTask.title}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to create task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing task
  Future<void> updateTask(Task task) async {
    try {
      _clearError();
      _setLoading(true);

      final updatedTask = await _taskRepository.updateTask(task);

      // Update task in local list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await _updatePendingSyncCount();

        debugPrint('Task updated successfully: ${updatedTask.title}');
      } else {
        _setError('Task not found in local list');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to update task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      _clearError();
      _setLoading(true);

      await _taskRepository.deleteTask(taskId);

      // Xóa task khỏi list local
      _tasks.removeWhere((task) => task.id == taskId);
      await _updatePendingSyncCount();

      debugPrint('Task deleted successfully: $taskId');
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      _clearError();
      _setLoading(true);

      final toggledTask = await _taskRepository.toggleTaskCompletion(task);

      // Update task in local list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = toggledTask;
        await _updatePendingSyncCount();

        debugPrint(
          'Task completion toggled: ${toggledTask.title} - ${toggledTask.status}',
        );
      } else {
        _setError('Failed to toggle task completion: Task not found in local');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle task completion: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get single task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return await _taskRepository.getTaskById(taskId);
    } catch (e) {
      debugPrint('Provider: Error getting task by ID - $e');
      return null;
    }
  }

  /// Refresh tasks (Pull to refresh)
  Future<void> refreshTasks() async {
    try {
      _clearError();
      _setLoading(true);

      await _checkConnectivity();

      // Only reload tasks, NO auto sync
      await getAllTasks();

      debugPrint('Tasks refreshed successfully');
    } catch (e) {
      _setError('Failed to refresh tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync pending operations (manual user action)
  Future<void> syncPendingOperations() async {
    try {
      if (!_isOnline) {
        debugPrint('Cannot sync: No internet connection');
        return;
      }

      debugPrint('=== SYNC STARTED ===');
      debugPrint('Before sync - Pending count: $_pendingSyncCount');

      _isSyncing = true;
      notifyListeners();

      await _taskRepository.syncPendingOperations();

      debugPrint('Repository sync completed, updating pending count...');
      await _updatePendingSyncCount();
      debugPrint('After sync - New pending count: $_pendingSyncCount');

      // Reload tasks after sync
      await getAllTasks();

      debugPrint('=== SYNC COMPLETED ===');
      debugPrint('Final pending count: $_pendingSyncCount');
    } catch (e) {
      debugPrint('Provider: Error syncing pending operations - $e');
      _setError('Failed to sync pending operations: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear all tasks (for testing/debugging)
  Future<void> clearAllTasks() async {
    try {
      _setLoading(true);
      await _taskRepository.clearAllTasks();
      _tasks.clear();
      _pendingSyncCount = 0;
      notifyListeners();
      debugPrint('All tasks cleared');
    } catch (e) {
      _setError('Failed to clear all tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      _isOnline = await _taskRepository.isOnline();
      debugPrint('Connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      debugPrint('Provider: Error checking connectivity - $e');
      _isOnline = false;
    }
  }

  /// Update pending sync count
  Future<void> _updatePendingSyncCount() async {
    try {
      final pendingOperations =
          await _taskRepository.getPendingSyncOperations();
      final previousCount = _pendingSyncCount;
      _pendingSyncCount = pendingOperations.length;

      debugPrint('=== PENDING COUNT UPDATE ===');
      debugPrint('Previous count: $previousCount');
      debugPrint('New count: $_pendingSyncCount');
      debugPrint('Operations found: ${pendingOperations.length}');

      if (pendingOperations.isNotEmpty) {
        debugPrint('Pending operations details:');
        for (int i = 0; i < pendingOperations.length; i++) {
          final op = pendingOperations[i];
          debugPrint(
            '  $i: ${op['operation']} - ${op['task']['title']} (synced: ${op['synced']})',
          );
        }
      }
      debugPrint('=============================');
    } catch (e) {
      debugPrint('Provider: Error updating pending sync count - $e');
      _pendingSyncCount = 0;
    }
  }

  /// Search tasks by title or description
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;

    return _tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get tasks by status
  List<Task> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('Provider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  /// Manual connectivity refresh (for UI button)
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
    await _updatePendingSyncCount();
    notifyListeners();
  }

  /// Get connectivity status text for UI
  String get connectivityStatusText {
    if (_isSyncing) {
      return 'Syncing...';
    }
    if (_isOnline) {
      return _pendingSyncCount > 0
          ? 'Online - $_pendingSyncCount pending sync(s)'
          : 'Online - All synced';
    } else {
      return _pendingSyncCount > 0
          ? 'Offline - $_pendingSyncCount pending sync(s)'
          : 'Offline';
    }
  }

  /// Get connectivity status color for UI
  Color get connectivityStatusColor {
    if (_isSyncing) {
      return AppColorsPath.syncingBlue;
    }
    if (_isOnline) {
      return _pendingSyncCount > 0
          ? AppColorsPath.pendingOrange
          : AppColorsPath.onlineGreen;
    } else {
      return AppColorsPath.offlineRed;
    }
  }

  /// Check if a specific task has pending sync
  Future<bool> taskHasPendingSync(String taskId) async {
    try {
      return await _taskRepository.taskHasPendingSync(taskId);
    } catch (e) {
      debugPrint('Provider: Error checking task pending sync - $e');
      return false;
    }
  }

  /// Force clear all sync queue (for debugging)
  Future<void> clearAllSyncQueue() async {
    try {
      await _taskRepository.clearAllSyncQueue();
      await _updatePendingSyncCount();
      notifyListeners();
      debugPrint('All sync queue cleared from Provider');
    } catch (e) {
      debugPrint('Provider: Error clearing sync queue - $e');
    }
  }
}
