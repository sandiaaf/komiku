import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komiku/class/category.dart';
import 'package:komiku/class/comic.dart';
import 'package:komiku/screen/bacakomik.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KomikFavorit extends StatefulWidget {
  const KomikFavorit({super.key});

  @override
  State<StatefulWidget> createState() {
    return _KomikFavoritState();
  }
}

class _KomikFavoritState extends State<KomikFavorit> {
  String _searchQuery = "";
  int _selectedCategory = 0;
  List<Category> _categories = [];
  List<Comic> _comics = [];
  bool _isLoading = true;

  void _refreshHomeData() {
    fetchComics();
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchComics();
  }

  void fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/kategori.php"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      setState(() {
        _categories = data.map((json) => Category.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _categories = [];
        _isLoading = false;
      });
    }
  }

  Future<void> fetchComics() async {
    String _userId = '';
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isLoading = true;
      _userId = prefs.getString('user_id') ?? '';
    });

    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/komikfavorit.php"),
      body: {
        'cari': _searchQuery,
        'kategori': _selectedCategory.toString(),
        'user_id':_userId,
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

  void sortComics(String sortBy) {
    setState(() {
      if (sortBy == "asc") {
        _comics.sort((a, b) => a.judul.compareTo(b.judul));
      } else if (sortBy == "desc") {
        _comics.sort((a, b) => b.judul.compareTo(a.judul));
      } else if (sortBy == "rate") {
        _comics.sort((a, b) => double.parse(b.rating??"").compareTo(double.parse(a.rating??"")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Komik Favorit"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      fetchComics();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari komik...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.id;
                          });
                          fetchComics();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedCategory == category.id
                                ? Colors.deepPurpleAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              category.nama,
                              style: TextStyle(
                                color: _selectedCategory == category.id
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        "Sort by:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => sortComics("asc"),
                        child: const Text("ASC"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => sortComics("desc"),
                        child: const Text("DESC"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => sortComics("rate"),
                        child: const Text("Rate"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                              builder: (context) =>
                                  BacaKomik(komikID: comic.id),
                            ),
                          );
                          // Setelah kembali dari BacaKomik, refresh data komik
                          fetchComics();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5,
                                spreadRadius: 2,
                              )
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
