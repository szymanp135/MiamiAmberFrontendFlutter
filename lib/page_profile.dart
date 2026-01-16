import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: kMiamiAmberColor),
              const SizedBox(height: 20),
              const Text("You are logged in!", style: TextStyle(fontSize: 22)),
              const SizedBox(height: 40),
              ElevatedButton.icon(onPressed: () => auth.logout(), icon: const Icon(Icons.logout), label: const Text("Logout"))
            ],
          ),
        ),
      );
    } else {
      return const LoginRegisterScreen();
    }
  }
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});
  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}
class _LoginRegisterScreenState extends State<LoginRegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleAuth(bool isLogin) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (isLogin) {
        await auth.login(_usernameController.text, _passwordController.text);
      } else {
        await ApiService().register(_usernameController.text, _passwordController.text);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered! Now login.")));
        _tabController.animateTo(0);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Naprawiony AppBar i kolory
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        bottom: TabBar(
          controller: _tabController,
          // Kolory są teraz sterowane przez Theme w main, ale tu można wymusić dla pewności
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white70,
          tabs: const [Tab(text: "Login"), Tab(text: "Register")],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: TabBarView(
            controller: _tabController,
            children: [_buildForm(true), _buildForm(false)],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLogin) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true, onSubmitted: (_) => _handleAuth(isLogin)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : () => _handleAuth(isLogin),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Login" : "Register"),
          ),
        ],
      ),
    );
  }
}