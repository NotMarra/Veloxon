import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _selectedPaths = [];
  final String _storageKey = 'scanned_paths';

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPaths = prefs.getStringList(_storageKey) ?? [];
    });
  }

  Future<void> _savePaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _selectedPaths);
  }

  Future<void> _addFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null && !_selectedPaths.contains(path)) {
      setState(() {
        _selectedPaths.add(path);
      });
      await _savePaths();
    }
  }

  void _removePath(int index) {
    setState(() {
      _selectedPaths.removeAt(index);
    });
    _savePaths();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Settings')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder, color: Colors.blue),
            title: const Text('Add Folder to Scan'),
            subtitle: const Text('Select where you have movies'),
            onTap: _addFolder,
          ),
          const Divider(),
          Expanded(
            child: _selectedPaths.isEmpty
                ? const Center(child: Text('No folders selected.'))
                : ListView.builder(
                    itemCount: _selectedPaths.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(_selectedPaths[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePath(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
