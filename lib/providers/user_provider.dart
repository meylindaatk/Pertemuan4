import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  UserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    _user = User(
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      isLoggedIn: prefs.getBool('is_logged_in') ?? false,
    );

    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    _favorites = prefs.getStringList('favorites') ?? [];

    _visitCount = (prefs.getInt('visit_count') ?? 0) + 1;

    await prefs.setInt('visit_count', _visitCount);

    _isLoading = false;
    notifyListeners();
  }

  // LATIHAN 1: Dark Mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);

    notifyListeners();
  }

  // LATIHAN 2: Counter Kunjungan
  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser;
    _isLoading = false;

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);

    _user = User(name: '', email: '');

    notifyListeners();
  }

  // LATIHAN 3: Menambahkan Favorit
  Future<void> addFavorite(String item) async {
    final value = item.trim();

    if (value.isEmpty ||
        _favorites.any(
          (e) => e.toLowerCase() == value.toLowerCase(),
        )) {
      return;
    }

    _favorites = [..._favorites, value];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);

    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    _favorites.remove(item);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);

    notifyListeners();
  }
}

// LATIHAN 4: Provider Package
class UserProviderWrapper extends StatelessWidget {
  final Widget child;

  const UserProviderWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: child,
    );
  }
}