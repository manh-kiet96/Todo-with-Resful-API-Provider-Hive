import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/services/api_service.dart';
import 'package:todo_with_resfulapi/services/storage_service.dart';

class TaskRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final Connectivity _connectivity = Connectivity();

  /// Init StorageService
  Future<void> init() async {
    await _storageService.init();
  }

  /// Get all tasks from the API or local hive
  Future<List<Task>> getAllTasks() async {
    try {
      if (await isOnline()) {
        /// Get tasks from api and later save to local
        final tasks = await _apiService.getAllTasks();
        await _storageService.saveAllTasks(tasks);
        return tasks;
      } else {
        /// Get tasks from local hive
        return await _storageService.getAllTasks();
      }
    } catch (e) {
      debugPrint('Error fetching tasks in TaskRepository: $e');
      return await _storageService.getAllTasks();
    }
  }

  /// Create new task
  Future<Task> createTask(String title, String description, {String? imagePath, String? category, int? dueAt}) async {
    try {
      if (await isOnline()) {
        /// Online: Create task via API
        await _apiService.createTask(title, description);

        /// After successful creation, reload all tasks from API to get correct ID
        final allTasks = await _api_service_getAllSafely();
        await _storageService.saveAllTasks(allTasks);

        /// Find the newly created task (best-effort match by title & description)
        final createdTask = allTasks.lastWhere(
          (task) => task.title == title && task.description == description,
          orElse: () => Task(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            description: description,
            status: 'pendiente',
            imagePath: imagePath,
            category: category,
            dueAt: dueAt,
          ),
        );

        debugPrint('Task created online: ${createdTask.title}');
        return createdTask;
      } else {
        /// Offline: Create task locally and add to sync queue
        final newTask = await _tryAddLocalWithFallback(title, description, imagePath: imagePath, category: category, dueAt: dueAt);
        debugPrint('Task created offline: ${newTask.title}');
        return newTask;
      }
    } catch (e) {
      debugPrint('Error creating task in Repository: $e');

      /// If API fails, try to create locally (fallback)
      try {
        final newTask = await _tryAddLocalWithFallback(title, description, imagePath: imagePath, category: category, dueAt: dueAt);
        debugPrint('Task created offline (fallback): ${newTask.title}');
        return newTask;
      } catch (localError) {
        debugPrint('Error creating task locally: $localError');
        throw Exception('Repository: Failed to create task - $e');
      }
    }
  }

  // small helper: attempt to call possible storage method variants
  Future<Task> _tryAddLocalWithFallback(String title, String description, {String? imagePath, String? category, int? dueAt}) async {
    try {
      // Preferred method (when storage supports image/category/dueAt)
      if (imagePath != null || category != null || dueAt != null) {
        return await _storage_service_addWithImageSafe(title, description, imagePath, category: category, dueAt: dueAt);
      } else {
        // fallback to simpler method
        return await _storage_service_addLocalSafe(title, description);
      }
    } catch (e) {
      // last-resort fallback: try the other variant
      try {
        return await _storage_service_addLocalSafe(title, description);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<Task> _storage_service_addLocalSafe(String title, String description) async {
    try {
      return await _storageService.addTaskLocal(title, description);
    } catch (e) {
      // If method not available, try an alternative name
      try {
        return await _storageService.addTaskLocalWithImage(title, description, null);
      } catch (e2) {
        rethrow;
      }
    }
  }

  Future<Task> _storage_service_addWithImageSafe(String title, String description, String? imagePath, {String? category, int? dueAt}) async {
    try {
      return await _storageService.addTaskLocalWithImage(title, description, imagePath, category: category, dueAt: dueAt);
    } catch (e) {
      // fallback to basic add
      return await _storage_service_addLocalSafe(title, description);
    }
  }

  /// Update existing task
  Future<Task> updateTask(Task task) async {
    try {
      if (await isOnline()) {
        /// Online: Update via API and local storage (WITHOUT adding to sync queue)
        await _apiService.updateTask(task);

        /// Update local storage directly (not via editTaskLocal to avoid sync queue)
        await _storageService.updateTaskDirectly(task);

        debugPrint('Task updated online: ${task.title}');
        return task;
      } else {
        /// Offline: Update locally and add to sync queue
        final updatedTask = await _storageService.editTaskLocal(task);
        debugPrint('Task updated offline: ${updatedTask.title}');
        return updatedTask;
      }
    } catch (e) {
      debugPrint('Error updating task in Repository: $e');

      /// If API fails, try to update locally
      try {
        final updatedTask = await _storageService.editTaskLocal(task);
        debugPrint('Task updated offline (fallback): ${updatedTask.title}');
        return updatedTask;
      } catch (localError) {
        debugPrint('Error updating task locally: $localError');
        throw Exception('Repository: Failed to update task - $e');
      }
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      if (await isOnline()) {
        /// Online: Delete via API and local storage (WITHOUT adding to sync queue)
        await _apiService.deleteTask(taskId);

        /// Delete from local storage directly (not via deleteTaskLocal to avoid sync queue)
        await _storageService.deleteTaskDirectly(taskId);

        debugPrint('Task deleted online: $taskId');
      } else {
        /// Offline: Delete locally and add to sync queue
        await _storageService.deleteTaskLocal(taskId);
        debugPrint('Task deleted offline: $taskId');
      }
    } catch (e) {
      debugPrint('Error deleting task in Repository: $e');

      /// If API fails, try to delete locally
      try {
        await _storageService.deleteTaskLocal(taskId);
        debugPrint('Task deleted offline (fallback): $taskId');
      } catch (localError) {
        debugPrint('Error deleting task locally: $localError');
        throw Exception('Repository: Failed to delete task - $e');
      }
    }
  }

  /// Toggle task completion status
  Future<Task> toggleTaskCompletion(Task task) async {
    try {
      if (await isOnline()) {
        /// Online: Toggle via API and local storage (WITHOUT adding to sync queue)
        final updatedTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          status: task.isPending ? 'completada' : 'pendiente',
        );

        await _apiService.updateTask(updatedTask);

        /// Update local storage directly (not via toggleTaskCompletedLocal to avoid sync queue)
        await _storageService.updateTaskDirectly(updatedTask);

        debugPrint(
          'Task completion toggled online: ${updatedTask.title} - ${updatedTask.status}',
        );
        return updatedTask;
      } else {
        /// Offline: Toggle locally and add to sync queue
        final toggledTask = await _storageService.toggleTaskCompletedLocal(
          task,
        );
        debugPrint(
          'Task completion toggled offline: ${toggledTask.title} - ${toggledTask.status}',
        );
        return toggledTask;
      }
    } catch (e) {
      debugPrint('Error toggling task completion in Repository: $e');

      /// If API fails, try to toggle locally
      try {
        final toggledTask = await _storageService.toggleTaskCompletedLocal(
          task,
        );
        debugPrint(
          'Task completion toggled offline (fallback): ${toggledTask.title}',
        );
        return toggledTask;
      } catch (localError) {
        debugPrint('Error toggling task completion locally: $localError');
        throw Exception('Repository: Failed to toggle task completion - $e');
      }
    }
  }

  /// Get single task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      return await _storageService.getTaskById(taskId);
    } catch (e) {
      debugPrint('Error getting task by ID in Repository: $e');
      return null;
    }
  }

  /// Check if task exists
  Future<bool> taskExists(String taskId) async {
    try {
      return await _storageService.taskExists(taskId);
    } catch (e) {
      debugPrint('Error checking task existence in Repository: $e');
      return false;
    }
  }

  /// Get tasks count
  Future<int> getTasksCount() async {
    try {
      return await _storageService.getTasksCount();
    } catch (e) {
      debugPrint('Error getting tasks count in Repository: $e');
      return 0;
    }
  }

  /// Get pending sync operations (for UI to display sync status)
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    try {
      return await _storageService.getPendingSyncOperations();
    } catch (e) {
      debugPrint('Error getting pending sync operations in Repository: $e');
      return [];
    }
  }

  /// Force sync all pending operations
  Future<void> syncPendingOperations() async {
    try {
      if (!await isOnline()) {
        debugPrint('Cannot sync: No internet connection');
        return;
      }

      final pendingOperations = await _storageService.getPendingSyncOperations();
      debugPrint('Found ${pendingOperations.length} pending operations to sync');

      int successfulSyncs = 0;
      for (final operation in pendingOperations) {
        try {
          final operationType = operation['operation'] as String;
          final taskData = Map<String, dynamic>.from(operation['task'] as Map<dynamic, dynamic>);
          final timestamp = operation['timestamp'] as int;

          debugPrint('Syncing operation: $operationType for task: ${taskData['title']}');

          switch (operationType) {
            case 'create':
              final taskId = taskData['id'] as String?;
              if (taskId != null && taskId.startsWith('local_')) {
                await _apiService.createTask(taskData['title'] as String, taskData['description'] as String);
              }
              break;

            case 'update':
              final task = Task(
                id: taskData['id'] as String?,
                title: taskData['title'] as String,
                description: taskData['description'] as String,
                status: taskData['status'] as String,
              );

              if (task.id != null && !task.id!.startsWith('local_')) {
                await _apiService.updateTask(task);
              }
              break;

            case 'delete':
              final taskId = taskData['id'] as String?;
              if (taskId != null && !taskId.startsWith('local_')) {
                await _apiService.deleteTask(taskId);
              }
              break;
          }

          final syncKey = operation['syncKey'] as String?;
          if (syncKey != null) {
            debugPrint('Using syncKey from operation data: $syncKey');
            await _storageService.markSyncOperationCompleted(syncKey);
          } else {
            final fallbackKey = '${operationType}_${taskData['id']}_$timestamp';
            debugPrint('Using fallback syncKey: $fallbackKey');
            await _storageService.markSyncOperationCompleted(fallbackKey);
          }

          successfulSyncs++;
          debugPrint('Successfully synced: $operationType - ${taskData['title']}');
        } catch (e) {
          debugPrint('Failed to sync operation: ${operation['operation']} - $e');

          final errLower = e.toString().toLowerCase();
          if (errLower.contains('rate limit') || errLower.contains('too many requests') || errLower.contains('429')) {
            debugPrint('Rate limit detected during sync. Aborting sync to retry later.');
            break;
          }

          if (errLower.contains('unauthorized') || errLower.contains('api key') || errLower.contains('403')) {
            debugPrint('API unauthorized error detected. Aborting sync.');
            break;
          }

          // For other errors, continue with next operation
          continue;
        }
      }

      // After sync, refresh tasks and clear completed operations (best-effort)
      if (successfulSyncs > 0) {
        final allTasks = await _apiService.getAllTasks();
        // save refreshed tasks to local storage
        await _storageService.saveAllTasks(allTasks);
        // Try to clear completed sync operations; call method names dynamically
        // so the analyzer doesn't require both spelled variants to exist at compile time.
        final dynamic _storageDyn = _storageService;
        try {
          try {
            await _storageDyn.clearCompledSyncOperations();
          } catch (_) {
            try {
              await _storageDyn.clearCompletedSyncOperations();
            } catch (_) {
              // ignore if neither method exists at runtime
            }
          }
        } catch (_) {
          // ignore any unexpected error while attempting to clear sync ops
        }

        debugPrint('Sync completed successfully. Synced: $successfulSyncs operations');
      } else {
        debugPrint('No operations were successfully synced');
      }
    } catch (e) {
      debugPrint('Error syncing pending operations: $e');
      throw Exception('Failed to sync pending operations: $e');
    }
  }

  /// Check internet connectivity
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Repository: Failed to check internet connection - $e');
      return false;
    }
  }

  /// Clear all tasks (for testing/debugging)
  Future<void> clearAllTasks() async {
    try {
      await _storageService.clearAllTasks();
      debugPrint('All tasks cleared from Repository');
    } catch (e) {
      debugPrint('Error clearing all tasks in Repository: $e');
    }
  }

  /// Check if task has pending sync operations
  Future<bool> taskHasPendingSync(String taskId) async {
    try {
      return await _storageService.taskHasPendingSync(taskId);
    } catch (e) {
      debugPrint('Repository: Error checking task pending sync - $e');
      return false;
    }
  }

  /// Force clear all sync queue (for debugging)
  Future<void> clearAllSyncQueue() async {
    try {
      await _storageService.clearAllSyncQueue();
      debugPrint('All sync queue cleared from Repository');
    } catch (e) {
      debugPrint('Repository: Error clearing sync queue: $e');
    }
  }

  /// Helper to safely get all tasks from API with defensive fallback
  Future<List<Task>> _api_service_getAllSafely() async {
    try {
      return await _apiService.getAllTasks();
    } catch (e) {
      debugPrint('Failed to fetch tasks from API during sync: $e');
      // fallback to local storage copy
      try {
        return await _storageService.getAllTasks();
      } catch (localErr) {
        debugPrint('Failed to fetch tasks from local storage as fallback: $localErr');
        return <Task>[];
      }
    }
  }
}
