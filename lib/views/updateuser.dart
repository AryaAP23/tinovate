import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class UpdateUser extends StatefulWidget {
  const UpdateUser({super.key});

  @override
  State<UpdateUser> createState() => _UpdateUserState();
}

class _UpdateUserState extends State<UpdateUser> {
  final supabase = Supabase.instance.client;
  File? _imageFile;
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _currentImageUrl;

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final fileExt = path.extension(_imageFile!.path);
    final fileName = '${userId}_profile$fileExt';
    final filePath = 'avatars/$fileName';
    final mimeType = lookupMimeType(_imageFile!.path);

    try {
      await supabase.storage.from('fotoprofile').uploadBinary(
            filePath,
            await _imageFile!.readAsBytes(),
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final imageUrl =
          supabase.storage.from('fotoprofile').getPublicUrl(filePath);

      await supabase
          .from('akun')
          .update({'foto_profile': imageUrl}).eq('user_id', userId);

      // Cek apakah masih mounted sebelum pakai context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diperbarui!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    try {
      final akunResponse = await supabase
          .from('akun')
          .select('name, foto_profile')
          .eq('user_id', userId)
          .single();

      _name.text = akunResponse['name'] ?? '';
      _email.text = user.email ?? '';
      _currentImageUrl = akunResponse['foto_profile'];

      setState(() {});
    } catch (e) {
      print('Error mengambil data pengguna: $e');
    }
  }

  Future<void> updateNamaDanEmail() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    try {
      // Update nama ke tabel akun
      await supabase
          .from('akun')
          .update({'name': _name.text}).eq('user_id', userId);

      // Update email ke auth Supabase
      await supabase.auth.updateUser(
        UserAttributes(email: _email.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update profil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(0xff4A6B3E);

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Foto Profil'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (_currentImageUrl != null
                      ? NetworkImage(_currentImageUrl!)
                      : null), // fallback: jika semua null, tampil CircleAvatar kosong
              child: _imageFile == null && _currentImageUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.photo),
              label: Text("Pilih dari Galeri"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Konfirmasi'),
                    content:
                        Text('Apakah kamu yakin ingin memperbarui profil?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // batal
                        child: Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // tutup dialog

                          try {
                            await updateNamaDanEmail();
                            await uploadImage();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Gagal menyimpan perubahan: $e')),
                            );
                          }
                        },
                        child: Text('Ya'),
                      ),
                    ],
                  ),
                );
              },
              child: Text("Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
