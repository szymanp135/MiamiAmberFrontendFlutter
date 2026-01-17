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
      setState(() => _userData = data);
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
            /*Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(_userData!['user']['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_userData!['user']['description'] ?? "No description", style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),*/
            const Divider(),
            // Użycie wspólnego grida z sortowaniem
            Expanded(child: ResponsivePostGrid(posts: userPosts)),
          ],
        ],
      ),
    );
  }
}