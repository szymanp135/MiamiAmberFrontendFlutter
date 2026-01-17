import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          bottom: TabBar(
            indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white70,
            tabs: const [
              Tab(text: "Settings", icon: Icon(Icons.settings)), // Settings teraz po lewej
              Tab(text: "Profile", icon: Icon(Icons.person)),   // Profile teraz po prawej
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SettingsTabContent(),
            _ProfileTabContent(),
          ],
        ),
      ),
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
                subtitle: Text(settingsProvider.sortNewestFirst ? "Newest posts first" : "Oldest posts first"),
                trailing: Switch(
                  value: settingsProvider.sortNewestFirst,
                  activeColor: kMiamiAmberColor,
                  onChanged: (val) => settingsProvider.setSortOrder(val),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text('Miami Amber App $versionText', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}

// --- ZAKŁADKA PROFILE ---
class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: kMiamiAmberColor),
            const SizedBox(height: 20),
            const Text("You are logged in!", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            )
          ],
        ),
      );
    } else {
      return const _AuthFormsWidget();
    }
  }
}

class _AuthFormsWidget extends StatefulWidget {
  const _AuthFormsWidget();

  @override
  State<_AuthFormsWidget> createState() => _AuthFormsWidgetState();
}

class _AuthFormsWidgetState extends State<_AuthFormsWidget> {
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_loginUserCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.login(_loginUserCtrl.text, _loginPassCtrl.text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_regUserCtrl.text.isEmpty || _regPassCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().register(_regUserCtrl.text, _regPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered! Now login above.")));
        _loginUserCtrl.text = _regUserCtrl.text;
        _regUserCtrl.clear();
        _regPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Register Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text("Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _loginUserCtrl,
                decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                textInputAction: TextInputAction.next, // Przejdź do hasła po Enter
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _loginPassCtrl,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(), // Wywołaj login po Enter
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login"),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 2),
              const SizedBox(height: 40),

              const Text("New here? Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _regUserCtrl,
                decoration: const InputDecoration(labelText: "Choose Username", border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regPassCtrl,
                decoration: const InputDecoration(labelText: "Choose Password", border: OutlineInputBorder()),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleRegister(), // Wywołaj rejestrację po Enter
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading ? const CircularProgressIndicator() : const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}