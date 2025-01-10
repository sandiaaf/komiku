import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  late ComicDetail comic;
  bool _isLoading = true;
  TextEditingController _commentController = TextEditingController();
  double _averageRating = 0.0;
  int userRating = 0;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    fetchComicDetails();
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
        comic = ComicDetail.fromJson(data['data'] ?? {});
        userRating = comic.rating?.firstWhere(
              (rating) => rating['username'] == _userName,
              orElse: () => {'rating': 0},
            )['rating'] ??
            0;
        _averageRating = _calculateAverageRating(comic.rating);
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
        userRating = comic.rating?.firstWhere(
              (rating) => rating['user_id'] == _userId,
              orElse: () => {'rating': 0},
            )['rating'] ??
            0;
        _averageRating = _calculateAverageRating(comic.rating);
      });
    } else {
      print("Failed to submit rating.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? "Loading..." : comic.judul),
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
                              comic.thumbnail,
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
                                    comic.judul,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      "Kategori: ${comic.kategori?.map((cat) => cat['kategori']).join(', ') ?? 'Unknown'}"),
                                  Text("Rilis: ${comic.tanggal_rilis}"),
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
                                  "Pengarang: ${comic.pengarang ?? 'Unknown'}",
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Deskripsi: ${comic.deskripsi ?? 'No description available.'}",
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
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditKomik(komikID: comic.id),
                          ),
                        );
                        fetchComicDetails();
                      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0),
                        ),
                        child: const Text("Edit"),
                      ),
                    ),
                  ),


                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: comic.konten?.map(
                                (page) => ClipRect(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Image.network(
                                      "https://ubaya.xyz/flutter/160421110/uas/" +page,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              )
                              .toList() ??
                          [],
                    ),
                  ),


                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          itemCount: comic.komentar?.length ?? 0,
                          itemBuilder: (context, index) {
                            final comment = comic.komentar![index];
                            return ListTile(
                              title: Text(comment['nama'] ?? "Anonymous"),
                              subtitle: Text(comment['isi'] ?? ""),
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
