class Category {
  final int id;
  final String nama;

  Category({required this.id, required this.nama});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      nama: json['nama'] as String,
    );
  }
}