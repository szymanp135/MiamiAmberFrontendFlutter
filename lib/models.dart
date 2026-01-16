class User {
  final int id;
  final String name;
  final String? description;

  User({required this.id, required this.name, this.description});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class Post {
  final int id;
  final String title;
  final String? artist;
  final String? album;
  final String? musicBrainzId;
  final String text;
  final int? rating;
  final DateTime date;
  final User? user;
  final List<String> tags;

  Post({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.musicBrainzId,
    required this.text,
    this.rating,
    required this.date,
    this.user,
    required this.tags,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      musicBrainzId: json['musicbrainz_id'],
      text: json['text'],
      rating: json['rating'],
      date: DateTime.parse(json['date']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Helper do pobierania okładki
  String? get coverArtUrl {
    if (musicBrainzId != null && musicBrainzId!.isNotEmpty) {
      return "https://coverartarchive.org/release/$musicBrainzId/front-250";
    }
    return null;
  }
}

class CreatePostRequest {
  final String title;
  final String artist;
  final String album;
  final String? musicBrainzId;
  final String text;
  final int rating;
  final List<String> tags;

  CreatePostRequest({
    required this.title,
    required this.artist,
    required this.album,
    this.musicBrainzId,
    required this.text,
    required this.rating,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "artist": artist,
      "album": album,
      "musicBrainzId": musicBrainzId,
      "text": text,
      "rating": rating,
      "tags": tags,
    };
  }
}