import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'common_widgets.dart';
import 'models.dart';

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
        title: const Text('Following'),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: SelectableText('Error: ${snapshot.error}'));
          return ResponsivePostGrid(posts: snapshot.data ?? []);
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _refreshPosts, child: const Icon(Icons.refresh)),
    );
  }
}
