import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:komiku/class/category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:komiku/class/comicdetail.dart';

class EditKomik extends StatefulWidget {
  final int komikID;

  const EditKomik({super.key, required this.komikID});

  @override
  State<EditKomik> createState() => _EditKomikState();
}

class _EditKomikState extends State<EditKomik> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controllerDate = TextEditingController();
  final TextEditingController _controllerJudul = TextEditingController();
  final TextEditingController _controllerDeskripsi = TextEditingController();
  final TextEditingController _controllerPengarang = TextEditingController();
  final TextEditingController _controllerThumbnail = TextEditingController();

  String? _userId;
  Uint8List? _imageBytes;
  List<Category> _kategoriList = [];
  List<int> _selectedKategori = [];
  ComicDetail? comic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKategori();
    fetchComicDetails();
  }

  Future<void> fetchKategori() async {
    final response = await http
        .get(Uri.parse('https://ubaya.xyz/flutter/160421110/uas/kategori.php'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      setState(() {
        _kategoriList = data
            .map((json) => Category.fromJson(json))
            .where((kategori) => kategori.nama != 'All')
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data kategori')));
    }
  }

  Future<void> fetchComicDetails() async {
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/detailkomik.php"),
      body: {'id': widget.komikID.toString()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        comic = ComicDetail.fromJson(data);
        _controllerJudul.text = comic?.judul ?? '';
        _controllerDeskripsi.text = comic?.deskripsi ?? '';
        _controllerDate.text = comic?.tanggal_rilis ?? '';
        _controllerPengarang.text = comic?.pengarang ?? '';
        _controllerThumbnail.text = comic?.thumbnail ?? '';
        _selectedKategori =
            (comic?.kategori ?? []).map((e) => e['id'] as int).toList();
        _isLoading = false; // Data selesai dimuat
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data komik')));
      setState(() {
        _isLoading = false; // Tetap set _isLoading meskipun gagal
      });
    }
  }

  Future<void> submit() async {
    try {
      final response = await http.post(
        Uri.parse("https://ubaya.xyz/flutter/160421110/uas/updatekomik.php"),
        body: {
          'id': widget.komikID.toString(),
          'title': _controllerJudul.text,
          'desc': _controllerDeskripsi.text,
          'rd': _controllerDate.text,
          'author': _controllerPengarang.text,
          'thumbnail': _controllerThumbnail.text,
        },
      );
      Map<String, dynamic> json = jsonDecode(response.body);
      print(json['result']);
      print(json['Error']);

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sukses Mengupdate Komik')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error mengupdate komik pada json')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error mengupdate komik')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _addCategory(int categoryId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://ubaya.xyz/flutter/160421110/uas/tambahkomikkategori.php'),
        body: {
          'id_kategori': categoryId.toString(),
          'id_komik': widget.komikID.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil ditambahkan')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menambah kategori: ${json["message"]}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error menambah kategori')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _removeCategory(int categoryId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://ubaya.xyz/flutter/160421110/uas/deletekomikkategori.php'),
        body: {
          'id_kategori': categoryId.toString(),
          'id_komik': widget.komikID.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menghapus kategori: ${json["message"]}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error menghapus kategori')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> deleteImage(String filePath) async {
    try {
      final response = await http.post(
        Uri.parse("https://ubaya.xyz/flutter/160421110/uas/deletehalaman.php"),
        body: {
          'filePath': filePath,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['result'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gambar berhasil dihapus')),
          );
          setState(() {
            fetchComicDetails();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menghapus gambar: ${json["message"]}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus gambar')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              color: Colors.white,
              child: Wrap(
                children: <Widget>[
                  ListTile(
                      tileColor: Colors.white,
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Galeri'),
                      onTap: imgGaleri),
                ],
              ),
            ),
          );
        });
  }

  imgGaleri() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxHeight: 600,
        maxWidth: 600);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void uploadScene64() async {
    String base64Image = base64Encode(_imageBytes!);
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/uploadhalaman.php"),
      body: {
        'komikId': widget.komikID.toString(),
        'base64Image': base64Image,
      },
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sukses mengupload Scene')));
        setState(() {
          fetchComicDetails();
          fetchKategori();
        });
      }
    } else {
      throw Exception('Failed to read API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Komik"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Tampilkan loading
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controllerJudul,
                        decoration: InputDecoration(
                          labelText: 'Judul',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controllerDeskripsi,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 50) {
                            return 'Deskripsi harus lebih panjang';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 3,
                        maxLines: 6,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _controllerDate,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Rilis',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2200),
                              ).then((value) {
                                setState(() {
                                  _controllerDate.text =
                                      value.toString().substring(0, 10);
                                });
                              });
                            },
                            child: const Icon(Icons.calendar_today_sharp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controllerPengarang,
                        decoration: InputDecoration(
                          labelText: 'Pengarang',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pengarang harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controllerThumbnail,
                        decoration: InputDecoration(
                          labelText: 'Thumbnail (URL)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || !Uri.parse(value).isAbsolute) {
                            return 'URL thumbnail tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "List Gambar Halaman",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (comic != null &&
                                comic!.konten != null &&
                                comic!.konten!.isNotEmpty)
                              Column(
                                children: comic!.konten!.map((page) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Image.network(
                                          "https://ubaya.xyz/flutter/160421110/uas/$page",
                                          height: 400,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                deleteImage(page);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              const Text("Tidak ada gambar halaman tersedia."),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Upload Gambar Halaman",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_imageBytes != null)
                            Image.memory(_imageBytes!,
                                height: 200, fit: BoxFit.cover),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _showPicker(context),
                            child: const Text('Pilih Gambar'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => uploadScene64(),
                            child: const Text('Upload Gambar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Kategori",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          for (var kategori in _kategoriList)
                            CheckboxListTile(
                              title: Text(kategori.nama),
                              value: _selectedKategori.contains(kategori.id),
                              onChanged: (isSelected) async {
                                setState(() {
                                  if (isSelected == true) {
                                    _selectedKategori.add(kategori.id);
                                    _addCategory(kategori.id);
                                  } else {
                                    _selectedKategori.remove(kategori.id);
                                    _removeCategory(kategori.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Harap isian diperbaiki')));
                            } else {
                              submit();
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
