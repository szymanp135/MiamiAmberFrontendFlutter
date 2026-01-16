import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'models.dart';

// --- Helper do naprawy znaków HTML ---
final unescape = HtmlUnescape();
String fixText(String text) => unescape.convert(text);

class ResponsivePostGrid extends StatelessWidget {
  final List<Post> posts;
  const ResponsivePostGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const Center(child: Text('No posts found.'));

    final settings = Provider.of<SettingsProvider>(context);

    // Sortowanie (Issue 4)
    final sortedPosts = List<Post>.from(posts);
    sortedPosts.sort((a, b) {
      // Domyślne sortowanie API vs Wymuszone nasze
      // Zakładamy, że API zwraca różnie, więc sortujemy po dacie
      if (settings.sortNewestFirst) {
        return b.date.compareTo(a.date); // Najnowsze na górze
      } else {
        return a.date.compareTo(b.date); // Najstarsze na górze
      }
    });

    return Column(
      children: [
        // Pasek filtrów
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Sort by: "),
              DropdownButton<bool>(
                value: settings.sortNewestFirst,
                items: const [
                  DropdownMenuItem(value: true, child: Text("Newest first")),
                  DropdownMenuItem(value: false, child: Text("Oldest first")),
                ],
                onChanged: (val) {
                  if (val != null) settings.setSortOrder(val);
                },
              ),
            ],
          ),
        ),
        // Właściwa siatka Masonry
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: MasonryGridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 3, // Zawsze 3 kolumny
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: sortedPosts.length,
                itemBuilder: (context, index) {
                  return VerticalPostCard(post: sortedPosts[index]);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VerticalPostCard extends StatelessWidget {
  final Post post;
  const VerticalPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Karta nie ma stałej wysokości, dopasowuje się do zawartości (Issue 2)
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // Ważne: zajmuje tyle miejsca ile potrzebuje
        children: [
          // 1. Obrazek - Zawsze KWADRAT (Issue 1)
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              color: Colors.black12,
              child: post.coverArtUrl != null
                  ? Image.network(
                post.coverArtUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.music_note, size: 50, color: Colors.grey)),
              )
                  : const Center(child: Icon(Icons.album, size: 50, color: Colors.grey)),
            ),
          ),
          // 2. Treść - Pełna długość tekstu (Issue 2)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  fixText(post.title),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  "${fixText(post.artist ?? '')} • ${fixText(post.album ?? '')}",
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const Divider(height: 20),
                // Tekst recenzji w całości
                SelectableText(
                  fixText(post.text),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: kMiamiAmberColor),
                    Text(" ${post.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy-MM-dd').format(post.date),
                      style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
                if (post.user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SelectableText(
                      "by ${post.user!.name}",
                      style: TextStyle(fontSize: 11, color: kMiamiAmberColor, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}