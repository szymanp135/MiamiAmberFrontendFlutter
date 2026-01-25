import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _SettingsTabContent(),
    );
  }
}

// --- ZAKŁADKA SETTINGS ---
class _SettingsTabContent extends StatelessWidget {
  const _SettingsTabContent();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                title: const Text("Dark Mode"),
                subtitle: const Text("Enable dark theme for the application"),
                secondary: const Icon(Icons.dark_mode),
                value: themeProvider.isDarkMode,
                activeColor: kMiamiAmberColor,
                onChanged: (bool value) => themeProvider.toggleTheme(value),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sort),
                title: const Text("Default Sort Order"),
                trailing: DropdownButton<SortingType>(
                  value: settingsProvider.sortingType,
                  items: const [
                    DropdownMenuItem(
                        value: SortingType.byNewest, child: Text("Newest first")),
                    DropdownMenuItem(
                        value: SortingType.byOldest, child: Text("Oldest first")),
                    DropdownMenuItem(
                        value: SortingType.byMostRated, child: Text("Most Rated first")),
                    DropdownMenuItem(
                        value: SortingType.byLeastRated, child: Text("Least Rated first")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      settingsProvider.setSortOrder(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
                child: Text('Miami Amber App $versionText',
                    style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
