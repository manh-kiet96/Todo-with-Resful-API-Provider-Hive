import 'package:flutter/material.dart';
import 'package:todo_with_resfulapi/services/settings_service.dart';
import 'package:todo_with_resfulapi/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _useMock = false;
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _settings.init();
    if (!mounted) return;
    setState(() {
      _useMock = _settings.getUseMock();
      _apiKeyController.text = _settings.getApiKey() ?? ''; // load saved api key
    });
  }

  // Quick test the RapidAPI key by setting it on ApiService and calling GET
  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    ApiService.setApiKey(key.isEmpty ? null : key);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing RapidAPI key...')));
    try {
      final svc = ApiService();
      await svc.getAllTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RapidAPI key valid — fetched tasks successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Test failed: ${e.toString()}')));
    }
  }

  Future<void> _save() async {
    await _settings.setUseMock(_useMock);
    await _settings.setApiKey(_apiKeyController.text.trim()); // persist api key
    ApiService.useMock = _useMock;
    ApiService.setApiKey(_apiKeyController.text.trim()); // apply immediately

    // profile remains in-screen only; user edits via Profile dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // RapidAPI details / helper
            const Text('RapidAPI host', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const SelectableText('x-rapidapi-host: task-manager-api3.p.rapidapi.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            // RapidAPI key input (allows user to paste new key)
            const Text('RapidAPI Key (optional)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste RapidAPI key here (leave empty to use local FastAPI)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // quick-fill example key from your curl (paste only if you trust it)
                    _apiKeyController.text = '5cccf55fbfmsha4f89acf4595db2p13853ajsn8add119d960e';
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Example key filled — press Test or Save')));
                  },
                  child: const Text('Use example key'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _testApiKey,
                  child: const Text('Test RapidAPI Key'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mock toggle remains
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Use Mock API (local)', style: TextStyle(fontSize: 16)),
                Switch(
                  value: _useMock,
                  onChanged: (v) => setState(() => _useMock = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}
