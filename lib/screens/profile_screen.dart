import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _favoriteFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  final _favoriteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<UserProvider>().user;

    _nameController.text = user.name;
    _emailController.text = user.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();

    super.dispose();
  }

  // LATIHAN 5: Validasi Keamanan
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    final prefs = await SharedPreferences.getInstance();

    final savedEmail =
        prefs.getString('user_email')?.toLowerCase();

    // Validasi email
    if (savedEmail != null &&
        savedEmail.isNotEmpty &&
        savedEmail != provider.user.email.toLowerCase() &&
        savedEmail == email) {
      _showMessage(
        'Email sudah digunakan!',
        true,
      );
      return;
    }

    // Validasi karakter berbahaya
    final dangerousName =
        RegExp(r'<\s*script\b|[<>]', caseSensitive: false);

    if (dangerousName.hasMatch(name)) {
      _showMessage(
        'Nama mengandung karakter berbahaya!',
        true,
      );
      return;
    }

    await provider.updateUser(
      provider.user.copyWith(
        name: name,
        email: email,
        isLoggedIn: true,
      ),
    );

    if (mounted) {
      _showMessage('Profil berhasil disimpan!', false);
    }
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Menambahkan favorit
  Future<void> _addFavorite() async {
    if (!_favoriteFormKey.currentState!.validate()) {
      return;
    }

    await context.read<UserProvider>().addFavorite(
          _favoriteController.text,
        );

    _favoriteController.clear();
  }

  // Logout
  Future<void> _logout() async {
    await context.read<UserProvider>().logout();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),

      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(
                        Icons.person,
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Input Nama
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }

                        if (RegExp(
                          r'<\s*script\b|[<>]',
                          caseSensitive: false,
                        ).hasMatch(value)) {
                          return 'Nama mengandung karakter berbahaya';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Input Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }

                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+$',
                        ).hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Profil'),
                    ),

                    const SizedBox(height: 30),

                    // LATIHAN 3: Daftar Favorit
                    Text(
                      'Daftar Favorit',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),

                    const SizedBox(height: 12),

                    Form(
                      key: _favoriteFormKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _favoriteController,
                              decoration: const InputDecoration(
                                labelText: 'Tambah hobi/favorit',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Isi nama favorit';
                                }

                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          IconButton.filled(
                            onPressed: _addFavorite,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (provider.favorites.isEmpty)
                      const Text('Belum ada item favorit.'),

                    ...provider.favorites.map(
                      (favorite) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.pink,
                          ),

                          title: Text(favorite),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            onPressed: () {
                              provider.removeFavorite(favorite);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}