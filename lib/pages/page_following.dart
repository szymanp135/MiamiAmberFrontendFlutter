import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/api/models.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/widgets/responsive_post_grid.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});
  @override
  State<FollowingScreen> createState() => _FollwingScreenState();
}

class _FollwingScreenState extends State<FollowingScreen> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = ApiService().getFollowingPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following', style: pageTitleTextStyle),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (!ApiService().isLoggedIn) {
              return const Center(child: SelectableText('Not logged in.'));
            }
            return Center(
                child: SelectableText('Error: ${snapshot.error.toString()}'));
          }
          return ResponsivePostGrid(posts: snapshot.data ?? []);
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _refreshPosts, child: const Icon(Icons.refresh)),
    );
  }
}
