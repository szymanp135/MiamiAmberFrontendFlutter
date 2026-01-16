import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _mbidController = TextEditingController();
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  double _rating = 50;
  bool _isLoading = false;

  // Tekst legendy ocen (Issue 6)
  final String ratingGuide = """
0 worst of all time
10 close to as horrible as it gets
20 bad
30 horrible
40 indifferent
50 listenable
60 good
70 very good
80 amazing
90 close to as good as it gets
100 best of all time""";

  Future<void> _fetchMusicBrainz() async {
    // ... (logika MusicBrainz bez zmian)
    final mbid = _mbidController.text.trim();
    if (mbid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().fetchMusicBrainzData(mbid);
      if (data['title'] != null) _albumController.text = data['title'];
      if (data['artist-credit'] != null && (data['artist-credit'] as List).isNotEmpty) {
        final artists = (data['artist-credit'] as List).map((a) => a['name']).join(', ');
        _artistController.text = artists;
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    // ... (logika submit bez zmian)
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log in first!")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final req = CreatePostRequest(
        title: _titleController.text,
        artist: _artistController.text,
        album: _albumController.text,
        musicBrainzId: _mbidController.text.isEmpty ? null : _mbidController.text,
        text: _textController.text,
        rating: _rating.toInt(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      );
      await ApiService().createPost(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post created!")));
        _formKey.currentState!.reset();
        setState(() => _rating = 50);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Używamy LayoutBuilder, żeby sprawdzić czy zmieścimy panel boczny
    return Scaffold(
      appBar: AppBar(title: const Text("Create Review")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), // Szerszy kontener, żeby zmieścić panel boczny
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEWA STRONA: Formularz
                Expanded(
                  flex: 3,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: "Review Title", border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: TextFormField(controller: _mbidController, decoration: const InputDecoration(labelText: "MBID", border: OutlineInputBorder()))),
                          const SizedBox(width: 8),
                          ElevatedButton(onPressed: _isLoading ? null : _fetchMusicBrainz, child: const Text("Load"))
                        ]),
                        const SizedBox(height: 16),
                        TextFormField(controller: _artistController, decoration: const InputDecoration(labelText: "Artist", border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        TextFormField(controller: _albumController, decoration: const InputDecoration(labelText: "Album", border: OutlineInputBorder())),
                        const SizedBox(height: 16),

                        // Issue 5: Skalujący się tekst
                        TextFormField(
                          controller: _textController,
                          decoration: const InputDecoration(labelText: "Review Text", border: OutlineInputBorder()),
                          minLines: 4, // Startuje od 4 linii
                          maxLines: null, // Rośnie w nieskończoność (do granic scrolla strony)
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),

                        const SizedBox(height: 16),
                        TextFormField(controller: _tagsController, decoration: const InputDecoration(labelText: "Tags", border: OutlineInputBorder())),
                        const SizedBox(height: 24),
                        Text("Rating: ${_rating.toInt()}/100", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Slider(value: _rating, min: 0, max: 100, divisions: 100, label: _rating.round().toString(), onChanged: (v) => setState(() => _rating = v), activeColor: kMiamiAmberColor),
                        const SizedBox(height: 24),
                        FilledButton(onPressed: _isLoading ? null : _submit, style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Review")),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // PRAWA STRONA: Panel z ocenami (Issue 6)
                // Wyświetlamy tylko na szerszych ekranach, ale zakładamy desktop
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kMiamiAmberColor, // Kolor marki
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(2, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Rating Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                        const Divider(color: Colors.black54),
                        Text(ratingGuide, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}