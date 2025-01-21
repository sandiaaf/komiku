class ComicDetail {
  final int id;
  final String judul;
  final String deskripsi;
  final String thumbnail;
  final String tanggal_rilis;
  final String pengarang;
  final String? userId;
  final List<Map<String, dynamic>>? rating;
  final List<Map<String, dynamic>>? kategori;
  final List<String>? konten;
  final List<Map<String, dynamic>>? komentar;
  String? userRating;

  ComicDetail({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.thumbnail,
    required this.tanggal_rilis,
    required this.pengarang,
    this.userId,
    this.rating,
    this.kategori,
    this.konten,
    this.komentar,
    this.userRating,
  });

  factory ComicDetail.fromJson(Map<String, dynamic> json) {
    return ComicDetail(
      id: json['id'] as int,
      judul: json['judul'] as String,
      deskripsi: json['deskripsi'] as String,
      thumbnail: json['thumbnail'] as String,
      tanggal_rilis: json['tanggal_rilis'] as String,
      pengarang: json['pengarang'] as String,
      userId: json['user_id'],
      rating: (json['rating'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      kategori: (json['kategori'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      konten: (json['konten'] as List?)
          ?.map((e) => e as String)
          .toList(),
      komentar: (json['komentar'] as List?)
          ?.map((e) => {
                'id': e['id'],
                'nama': e['nama'],
                'isi': e['isi'],
                'balasan': e['balasan'] ?? [],
              })
          .toList(),
      userRating: json['userRating'] as String?,
    );
  }
}