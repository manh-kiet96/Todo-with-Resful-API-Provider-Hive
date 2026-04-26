// lib/screens/completed_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';
import 'package:todo_with_resfulapi/widgets/connectivity_banner_widget.dart';
import 'package:todo_with_resfulapi/widgets/connectivity_indicator_widget.dart';
import 'package:todo_with_resfulapi/widgets/empty_state_widget.dart';
import 'package:todo_with_resfulapi/widgets/task_item_widget_completed_screen.dart';
import 'package:todo_with_resfulapi/widgets/dialog_widget_completed_screen.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  bool _showDashed = true;
  bool _swipeToDeleteEnabled = true;

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Show dashed line for completed items'),
                  value: _showDashed,
                  onChanged: (v) => setState(() => _showDashed = v),
                ),
                SwitchListTile(
                  title: const Text('Enable swipe-to-delete'),
                  value: _swipeToDeleteEnabled,
                  onChanged: (v) => setState(() => _swipeToDeleteEnabled = v),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (_, taskProvider, __) {
        return Scaffold(
          backgroundColor: AppColorsPath.sunburn,
          appBar: AppBar(
            backgroundColor: AppColorsPath.grey, // changed to grey
            title: AppText(
              title: 'Completed Tasks',
              style: AppTextStyle.textFont24W600.copyWith(
                color: AppColorsPath.white,
              ),
            ),
            actions: [
              // Connectivity Status Indicator
              ConnectivityIndicatorWidget(),

              // Refresh Button
              IconButton(
                icon: Icon(Icons.refresh, color: AppColorsPath.white),
                onPressed: () => taskProvider.refreshTasks(),
              ),

              // Settings (dashed + swipe toggles)
              IconButton(
                icon: Icon(Icons.settings, color: AppColorsPath.white),
                onPressed: _openSettingsSheet,
                tooltip: 'View display & delete options',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => taskProvider.refreshTasks(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Connectivity Status Banner
                  ConnectivityBannerWidget(),
                  // Body
                  Expanded(
                    child: taskProvider.completedTasks.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.check_circle_outline,
                            title: 'No completed tasks yet',
                            subtitle: 'Complete some tasks to see them here',
                          )
                        : ListView.separated(
                            itemCount: taskProvider.completedTasks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = taskProvider.completedTasks[index];

                              // When swipe-to-delete is disabled just render the item directly
                              final itemWidget = CompletedTaskItemWidget(
                                task: task,
                                taskProvider: taskProvider,
                                showDashed: _showDashed, // controlled by settings sheet
                              );

                              if (!_swipeToDeleteEnabled) {
                                return itemWidget;
                              }

                              // Swipe-to-delete enabled: wrap with Dismissible
                              return Dismissible(
                                key: ValueKey(task.id ?? index),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  final confirmed =
                                      await DialogWidgetCompletedScreen
                                          .showDeleteConfirmDialog(
                                              context, task);
                                  return confirmed == true;
                                },
                                onDismissed: (direction) {
                                  taskProvider.deleteTask(task.id ?? '');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Task deleted')),
                                    );
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColorsPath.errorRed,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                child: itemWidget,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
