import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';
import 'package:todo_with_resfulapi/routes/app_routes.dart';
import 'package:todo_with_resfulapi/widgets/dialog_widget_home_screen.dart';
import 'dart:io';

class HomeTaskItemWidget extends StatelessWidget {
  final Task task;

  const HomeTaskItemWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final isCompleted = task.isCompleted;

        final titleStyle = AppTextStyle.textFontSM13W600.copyWith(
          color: AppColorsPath.sunburn,
          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: AppColorsPath.sunburn,
          decorationThickness: 1.5,
        );

        final descStyle = AppTextStyle.textFontR10W400.copyWith(
          color: AppColorsPath.black,
          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
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
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Task Status Indicator (for local tasks or tasks with pending sync)
              FutureBuilder<bool>(
                future: task.id?.startsWith('local_') == true
                    ? Future.value(true)
                    : taskProvider.taskHasPendingSync(task.id ?? ''),
                builder: (context, snapshot) {
                  final hasPendingSync = snapshot.data ?? false;

                  if (hasPendingSync) {
                    return Container(
                      width: 4,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColorsPath.warningOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }
                  return const SizedBox(width: 8);
                },
              ),

              // Thumbnail (if image available)
              if (task.imagePath != null && task.imagePath!.isNotEmpty)
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(task.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText(
                            title: task.title,
                            style: titleStyle,
                          ),
                        ),
                        // Created/due time
                        if (task.createdAt != null)
                          Text(
                            _formatTimestamp(task.createdAt!),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: AppText(
                          title: task.description,
                          style: descStyle,
                        ),
                      ),
                    if (task.category != null && task.category!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Category: ${task.category}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),

                    // Pending sync indicator (secondary, small badge)
                    FutureBuilder<bool>(
                      future: task.id?.startsWith('local_') == true
                          ? Future.value(true)
                          : taskProvider.taskHasPendingSync(task.id ?? ''),
                      builder: (context, snapshot) {
                        final hasPendingSync = snapshot.data ?? false;

                        if (hasPendingSync) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(top: 8),
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
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),

              // Action Buttons: Edit, Complete (delete removed from item UI)
              _buildActionButton(
                context,
                icon: Icons.edit,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editTodoScreenRouter,
                    arguments: task,
                  );
                },
              ),
              
              _buildActionButton(
                context,
                icon: Icons.check_circle_outlined,
                color: AppColorsPath.successGreen,
                onPressed: () => _showCompleteConfirmDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  IconButton _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      visualDensity: VisualDensity.compact,
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

  // (delete removed) individual item delete action is no longer available; swipe-to-delete remains on the list

  // Show complete confirmation dialog
  Future<void> _showCompleteConfirmDialog(BuildContext context) async {
    final confirmed = await DialogWidgetHomeScreen.showCompleteConfirmDialog(
      context,
      task,
    );

    if (confirmed == true && context.mounted) {
      context.read<TaskProvider>().toggleTaskCompletion(task);
    }
  }
}
