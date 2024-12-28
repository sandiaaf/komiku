import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:komiku/class/category.dart';
import 'package:komiku/screen/daftarkomik.dart';

class Kategori extends StatefulWidget {
  const Kategori({super.key});

  @override
  State<StatefulWidget> createState() {
    return _KategoriState();
  }
}

class _KategoriState extends State<Kategori> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
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
        _categories = data
            .map((json) => Category.fromJson(json))
            .where((category) => category.nama.toLowerCase() != 'all')
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _categories = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DaftarKomik(
                          kategoriID: category.id,
                          kategoriNama: category.nama,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      category.nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}