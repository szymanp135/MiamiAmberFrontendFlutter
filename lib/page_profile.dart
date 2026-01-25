import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/page_user.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isLoggedIn) {
      return const LoginRegisterScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      // CustomScrollView pozwala na łączenie różnych efektów scrollowania
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000),
          child: CustomScrollView(
            slivers: [
              // 1. Sekcja nagłówka (Logo i status)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 80, color: kMiamiAmberColor),
                      SizedBox(height: 10),
                      Text("You are logged in!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // 2. Sekcja "Obserwowani" (Nagłówek sekcji)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 16, top: 10, bottom: 8),
                  child: Text("Following", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // 3. Dynamiczna lista obserwowanych
              const FollowingSliverList(),

              // 4. Przycisk Logout na dole
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ),

              // Miejsce na Twoje "późniejsze plany" - po prostu dodawaj kolejne Slivery tutaj
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

class FollowingSliverList extends StatefulWidget {
  const FollowingSliverList({super.key});

  @override
  State<FollowingSliverList> createState() => _FollowingSliverListState();
}

class _FollowingSliverListState extends State<FollowingSliverList> {
  // Klucz do wymuszenia odświeżenia FutureBuilder
  Key _refreshKey = UniqueKey();

  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey(); // Zmiana klucza zmusza widget do ponownego pobrania danych
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return FutureBuilder<int?>(
      future: api.getCurrentUserId(),
      builder: (context, idSnapshot) {
        if (!idSnapshot.hasData || idSnapshot.data == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return FutureBuilder<List<dynamic>>(
          key: _refreshKey, // Przypisujemy klucz tutaj
          future: api.getFollowing(idSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("You don't follow anyone yet.", textAlign: TextAlign.center),
                ),
              );
            }

            final following = snapshot.data!;

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final user = following[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: kMiamiAmberColor,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user['name'] ?? "Unknown"),
                    subtitle: Text("User ID: ${user['id']}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // NAWIGACJA Z ODŚWIEŻENIEM
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserSearchScreen(
                            initialUsername: user['name'],
                          ),
                        ),
                      ).then((_) {
                        // Ta funkcja wykona się po powrocie (Navigator.pop)
                        _refresh();
                      });
                    },
                  );
                },
                childCount: following.length,
              ),
            );
          },
        );
      },
    );
  }
}
