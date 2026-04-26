import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';
import 'package:todo_with_resfulapi/widgets/dialog_widget_completed_screen.dart';

class CompletedTaskItemWidget extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;
  final bool showDashed;

  const CompletedTaskItemWidget({
    super.key,
    required this.task,
    required this.taskProvider,
    this.showDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyle.textFontSM13W600.copyWith(
      color: AppColorsPath.sunburn,
      decoration: showDashed ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColorsPath.sunburn,
      decorationThickness: 1.5,
    );

    final descStyle = AppTextStyle.textFontR10W400.copyWith(
      color: AppColorsPath.black,
      decoration: showDashed ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColorsPath.sunburn,
      decorationThickness: 1.2,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColorsPath.white,
        boxShadow: [
          BoxShadow(
            color: AppColorsPath.shadowGrey,
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Task Status Indicator (for local tasks or tasks with pending sync)
          FutureBuilder<bool>(
            future:
                task.id?.startsWith('local_') == true
                    ? Future.value(true)
                    : taskProvider.taskHasPendingSync(task.id ?? ''),
            builder: (context, snapshot) {
              final hasPendingSync = snapshot.data ?? false;

              if (hasPendingSync) {
                return Container(
                  width: 4,
                  height: 40,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColorsPath.warningOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title: task.title,
                  style: titleStyle,
                ),

                if (task.description.isNotEmpty)
                  AppText(
                    title: task.description,
                    style: descStyle,
                  ),

                // timestamp (created or due)
                if (task.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      _formatTimestamp(task.createdAt!),
                      style: TextStyle(fontSize: 11, color: AppColorsPath.grey),
                    ),
                  ),

                // Pending sync indicator
                FutureBuilder<bool>(
                  future:
                      task.id?.startsWith('local_') == true
                          ? Future.value(true)
                          : taskProvider.taskHasPendingSync(task.id ?? ''),
                  builder: (context, snapshot) {
                    final hasPendingSync = snapshot.data ?? false;

                    if (hasPendingSync) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColorsPath.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColorsPath.warningOrange,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Pending sync',
                          style: TextStyle(
                            color: AppColorsPath.warningOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Action Buttons - delete icon removed; undo & completed indicator remain
          IconButton(
            onPressed: () => _showUndoConfirmDialog(context),
            icon: Icon(Icons.undo_rounded, color: AppColorsPath.warningOrange),
            visualDensity: VisualDensity.compact,
          ),

          Icon(Icons.check_circle, color: AppColorsPath.successGreen, size: 30),
        ],
      ),
    );
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  // Show undo confirmation dialog
  Future<void> _showUndoConfirmDialog(BuildContext context) async {
    final confirmed = await DialogWidgetCompletedScreen.showUndoConfirmDialog(
      context,
      task,
    );

    if (confirmed == true) {
      taskProvider.toggleTaskCompletion(task);
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await DialogWidgetCompletedScreen.showDeleteConfirmDialog(
      context,
      task,
    );

    if (confirmed == true) {
      taskProvider.deleteTask(task.id ?? '');
    }
  }
}
