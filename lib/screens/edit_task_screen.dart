import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/components/text_field.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/models/task.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Task task;
  String? _imagePath;
  int? _dueAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      task = ModalRoute.of(context)?.settings.arguments as Task;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _categoryController.text = task.category ?? '';
      _imagePath = task.imagePath;
      _dueAt = task.dueAt;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedTask = task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      imagePath: _imagePath,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      dueAt: _dueAt,
    );

    if (mounted) {
      await context.read<TaskProvider>().updateTask(updatedTask);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsPath.sunburnLight,
      appBar: AppBar(
        backgroundColor: AppColorsPath.sunburn,
        title: AppText(
          title: 'Edit Task',
          style: AppTextStyle.textFont24W600.copyWith(
            color: AppColorsPath.white,
          ),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (_, taskProvider, __) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _titleController,
                    labelText: 'Title',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Image picker preview + button
                  Row(
                    children: [
                      _imagePath == null
                          ? Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePath!),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (picked != null) {
                            setState(() {
                              _imagePath = picked.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _categoryController,
                    labelText: 'Category (optional)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _dueAt != null ? DateTime.fromMillisecondsSinceEpoch(_dueAt!) : DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_dueAt != null ? DateTime.fromMillisecondsSinceEpoch(_dueAt!) : DateTime.now()),
                              );
                              final dt = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime?.hour ?? 0,
                                pickedTime?.minute ?? 0,
                              );
                              setState(() {
                                _dueAt = dt.millisecondsSinceEpoch;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_dueAt == null ? 'Set due date' : 'Due: ${_formatTimestamp(_dueAt!)}'),
                        ),
                      ),
                      if (_dueAt != null)
                        IconButton(
                          onPressed: () => setState(() => _dueAt = null),
                          icon: Icon(Icons.clear),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              taskProvider.isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              taskProvider.isLoading ? null : _updateTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorsPath.sunburn,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              taskProvider.isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Update',
                                    style: TextStyle(color: Colors.white),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
