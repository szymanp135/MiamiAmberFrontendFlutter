import 'package:flutter/material.dart';

import 'api_service.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'models.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}
class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() { _isLoading = true; _userData = null; });
    try {
      final data = await ApiService().searchUser(_searchController.text.trim());
      setState(() { _userData = data; });
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Post> userPosts = [];
    if (_userData != null) {
      userPosts = (_userData!['posts'] as List).map((p) => Post.fromJson(p)).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Find User")),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(labelText: "Username", border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search)),
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: kMiamiAmberColor),
          if (_userData != null) ...[
            const Divider(),
            // Użycie wspólnego grida z sortowaniem
            Expanded(child:
              ResponsivePostGrid(
                posts: userPosts,
                scrollableHead: UserHeader(userData: _userData!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/*
Widget userNameBar(Map<String, dynamic> userData) {
  print(userData);
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Text(userData['user']['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(userData['user']['description'] ?? "No description", style: const TextStyle(fontStyle: FontStyle.italic)),
      ],
    ),
  );
}*/

class UserHeader extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserHeader({
    super.key,
    required this.userData,
  });

  @override
  State<UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isMe = false; // Czy to profil zalogowanego użytkownika?
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final targetUserId = widget.userData['user']['id'];
      final currentUserId = await _api.getCurrentUserId();

      if (currentUserId == targetUserId) {
        if (mounted) setState(() { _isMe = true; _isLoading = false; });
        return;
      }

      // Sprawdzamy czy followujemy tego usera
      final status = await _api.isFollowing(targetUserId);

      if (mounted) {
        setState(() {
          _isFollowing = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Header status error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(bool? value) async {
    if (value == null || _isLoading) return;

    // 1. Optymistyczna zmiana w UI
    setState(() {
      _isFollowing = value;
    });

    final targetUserId = widget.userData['user']['id'];

    try {
      if (value) {
        await _api.followUser(targetUserId);
      } else {
        await _api.unfollowUser(targetUserId);
      }
    } catch (e) {
      // 2. Jeśli wystąpił błąd, cofamy zmianę w UI
      if (mounted) {
        setState(() {
          _isFollowing = !value; // Przywracamy poprzedni stan
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString().replaceAll('Exception:', '')}"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            widget.userData['user']['name'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.userData['user']['description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.userData['user']['description'],
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ) else 
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'No description provided',
                  style: TextStyle(fontStyle: FontStyle.italic)
                ),
              ),
          const SizedBox(height: 10),

          // Logika wyświetlania przycisku
          if (_isMe)
            const Chip(label: Text("This is your profile"))
          else if (_isLoading)
            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isFollowing,
                  onChanged: _toggleFollow,
                  activeColor: kMiamiAmberColor,
                ),
                Text(_isFollowing ? "Following" : "Follow"),
              ],
            ),
        ],
      ),
    );
  }
}
