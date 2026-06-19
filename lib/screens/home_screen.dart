import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import 'login_screen.dart';
import 'receipt_screen.dart';
import 'expense_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReceiptScreen(),
    ExpenseListScreen(),
  ];

  Future<void> _logout() async {
    await ApiClient.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moja Kasa'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Paragon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Wydatki',
          ),
        ],
      ),
    );
  }
}
