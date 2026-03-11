import 'package:flutter/material.dart';
import 'package:miami_amber_frontend/api/api_service.dart';
import 'package:miami_amber_frontend/api/models.dart';
import 'package:miami_amber_frontend/constants.dart';
import 'package:miami_amber_frontend/providers/auth_provider.dart';
import 'package:miami_amber_frontend/widgets/guide_widget.dart';
import 'package:miami_amber_frontend/widgets/linkable_text.dart';
import 'package:provider/provider.dart';

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

  final String postingGuidePreface =
      """To fill in artist, album and tags data enter album's MusicBrainz ID in MBID label and press "Load" button.""";

  final String postingGuide1 =
      """To find album's MusicBrainz ID search for it at """;
  final String postingGuide2 = """musicbrainz.org""";
  final String postingGuideUrl = """https://musicbrainz.org/search""";
  final String postingGuide3 =
      """. When you find your album choose it's release and then in "Details" tab copy MBID value.""";
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
100 best of all time
""";
  final String taggingGuide =
      """In Tags field enter comma separated tags. Loading MusicBrainz data overwrites current tags.""";

  Future<bool> _fetchMusicBrainz({bool overwriteTags = true}) async {
    final mbid = _mbidController.text.trim();
    if (mbid.isEmpty) return false;
    setState(() => _isLoading = true);
    bool success = true;
    try {
      final data = await ApiService().fetchMusicBrainzData(mbid);
      if (data['title'] == null ||
          data['artist-credit'] == null ||
          data['tags'] == null ||
          (data['artist-credit'] as List).isEmpty) {
        throw Exception('Could not fetch MusicBrainz data.');
      }
      final artistCredits = data['artist-credit'] as List;
      final allTags = artistCredits
          .expand((credit) {
            final artist = credit['artist'] as Map<String, dynamic>?;
            final tags = artist?['tags'] as List?;
            return tags ?? [];
          })
          .map((t) => t['name'].toString())
          .toSet(); // toSet() usunie duplikaty (np. 'vaporwave' u obu artystów)
      for (var tag in data['tags']) {
        allTags.add(tag['name']);
      }
      final tags = allTags.isEmpty ? '' : allTags.join(', ');

      _albumController.text = data['title'];
      _artistController.text = artistCredits.map((a) => a['name']).join(', ');
      _tagsController.text = tags;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
      success = false;
    } finally {
      setState(() => _isLoading = false);
    }
    return success;
  }

  Future<void> _submit() async {
    // validate forms fill
    if (!_formKey.currentState!.validate()) return;
    // validate auth
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Log in first!")));
      return;
    }
    // validate mbid
    final mbid = _mbidController.text.trim();
    try {
      await ApiService().fetchMusicBrainzData(mbid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid MusicBrainz ID.")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final req = CreatePostRequest(
        title: _titleController.text,
        artist: _artistController.text,
        album: _albumController.text,
        musicBrainzId:
            _mbidController.text.isEmpty ? null : _mbidController.text,
        text: _textController.text,
        rating: _rating.toInt(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      );
      await ApiService().createPost(req);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Post created!")));
        _formKey.currentState!.reset();
        setState(() => _rating = 50);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _ratingGuideWidget() =>
      GuideWidget(title: "Rating Guide", text: ratingGuide);
  Widget _tagGuideWidget() =>
      GuideWidget(title: "Tagging Guide", text: taggingGuide);
  Widget _postGuideWidget(ThemeData theme) => GuideWidget(
        title: 'Posting Guide',
        text: postingGuidePreface,
        linkableText: LinkableText(
          text1: postingGuide1,
          text2: postingGuide2,
          text3: postingGuide3,
          url: postingGuideUrl,
          textStyle: guideTextStyle(theme),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Sprawdzamy, czy mamy wystarczająco dużo miejsca na układ poziomy
    final bool isWide = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar:
          AppBar(title: const Text("Create Review", style: pageTitleTextStyle)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1000 : 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GŁÓWNY FORMULARZ
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                              labelText: "Review Title",
                              border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        if (!isWide) ...[
                          const SizedBox(height: 16),
                          _postGuideWidget(theme),
                        ],
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _mbidController,
                                  decoration: const InputDecoration(
                                      labelText: "MBID",
                                      border: OutlineInputBorder()),
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null)),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              onPressed: _isLoading ? null : _fetchMusicBrainz,
                              child: const Text("Load"))
                        ]),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _artistController,
                          decoration: const InputDecoration(
                              labelText: "Artist",
                              border: OutlineInputBorder()),
                          readOnly: true,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _albumController,
                          decoration: const InputDecoration(
                              labelText: "Album", border: OutlineInputBorder()),
                          readOnly: true,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _textController,
                          decoration: const InputDecoration(
                              labelText: "Review Text",
                              border: OutlineInputBorder()),
                          minLines: 4,
                          maxLines: null,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                                labelText: "Tags",
                                border: OutlineInputBorder())),
                        if (!isWide) ...[
                          const SizedBox(height: 16),
                          _tagGuideWidget(),
                        ],
                        const SizedBox(height: 24),
                        Text("Rating: ${_rating.toInt()}/100",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Slider(
                          value: _rating,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _rating.round().toString(),
                          onChanged: (v) => setState(() => _rating = v),
                          activeColor: kMiamiAmberColor,
                        ),

                        // --- DYNAMICZNY ELEMENT ---
                        // Jeśli ekran jest wąski, wstawiamy legendę tutaj
                        if (!isWide) ...[
                          const SizedBox(height: 16),
                          _ratingGuideWidget(),
                        ],

                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(18)),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Submit Review"),
                        ),
                      ],
                    ),
                  ),

                  // Jeśli ekran jest szeroki, pokazujemy panel z boku
                  if (isWide) ...[
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _postGuideWidget(theme),
                          const SizedBox(height: 16),
                          _ratingGuideWidget(),
                          const SizedBox(height: 16),
                          _tagGuideWidget(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
