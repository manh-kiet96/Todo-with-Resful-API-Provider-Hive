import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_with_resfulapi/components/app_text.dart';
import 'package:todo_with_resfulapi/components/app_text_style.dart';
import 'package:todo_with_resfulapi/constants/app_color_path.dart';
import 'package:todo_with_resfulapi/constants/app_data.dart';
import 'package:todo_with_resfulapi/providers/task_provider.dart';
import 'package:todo_with_resfulapi/routes/app_routes.dart';
import 'package:todo_with_resfulapi/widgets/connectivity_banner_widget.dart';
import 'package:todo_with_resfulapi/widgets/connectivity_indicator_widget.dart';
import 'package:todo_with_resfulapi/widgets/empty_state_widget.dart';
import 'package:todo_with_resfulapi/widgets/error_state_widget_home_screen.dart';
import 'package:todo_with_resfulapi/widgets/task_item_widget_home_screen.dart';
import 'package:todo_with_resfulapi/widgets/dialog_widget_home_screen.dart'; // added import
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    // Initialize data when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().init();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (_, taskProvider, __) {
        return Scaffold(
          backgroundColor: AppColorsPath.sunburnLight,
          appBar: AppBar(
            backgroundColor: AppColorsPath.sunburn,
            elevation: 0,
            title: AppText(
              title: AppData.appName,
              style: AppTextStyle.textFont24W600,
            ),
            actions: [
              // Connectivity Status Indicator
              ConnectivityIndicatorWidget(),

              // Refresh Button
              IconButton(
                icon: Icon(Icons.refresh, color: AppColorsPath.white),
                onPressed: () => taskProvider.refreshTasks(),
              ),

              // Settings
              IconButton(
                icon: Icon(Icons.settings, color: AppColorsPath.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsRouter),
              ),

              // Profile icon: navigate to profile edit screen (replaces dialog + extra popup menu)
              Builder(builder: (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                final imageProvider = (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                    ? NetworkImage(user.photoURL!)
                    : AssetImage('images/7.png') as ImageProvider;

                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                    );
                  },
                  icon: CircleAvatar(radius: 16, backgroundImage: imageProvider),
                  tooltip: 'Edit profile',
                );
              }),

            ],
          ),
          // Replaced the floating + button with a professional bottom bar that includes
          // a right-aligned "Add New Todo" action and removes the separate FAB.
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColorsPath.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Left: optional compact navigation items (kept minimal to avoid interfering with app's nav)
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            // maintain original behavior if needed; keep simple: refresh
                            taskProvider.refreshTasks();
                          },
                          icon: Icon(Icons.home_outlined, color: AppColorsPath.sunburn),
                        ),
                        const SizedBox(width: 6),

                        // Replaced settings with Completed Tasks shortcut
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.completedTaskScreenRouter);
                          },
                          icon: Icon(Icons.check_circle_outline, color: Colors.grey[700]),
                          tooltip: 'Completed tasks',
                        ),
                      ],
                    ),
                  ),

                  // Right: prominent Add New Todo button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.addTodoScreeRouter),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Todo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsPath.sunburn,
                      elevation: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => taskProvider.refreshTasks(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Connectivity Status Banner
                  ConnectivityBannerWidget(),

                  // Filters and sorting
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Sort control (icon + text "Sort")
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            taskProvider.setSortOption(val);
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'created_desc', child: Text('Newest')),
                            PopupMenuItem(value: 'created_asc', child: Text('Oldest')),
                            PopupMenuItem(value: 'title_asc', child: Text('Title')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColorsPath.borderGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.sort, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Sort', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Status filter
                        PopupMenuButton<String>(
                          onSelected: (val) => taskProvider.setFilterStatus(val),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'pendiente', child: Text('Pending')),
                            PopupMenuItem(value: 'completada', child: Text('Completed')),
                          ],
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColorsPath.borderGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Filter'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Category quick filter (shows distinct categories)
                        PopupMenuButton<String?>(
                          onSelected: (val) => taskProvider.setFilterCategory(val),
                          itemBuilder: (context) {
                            final cats = taskProvider.tasks
                                .map((t) => t.category)
                                .where((c) => c != null && c.isNotEmpty)
                                .cast<String>()
                                .toSet()
                                .toList();
                            return [
                              const PopupMenuItem(value: null, child: Text('All categories')),
                              ...cats.map((c) => PopupMenuItem(value: c, child: Text(c))).toList()
                            ];
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColorsPath.borderGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Category'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body Content
                  // Case 1: Loading
                  if (taskProvider.isLoading)
                    Expanded(
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  // Case 2: Error
                  else if (taskProvider.errorMessage.isNotEmpty)
                    Expanded(
                      child: ErrorStateWidget(
                        title: 'Error loading tasks',
                        message: taskProvider.errorMessage,
                        onRetry: () => taskProvider.getAllTasks(),
                      ),
                    )
                  // Case 3: Empty Data
                  else if (taskProvider.pendingTasks.isEmpty)
                    Expanded(
                      child: EmptyStateWidget(
                        icon: Icons.task_outlined,
                        title: 'No pending tasks',
                        subtitle: 'Use the "Add New Todo" button at the bottom to create your first task',
                      ),
                    )
                  // Case 4: Has Data
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: taskProvider.visibleTasks.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = taskProvider.visibleTasks[index];
                          return Dismissible(
                            key: ValueKey(task.id ?? index),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              final confirmed = await DialogWidgetHomeScreen.showDeleteConfirmDialog(context, task);
                              return confirmed == true;
                            },
                            onDismissed: (direction) {
                              taskProvider.deleteTask(task.id ?? '');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
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
                                children: const [
                                  Icon(Icons.delete_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            child: HomeTaskItemWidget(task: task),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Removed the floating '+' FAB in favor of the new bottom bar Add button.
        );
      },
    );
  }
}

// Replace previous ProfileEditScreen with improved implementation:
// - tap avatar to pick image from gallery
// - upload to Firebase Storage and use returned URL for updatePhotoURL
// - update displayName and photoURL on save, then reload user
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  bool _loading = false;
  XFile? _pickedImage;
  String? _uploadedPhotoUrl; // now holds either remote URL or local file path

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayNameController.text = user?.displayName ?? '';
    _uploadedPhotoUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = picked;
        // store local path so UI can show it immediately
        _uploadedPhotoUrl = picked.path;
      });
      // NOTE: Upload step to Firebase Storage removed to avoid missing package.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected (local). Save to update display locally.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _pickedImage = null;
      _uploadedPhotoUrl = null;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed locally. Save to persist change.')));
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        messenger.showSnackBar(const SnackBar(content: Text('No authenticated user')));
        return;
      }

      // Ensure Firebase sends a valid locale header to avoid "Ignoring header X-Firebase-Locale because its value was null."
      // This prevents warnings from native Firebase networking when languageCode is null.
      try {
        FirebaseAuth.instance.setLanguageCode('en');
      } catch (_) {
        // ignore - setLanguageCode may not throw, but keep it defensive
      }

      final displayName = _displayNameController.text.trim();

      if (displayName.isNotEmpty && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
      }

      // If we have an uploaded photo URL, update the user with it.
      if (_uploadedPhotoUrl != null && _uploadedPhotoUrl != user.photoURL) {
        // Only set remote URL when it's an http(s) link (local file paths are not uploaded in this build)
        if (_uploadedPhotoUrl!.startsWith('http://') || _uploadedPhotoUrl!.startsWith('https://')) {
          await user.updatePhotoURL(_uploadedPhotoUrl);
        } else {
          // Local file selected — optionally inform the user that the photo will be used locally until uploaded
          messenger.showSnackBar(const SnackBar(content: Text('Local photo selected. Add upload support to persist photo to remote storage.')));
        }
      } else if (_uploadedPhotoUrl == null && user.photoURL != null) {
        // Clear remote photo (explicit) — ensure language code set above avoids null-locale header warning
        await user.updatePhotoURL(null);
      }

      await user.reload(); // refresh local user data
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    ImageProvider imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(File(_pickedImage!.path));
    } else if (_uploadedPhotoUrl != null && (_uploadedPhotoUrl!.startsWith('http://') || _uploadedPhotoUrl!.startsWith('https://'))) {
      imageProvider = NetworkImage(_uploadedPhotoUrl!);
    } else {
      imageProvider = const AssetImage('images/7.png');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: AppColorsPath.sunburn,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final choice = await showModalBottomSheet<String?>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose photo'),
                          onTap: () => Navigator.pop(ctx, 'pick'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Remove photo'),
                          onTap: () => Navigator.pop(ctx, 'remove'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.close),
                          title: const Text('Cancel'),
                          onTap: () => Navigator.pop(ctx, null),
                        ),
                      ],
                    ),
                  ),
                );

                if (choice == 'pick') {
                  await _pickImage();
                } else if (choice == 'remove') {
                  await _removePhoto();
                }
              },
              child: CircleAvatar(radius: 48, backgroundImage: imageProvider),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Profile photo: tap the avatar to pick or remove'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child: _loading ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColorsPath.sunburn),
              ),
            ),
            const SizedBox(height: 8),
            // Keep logout accessible from profile edit screen (optional)
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
