import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/providers/auth_provider.dart';
import 'package:miami_amber_frontend/widgets/following_sliver_list.dart';
import 'package:miami_amber_frontend/widgets/guide_widget.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final String followingGuide =
      """To follow a user go to users page and check Follow checkbox.""";

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return const LoginRegisterScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile", style: pageTitleTextStyle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: CustomScrollView(
            slivers: [
              // Logo and status
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle,
                          size: 80, color: kMiamiAmberColor),
                      SizedBox(height: 10),
                      Text("You are logged in!",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Logout button
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 32, right: 32, bottom: 32, top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => auth.logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),

              // Following header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 16, top: 10, bottom: 8),
                  child: Text("Following",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              // Following guide
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsGeometry.all(8),
                  child: GuideWidget(
                      title: "Following Guide", text: followingGuide),
                ),
              ),
              // Following list
              const FollowingSliverList(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});
  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
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
        await ApiService()
            .register(_usernameController.text, _passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registered! Now login.")));
        }
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black54
              : Colors.white70,
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
          TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                  labelText: "Username", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                  labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
              onSubmitted: (_) => _handleAuth(isLogin)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : () => _handleAuth(isLogin),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(isLogin ? "Login" : "Register"),
          ),
        ],
      ),
    );
  }
}
