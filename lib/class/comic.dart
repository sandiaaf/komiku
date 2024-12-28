class Comic {
  final int id;
  final String judul;
  final String thumbnail;
  final String? rating;

  Comic({
    required this.id,
    required this.judul,
    required this.thumbnail,
    this.rating,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'] as int,
      judul: json['judul'] as String,
      thumbnail: json['thumbnail'] as String,
      rating: json['rating']?.toString(),
    );
  }
}