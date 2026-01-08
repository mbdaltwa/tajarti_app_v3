import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/setup_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tajarti_royal_v1');
  runApp(const TajartiApp());
}

class TajartiApp extends StatelessWidget {
  const TajartiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تجارتي برو',
      theme: ThemeData(
        fontFamily: 'sans-serif',
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.royalBlue,
          primary: AppTheme.royalBlue,
          secondary: AppTheme.alertOrange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: StartupCheck()),
    );
  }
}

class StartupCheck extends StatefulWidget {
  const StartupCheck({super.key});
  @override
  State<StartupCheck> createState() => _StartupCheckState();
}

class _StartupCheckState extends State<StartupCheck> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  _checkAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final box = Hive.box('tajarti_royal_v1');
    if (!mounted) return;
    if (box.get('shop_name') == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupPage(isFirstTime: true)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)]),
              child: const Icon(Icons.account_balance_wallet, size: 60, color: AppTheme.royalBlue),
            ),
            const SizedBox(height: 20),
            const Text("تجارتي برو", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}