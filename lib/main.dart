import 'package:flutter/material.dart';
import 'package:miami_amber_flutter_frontend/providers.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import 'api_service.dart';
import 'models.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MiamiAmberApp(),
    ),
  );
}

// --- Helper do naprawy znaków HTML ---
final unescape = HtmlUnescape();
String fixText(String text) => unescape.convert(text);

// --- Stałe Kolory ---
const kMiamiAmberColor = Color(0xFFFFC000); // #ffc000 - Kolor marki
const kLightBgColor = Color(0xFFfff8e5);
const kDarkBgColor = Color(0xFF1E1E1E); // Ciemny szary, przyjemny dla oka

// --- Główny Widget Aplikacji ---
class MiamiAmberApp extends StatelessWidget {
  const MiamiAmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Miami Amber',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      // --- Motyw Jasny ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kLightBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kMiamiAmberColor,
          brightness: Brightness.light,
          primary: kMiamiAmberColor, // Kolor przycisków i akcentów
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kMiamiAmberColor,
          foregroundColor: Colors.white, // Tekst na pasku
          centerTitle: true,
        ),
      ),
      // --- Motyw Ciemny ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kMiamiAmberColor,
          brightness: Brightness.dark,
          primary: kMiamiAmberColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kMiamiAmberColor,
          foregroundColor: Colors.black, // Ciemny tekst na żółtym tle wygląda lepiej
          centerTitle: true,
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

// --- Główny Layout z Bocznym Paskiem (NavigationRail) ---
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CreatePostScreen(),
    const UserSearchScreen(),
    const ProfileScreen(),
    const SettingsScreen(), // Nowa strona
  ];

  @override
  Widget build(BuildContext context) {
    // Sprawdzamy szerokość ekranu, żeby wiedzieć czy pokazać etykiety w menu
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // 1. Panel boczny (lewa krawędź)
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() => _currentIndex = index);
            },
            extended: isWideScreen, // Rozwija menu na szerokich ekranach
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            indicatorColor: kMiamiAmberColor,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search_rounded),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 2. Główna zawartość strony
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }
}

// --- Widget Siatki Postów (Dla Home i User Profile) ---
class ResponsivePostGrid extends StatelessWidget {
  final List<Post> posts;
  const ResponsivePostGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    // GridView w środku Center z ograniczeniem szerokości
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200), // Nie szersze niż 1200px
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400, // Max szerokość jednej karty
            childAspectRatio: 0.75, // Pionowy format (wysokość > szerokość)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return VerticalPostCard(post: posts[index]);
          },
        ),
      ),
    );
  }
}

// --- Nowa Karta Posta (Pionowa) ---
class VerticalPostCard extends StatelessWidget {
  final Post post;
  const VerticalPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ładnie przycina obrazek w rogach
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Obrazek (Okładka) na górze
          Expanded(
            flex: 4, // Zajmuje 40% wysokości karty (lub więcej w zależności od treści)
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
          // 2. Treść pod obrazkiem
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    fixText(post.title),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    "${fixText(post.artist ?? '')} • ${fixText(post.album ?? '')}",
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontStyle: FontStyle.italic),
                    maxLines: 1,
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        fixText(post.text),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: kMiamiAmberColor),
                      Text(" ${post.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        DateFormat('yyyy-MM-dd').format(post.date),
                        style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                  if (post.user != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: SelectableText(
                        "by ${post.user!.name}",
                        style: TextStyle(fontSize: 11, color: kMiamiAmberColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Strona 1: Home ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> _postsFuture;
  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }
  void _refreshPosts() {
    setState(() { _postsFuture = ApiService().getPosts(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Miami Amber')),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: SelectableText('Error: ${snapshot.error}'));

          // Używamy naszego nowego grida
          return ResponsivePostGrid(posts: snapshot.data ?? []);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshPosts,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// --- Strona 2: Create Post (Wąski formularz) ---
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // ... (Logika kontrolerów bez zmian)
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _mbidController = TextEditingController();
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  double _rating = 50;
  bool _isLoading = false;

  Future<void> _fetchMusicBrainz() async {
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
      if (data['tags'] != null) {
        final tags = (data['tags'] as List).take(5).map((t) => t['name']).join(', ');
        _tagsController.text = tags;
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
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
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
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
    // Ograniczamy szerokość formularza
    return Scaffold(
      appBar: AppBar(title: const Text("Create Review")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Max szerokość 600px
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mbidController,
                          decoration: const InputDecoration(labelText: "MBID (Optional)", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _isLoading ? null : _fetchMusicBrainz, child: const Text("Load"))
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _artistController,
                    decoration: const InputDecoration(labelText: "Artist", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _albumController,
                    decoration: const InputDecoration(labelText: "Album", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _textController,
                    decoration: const InputDecoration(labelText: "Review Text", border: OutlineInputBorder()),
                    maxLines: 6,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: "Tags", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  Text("Rating: ${_rating.toInt()}/100", textAlign: TextAlign.center),
                  Slider(
                    value: _rating, min: 0, max: 100, divisions: 100, label: _rating.round().toString(),
                    onChanged: (v) => setState(() => _rating = v),
                    activeColor: kMiamiAmberColor,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Review"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Strona 3: User Search (Poprawiony enter i layout) ---
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
          // Pasek wyszukiwania - też ograniczony szerokością
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  // Obsługa entera:
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: kMiamiAmberColor),

          if (_userData != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(_userData!['user']['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_userData!['user']['description'] ?? "No description", style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const Divider(),
            // Używamy tego samego ResponsivePostGrid co na głównej!
            Expanded(child: ResponsivePostGrid(posts: userPosts)),
          ],
        ],
      ),
    );
  }
}

// --- Strona 4: Profil / Login (Wąskie formularze) ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: kMiamiAmberColor),
              const SizedBox(height: 20),
              const Text("You are logged in!", style: TextStyle(fontSize: 22)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              )
            ],
          ),
        ),
      );
    } else {
      return const LoginRegisterScreen();
    }
  }
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});
  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _handleAuth(bool isLogin) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (isLogin) {
        await auth.login(_usernameController.text, _passwordController.text);
      } else {
        await ApiService().register(_usernameController.text, _passwordController.text);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered! Now login.")));
        _tabController.animateTo(0);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: "Login"), Tab(text: "Register")],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Wąski formularz
          child: TabBarView(
            controller: _tabController,
            children: [_buildForm(true), _buildForm(false)],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLogin) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            obscureText: true,
            onSubmitted: (_) => _handleAuth(isLogin), // Enter zatwierdza
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : () => _handleAuth(isLogin),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Login" : "Register"),
          ),
        ],
      ),
    );
  }
}

// --- Strona 5: Settings (Nowa) ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Enable dark theme for the application"),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeProvider.isDarkMode,
                  activeColor: kMiamiAmberColor,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text("Miami Amber App v1.0.1", style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}