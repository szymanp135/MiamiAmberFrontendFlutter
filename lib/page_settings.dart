import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
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
                  subtitle: Text(settingsProvider.sortNewestFirst ? "Newest posts first" : "Oldest posts first"),
                  trailing: Switch(
                    value: settingsProvider.sortNewestFirst,
                    activeColor: kMiamiAmberColor,
                    onChanged: (val) => settingsProvider.setSortOrder(val),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text("Miami Amber App v1.260117.0", style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}