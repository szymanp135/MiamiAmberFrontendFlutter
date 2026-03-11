import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/pages/page_user.dart';

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
      // Zmiana klucza zmusza widget do ponownego pobrania danych
      _refreshKey = UniqueKey();
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
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Follow someone to display their name here.",
                      textAlign: TextAlign.center),
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
