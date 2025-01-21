import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:komiku/class/category.dart';
import 'package:komiku/screen/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TambahKomik extends StatefulWidget {
  const TambahKomik({super.key});

  @override
  State<TambahKomik> createState() => _TambahKomikState();
}

class _TambahKomikState extends State<TambahKomik> {
  final _formKey = GlobalKey<FormState>();
  String _judul = "";
  String _deskripsi = "";
  String _tanggalRilis = "";
  String _pengarang = "";
  String? _userId;
  String _thumbnail = "";
  Uint8List? _imageBytes;
  List<Category> _kategoriList = [];
  List<int> _selectedKategori = [];
  final _controllerDate = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchKategori();
  }

  Future<void> fetchKategori() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
    });
    if (_userId == '') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan.')));
    }

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

  Future<void> submit() async {
    String base64Image = "";
    if (_imageBytes != null) {
      base64Image = base64Encode(_imageBytes!);
    }
    final response = await http.post(
      Uri.parse("https://ubaya.xyz/flutter/160421110/uas/newkomik.php"),
      body: {
        'judul': _judul,
        'deskripsi': _deskripsi,
        'tanggal_rilis': _tanggalRilis,
        'pengarang': _pengarang,
        'user_id': _userId,
        'thumbnail': _thumbnail,
        'base64Image': base64Image,
        'category_ids': jsonEncode(_selectedKategori)
      },
    );
    if (response.statusCode == 200) {
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sukses Menambah Komik')));
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (Route<dynamic> route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error menambah komik')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Komik"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _judul = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _deskripsi = value;
                  },
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
                        decoration: InputDecoration(
                          labelText: 'Tanggal Rilis',
                          border: OutlineInputBorder(),
                        ),
                        controller: _controllerDate,
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
                            _tanggalRilis = _controllerDate.text;
                          });
                        });
                      },
                      child: const Icon(Icons.calendar_today_sharp),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Pengarang',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _pengarang = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pengarang harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Thumbnail (URL)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _thumbnail = value;
                  },
                  validator: (value) {
                    if (value == null || !Uri.parse(value).isAbsolute) {
                      return 'URL thumbnail tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gambar Halaman",
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
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Kategori",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._kategoriList.map((kategori) {
                      return CheckboxListTile(
                        title: Text(kategori.nama),
                        value: _selectedKategori.contains(kategori.id),
                        onChanged: (isSelected) {
                          setState(() {
                            if (isSelected == true) {
                              _selectedKategori.add(kategori.id);
                            } else {
                              _selectedKategori.remove(kategori.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
