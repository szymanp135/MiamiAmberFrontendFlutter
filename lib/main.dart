import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MiamiAmberApp(),
    ),
  );
}

// --- Stan Aplikacji (Auth) ---
class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService().getToken();
    if (token != null) {
      _token = token;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final data = await ApiService().login(username, password);
    _token = data['token'];
    await ApiService().saveToken(_token!);
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().removeToken();
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

// --- Główny Widget Aplikacji ---
class MiamiAmberApp extends StatelessWidget {
  const MiamiAmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miami Amber',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC000), // Amber
          brightness: Brightness.light,
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

// --- Główny Ekran z Nawigacją ---
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- Ekran 1: Lista Postów ---
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
    setState(() {
      _postsFuture = ApiService().getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miami Amber', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshPosts(),
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No posts found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return PostCard(post: snapshot.data![index]);
              },
            );
          },
        ),
      ),
    );
  }
}

// Widget karty posta
class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.coverArtUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Image.network(
                      post.coverArtUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.album, size: 80, color: Colors.grey),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${post.artist ?? 'Unknown'} - ${post.album ?? 'Unknown'}",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(" ${post.rating}/100"),
                          const Spacer(),
                          Text(
                            DateFormat('yyyy-MM-dd').format(post.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(post.text),
            const SizedBox(height: 8),
            if (post.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: post.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            const SizedBox(height: 8),
            if (post.user != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "by ${post.user!.name}",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Ekran 2: Tworzenie Posta ---
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

  Future<void> _fetchMusicBrainz() async {
    final mbid = _mbidController.text.trim();
    if (mbid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter MBID first")));
      return;
    }
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data loaded!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final req = CreatePostRequest(
        title: _titleController.text,
        artist: _artistController.text,
        album: _albumController.text,
        musicBrainzId: _mbidController.text.isEmpty ? null : _mbidController.text,
        text: _textController.text,
        rating: _rating.toInt(),
        tags: tagsList,
      );

      await ApiService().createPost(req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post created!")));
        _formKey.currentState!.reset();
        _rating = 50;
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Review")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Review Title", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mbidController,
                      decoration: const InputDecoration(labelText: "MusicBrainz ID (Optional)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _isLoading ? null : _fetchMusicBrainz, child: const Text("Load"))
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: "Artist", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _albumController,
                decoration: const InputDecoration(labelText: "Album", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(labelText: "Review Text", border: OutlineInputBorder()),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: "Tags (comma separated)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              Text("Rating: ${_rating.toInt()}/100"),
              Slider(
                value: _rating,
                min: 0,
                max: 100,
                divisions: 100,
                label: _rating.round().toString(),
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Review"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- Ekran 3: Wyszukiwanie Użytkownika ---
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
    return Scaffold(
      appBar: AppBar(title: const Text("Find User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_userData != null) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  title: Text(_userData!['user']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_userData!['user']['description'] ?? "No description"),
                  trailing: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: (_userData!['posts'] as List).length,
                  itemBuilder: (context, index) {
                    final p = (_userData!['posts'] as List)[index];
                    // Mapowanie prostego JSONa z endpointu user na obiekt Post
                    final post = Post(
                      id: p['id'],
                      title: p['title'],
                      artist: p['artist'],
                      album: p['album'],
                      musicBrainzId: p['musicbrainz_id'],
                      text: p['text'],
                      rating: p['rating'],
                      date: DateTime.parse(p['date']),
                      tags: List<String>.from(p['tags'] ?? []),
                    );
                    return PostCard(post: post);
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// --- Ekran 4: Profil / Login ---
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
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text("You are logged in!", style: TextStyle(fontSize: 20)),
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
        _tabController.animateTo(0); // Przełącz na login
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
          tabs: const [Tab(text: "Login"), Tab(text: "Register")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(true),
          _buildForm(false),
        ],
      ),
    );
  }

  Widget _buildForm(bool isLogin) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : () => _handleAuth(isLogin),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "Login" : "Register"),
            ),
          ),
        ],
      ),
    );
  }
}