import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komiku/class/comic.dart';
import 'package:komiku/screen/bacakomik.dart';

class DaftarKomik extends StatefulWidget {
  final int kategoriID;
  final String kategoriNama;

  const DaftarKomik({
    super.key,
    required this.kategoriID,
    required this.kategoriNama,
  });

  @override
  State<StatefulWidget> createState() {
    return _DaftarKomikState();
  }
}

class _DaftarKomikState extends State<DaftarKomik> {
  List<Comic> _comics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComics();
  }

  void fetchComics() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/komik.php"),
      body: {
        'cari': '',
        'kategori': widget.kategoriID.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      setState(() {
        _comics = data.map((json) => Comic.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _comics = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategoriNama),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.6,
              ),
              itemCount: _comics.length,
              itemBuilder: (context, index) {
                final comic = _comics[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BacaKomik(komikID: comic.id),
                      ),
                    );
                    fetchComics();
                  },
                  child: Container(
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
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
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
                              borderRadius: BorderRadius.circular(8),
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
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              comic.judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
    );
  }
}
