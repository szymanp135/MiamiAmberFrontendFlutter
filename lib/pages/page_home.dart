import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/api/models.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/widgets/responsive_post_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = ApiService().getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miami Amber', style: pageTitleTextStyle),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SelectableText('Error: ${snapshot.error}'));
          }
          return ResponsivePostGrid(posts: snapshot.data ?? []);
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _refreshPosts, child: const Icon(Icons.refresh)),
    );
  }
}
