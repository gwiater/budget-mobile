import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl', null);
  final token = await SecureStorage.getToken();
  runApp(BudgetApp(isLoggedIn: token != null));
}

class BudgetApp extends StatelessWidget {
  final bool isLoggedIn;
  const BudgetApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moja Kasa',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pl'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
