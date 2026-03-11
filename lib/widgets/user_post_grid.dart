import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/api/models.dart';
import 'package:miami_amber_frontend/widgets/responsive_post_grid.dart';

class UserPostSliverGrid extends StatefulWidget {
  const UserPostSliverGrid({super.key, required this.userId});

  final int userId;

  @override
  State<UserPostSliverGrid> createState() => _UserPostSliverGridState();
}

class _UserPostSliverGridState extends State<UserPostSliverGrid> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() async {
    setState(() {
      _postsFuture = ApiService().getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }
        if (snapshot.data == null) {
          return const Center(child: SelectableText('No posts found.'));
        }

        final userPosts = snapshot.data!.where((p) => p.user != null && p.user!.id == widget.userId).toList();

        return ResponsivePostGrid(posts: userPosts);
      },
    );
  }
}
