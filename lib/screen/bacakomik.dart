import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:komiku/class/comic.dart';
import 'package:komiku/class/comicdetail.dart';
import 'package:komiku/screen/editkomik.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BacaKomik extends StatefulWidget {
  final int komikID;

  const BacaKomik({super.key, required this.komikID});

  @override
  State<BacaKomik> createState() => _BacaKomikState();
}

class _BacaKomikState extends State<BacaKomik> {
  late ComicDetail comicDetail;
  List<Comic> _comics = [];
  bool _isLoading = true;
  TextEditingController _commentController = TextEditingController();
  double _averageRating = 0.0;
  int userRating = 0;
  String? _userId;
  String? _userName;
  String buttonFavText = "FAVORIT";

  int _selectedChapter = 0;

  @override
  void initState() {
    super.initState();
    fetchComicDetails();
    checkFavorit();
  }

  Future<void> fetchComicDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
      _userName = prefs.getString('user_name') ?? '';
    });
    if (_userId == '') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan.')));
    }

    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/detailkomik.php"),
      body: {'id': widget.komikID.toString()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        comicDetail = ComicDetail.fromJson(data['data'] ?? {});
        userRating = comicDetail.rating?.firstWhere(
              (rating) => rating['username'] == _userName,
              orElse: () => {'rating': 0},
            )['rating'] ??
            0;
        _averageRating = _calculateAverageRating(comicDetail.rating);

        if (comicDetail.kategori != null && comicDetail.kategori!.isNotEmpty) {
          final kategoriID = comicDetail.kategori![0]['id'];
          fetchComics(kategoriID);
        }

        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print("Failed to load comic details.");
    }
  }

  double _calculateAverageRating(List<Map<String, dynamic>>? ratings) {
    if (ratings == null || ratings.isEmpty) return 0.0;
    double sum = 0.0;
    for (var rating in ratings) {
      sum += double.tryParse(rating['rating']?.toString() ?? '0') ?? 0.0;
    }
    return sum / ratings.length;
  }

  Future<void> submitComment(String comment) async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/tambahkomentar.php"),
      body: {
        'idkomik': widget.komikID.toString(),
        'user_id': _userId,
        'komentar': comment,
      },
    );

    if (response.statusCode == 200) {
      fetchComicDetails();
    } else {
      print("Failed to submit comment.");
    }
  }

  Future<void> editComment(String comment, int commentId) async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/updatekomentar.php"),
      body: {
        'idkomik': widget.komikID.toString(),
        'user_id': _userId,
        'komentar': comment,
        'comment_id': commentId.toString(),
      },
    );

    if (response.statusCode == 200) {
      fetchComicDetails();
    } else {
      print("Failed to submit comment.");
    }
  }

  void _showEditPopup(String currentComment, int commentId) {
    if (commentId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Komentar ID tidak valid.")),
      );
      return;
    }

    TextEditingController _editController =
        TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Komentar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(
              labelText: "Edit Komentar",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_editController.text.isNotEmpty) {
                  editComment(_editController.text, commentId);
                  _editController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Balasan tidak boleh kosong."),
                    ),
                  );
                }
              },
              child: const Text("simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComic() async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/deletekomik.php"),
      body: {
        'idkomik': widget.komikID.toString(),
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      if (responseBody['result'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komik berhasil dihapus.")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Gagal menghapus komik: ${responseBody['message']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghubungi server.")),
      );
    }
  }

  Future<void> submitRating(String rating) async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/tambahrating.php"),
      body: {
        'idkomik': widget.komikID.toString(),
        'user_id': _userId,
        'rating': rating,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        fetchComicDetails();
        userRating = comicDetail.rating?.firstWhere(
              (rating) => rating['user_id'] == _userId,
              orElse: () => {'rating': 0},
            )['rating'] ??
            0;
        _averageRating = _calculateAverageRating(comicDetail.rating);
      });
    } else {
      print("Failed to submit rating.");
    }
  }

  Future<void> submitFavorit(int komikId) async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/tambahfavorit.php"),
      body: {
        'user_id': _userId,
        'komik_id': komikId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['result'] == 'success') {
        if (result['action'] == 'added') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Komik berhasil ditambahkan ke favorit!')),
          );
          setState(() {
            buttonFavText = "BATAL FAVORIT";
          });
        } else if (result['action'] == 'removed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Komik berhasil dihapus dari favorit!')),
          );
          setState(() {
            buttonFavText = "FAVORIT";
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal mengubah status favorit: ${result['Error']}')),
        );
      }
    } else {
      print("Failed to submit favorit. Status code: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status favorit.')),
      );
    }
  }

  Future<void> checkFavorit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
      _userName = prefs.getString('user_name') ?? '';
    });
    if (_userId == '') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan.')));
    }

    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/userlistfavorit.php"),
      body: {
        'user_id': _userId,
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['result'] == 'success') {
        bool isFavorit = false;

        for (var item in result['data']) {
          if (item['user_id'] == _userId &&
              item['komik_id'] == widget.komikID) {
            isFavorit = true;

            break;
          }
        }

        setState(() {
          buttonFavText = isFavorit ? "BATAL FAVORIT" : "FAVORIT";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal memuat status favorit: ${result['message']}')),
        );
      }
    } else {
      print("Failed to check favorit. Status code: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat status favorit.')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah Anda yakin ingin menghapus komik ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComic();
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _showReplyPopup(int commentId) {
    if (commentId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Komentar ID tidak valid.")),
      );
      return;
    }

    TextEditingController _replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Balas Komentar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _replyController,
            decoration: const InputDecoration(
              labelText: "Balas Komentar",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_replyController.text.isNotEmpty) {
                  submitReply(commentId, _replyController.text);
                  _replyController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Balasan tidak boleh kosong."),
                    ),
                  );
                }
              },
              child: const Text("Kirim Balasan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitReply(int commentId, String reply) async {
    final response = await http.post(
      Uri.parse(
          "https://ubaya.xyz/flutter/160421110/uas/tambahsubkomentar.php"),
      body: {
        'idkomik': widget.komikID.toString(),
        'comment_id': commentId.toString(),
        'user_id': _userId,
        'komentar': reply,
      },
    );

    if (response.statusCode == 200) {
      fetchComicDetails();
    } else {
      print("Failed to submit reply.");
    }
  }

  Future<void> editReply(int replyId, String reply) async {
    final response = await http.post(
      Uri.parse(
          "https://ubaya.xyz/flutter/160421110/uas/updatesubkomentar.php"),
      body: {
        'idkomik': widget.komikID.toString(),
        'balasan_id': replyId.toString(),
        'user_id': _userId,
        'komentar': reply,
      },
    );

    if (response.statusCode == 200) {
      fetchComicDetails();
    } else {
      print("Failed to submit reply.");
    }
  }

  void _showEditReplyPopup(int replyId, String currentReply) {
    if (replyId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Balasan ID tidak valid.")),
      );
      return;
    }

    TextEditingController _editReplyController =
        TextEditingController(text: currentReply);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Balasan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _editReplyController,
            decoration: const InputDecoration(
              labelText: "Edit Balasan",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_editReplyController.text.isNotEmpty) {
                  editReply(replyId, _editReplyController.text);
                  _editReplyController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Balasan tidak boleh kosong.")),
                  );
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void fetchComics(int kategoriID) async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/komik.php"),
      body: {
        'cari': '',
        'kategori': kategoriID.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      List<Comic> comics = [];
      int count = 0;

      for (var item in data) {
        comics.add(Comic.fromJson(item));
        count++;
        if (count >= 3) break;
      }

      setState(() {
        _comics = comics;
      });
    } else {
      setState(() {
        _comics = [];
      });
    }
  }

  List<List<String>> _splitIntoChapters(List<String> content) {
    List<List<String>> chapters = [];
    for (int i = 0; i < content.length; i += 4) {
      chapters.add(
          content.sublist(i, i + 4 > content.length ? content.length : i + 4));
    }
    return chapters;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    List<List<String>> chapters = [];
    if (comicDetail.konten != null && comicDetail.konten!.isNotEmpty) {
      chapters = _splitIntoChapters(comicDetail.konten!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? "Loading..." : comicDetail.judul),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.network(
                              comicDetail.thumbnail,
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comicDetail.judul,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      "Kategori: ${comicDetail.kategori?.map((cat) => cat['kategori']).join(', ') ?? 'Unknown'}"),
                                  Text(
                                    "Rilis: ${comicDetail.tanggal_rilis != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(comicDetail.tanggal_rilis)) : 'Unknown'}",
                                  ),
                                  Text(
                                      "Rating: ${_averageRating.toStringAsFixed(1)}/5"),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                child: Text(
                                  "Pengarang: ${comicDetail.pengarang ?? 'Unknown'}",
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Deskripsi: ${comicDetail.deskripsi ?? 'No description available.'}",
                          style: const TextStyle(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          submitFavorit(comicDetail.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 14.0,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              buttonFavText,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_userId == comicDetail.userId) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditKomik(komikID: comicDetail.id),
                              ),
                            );
                            fetchComicDetails();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text("EDIT"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showDeleteConfirmationDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text("DELETE"),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: chapters.isNotEmpty
                        ? Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple,
                                    width: 1,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButton<int>(
                                  value: _selectedChapter,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedChapter = value!;
                                    });
                                  },
                                  items: List.generate(
                                    chapters.length,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text(
                                        "Chapter ${index + 1}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedChapter == index
                                              ? Colors.purple
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  underline: const SizedBox(),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  style: const TextStyle(fontSize: 16),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: chapters[_selectedChapter]
                                      .map(
                                        (page) => ClipRect(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Image.network(
                                              "https://ubaya.xyz/flutter/160421110/uas/" +
                                                  page,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "Komik Serupa",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 230,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _comics.length,
                            itemBuilder: (context, index) {
                              final comic = _comics[index];
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BacaKomik(komikID: comic.id),
                                    ),
                                  );
                                  fetchComics(
                                      comicDetail.kategori?[0]['kategori']);
                                },
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(15)),
                                        child: AspectRatio(
                                          aspectRatio: 1 / 1,
                                          child: Image.network(
                                            comic.thumbnail,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                comic.rating != "0"
                                                    ? "${comic.rating}/5"
                                                    : "N/A",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        left: 8,
                                        right: 8,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            comic.judul,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Rating (Max 5)",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < userRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                submitRating((index + 1).toString());
                              },
                            );
                          }),
                        ),
                        Text(
                          "Komentar",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: "Tulis komentar...",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              submitComment(_commentController.text);
                              _commentController.clear();
                            }
                          },
                          child: const Text("Kirim Komentar"),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comicDetail.komentar?.length ?? 0,
                          itemBuilder: (context, index) {
                            final comment = comicDetail.komentar![index];
                            bool isUserComment = comment['user_id'] == _userId;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(comment['nama'] ?? ""),
                                  subtitle: Text(comment['isi'] ?? ""),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4.0, bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (isUserComment)
                                        TextButton(
                                          onPressed: () {
                                            _showEditPopup(
                                                comment['isi'], comment['id']);
                                          },
                                          child: const Text("Edit"),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          _showReplyPopup(comment['id']);
                                        },
                                        child: const Text("Balas"),
                                      ),
                                    ],
                                  ),
                                ),
                                if ((comment['balasan'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 32.0),
                                    child: Column(
                                      children: (comment['balasan'] as List)
                                          .map((reply) {
                                        bool isUserReply =
                                            reply['user_id'] == _userId;

                                        return Column(
                                          children: [
                                            ListTile(
                                              title: Text(reply['nama'] ?? ""),
                                              subtitle:
                                                  Text(reply['isi'] ?? ""),
                                            ),
                                            if (isUserReply)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      _showEditReplyPopup(
                                                          reply['id'],
                                                          reply['isi']);
                                                    },
                                                    child: const Text("Edit"),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const Divider(), // Garis pemisah
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
