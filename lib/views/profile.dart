import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final supabase = Supabase.instance.client;
  late final user = supabase.auth.currentUser;
  String? name;
  String? fotoProfileUrl;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (user == null) return;

    final response = await supabase
        .from('akun')
        .select('name, foto_profile')
        .eq('user_id', user!.id)
        .single();

    setState(() {
      name = response['name'];
      fotoProfileUrl = response['foto_profile'];
    });
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xff4A6B3E);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xffCFEBC1),
              backgroundImage:
                  fotoProfileUrl != null ? NetworkImage(fotoProfileUrl!) : null,
              child: fotoProfileUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text("Nama Lengkap"),
                      subtitle: Text(name ?? 'Tidak tersedia'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text("Email"),
                      subtitle: Text(user?.email ?? 'Tidak tersedia'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol edit profil
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/updateuser');
                },
                icon: const Icon(Icons.edit),
                label: const Text("Ubah Profil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Konfirmasi'),
                      content: Text('Apakah kamu yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(), // batal
                          child: Text('Tidak'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // tutup dialog
                            await logout(); // panggil fungsi logout
                          },
                          child: Text('Ya'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Keluar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
