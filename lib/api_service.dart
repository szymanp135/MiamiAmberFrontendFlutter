import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  static const String baseUrl = "https://amber.miami.monster/api";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);

    Map<String, dynamic> payload = _parseJwt(token);
    if (payload.containsKey('id')) {
      await prefs.setInt('userId', payload['id']);
    }
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    await prefs.remove('userId');
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getInt('userId') == null) {
      prefs.clear();
      throw Exception('Not logged in');
    }
    return prefs.getInt('userId');
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String token = data['token'];
      await saveToken(token);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<List<Post>> getPosts() async {
    final response = await http.get(Uri.parse('$baseUrl/posts'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> createPost(CreatePostRequest request) async {
    final token = await getToken();
    if (token == null) throw Exception("Not logged in");

    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> searchUser(String nickname) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/byname/$nickname'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Error searching user');
    }
  }

  // Get list of people who user_id is following
  // This function *was at some point* written manually by a human.
  Future<List<dynamic>> getFollowing(int user_id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$user_id/following'),
    );
    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Error searching user');
    }
  }

  // Followowanie użytkownika
  Future<void> followUser(int userId) async {
    final token = await getToken();
    if (token == null) throw Exception("Not logged in");

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400 && response.body.contains('Already')){
        throw Exception('Already following this user');
      }
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  // Od-followowanie użytkownika
  Future<void> unfollowUser(int userId) async {
    final token = await getToken();
    if (token == null) throw Exception("Not logged in");

    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400 && response.body.contains('Already')){
        throw Exception('Already not following this user');
      }
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  // Sprawdza czy zalogowany user followuje targetUserId
  Future<bool> isFollowing(int targetUserId) async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('Log in first');
    }

    // Jeśli sprawdzasz swój własny profil, to technicznie nie followujesz samego siebie
    if (currentUserId == targetUserId) return false;

    final followingList = await getFollowing(currentUserId);

    // Iterujemy po liście obiektów zwróconych przez API
    for (var user in followingList) {
      if (user['id'] == targetUserId) {
        return true;
      }
    }
    return false;
  }

  // get posts people you follow
  Future<List<Post>> getFollowingPosts() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/posts/following'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // To jest kluczowe dla FastAPI
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Post.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Not logged in');
    } else {
      throw Exception('Error loading following posts');
    }
  }

  // Funkcja MusicBrainz z index.html przepisana na Dart
  Future<Map<String, dynamic>> fetchMusicBrainzData(String mbid) async {
    final url = "https://musicbrainz.org/ws/2/release/$mbid?inc=artists+tags&fmt=json";
    final response = await http.get(
      Uri.parse(url),
      headers: {"User-Agent": "MiamiAmber/1.0 (contact@miami.monster)"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('MBID not found or invalid');
    }
  }

  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
      default: throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }
}
