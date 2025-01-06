import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:wawehead/screens/home.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();
  // await Hive.openBox<String>('link');
  // await Hive.openBox<int>('bookProgress');
  await Hive.openBox<int>('homePage');
  await Hive.openBox<String>('playerPage');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.laila().fontFamily,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(selectedItemColor: Colors.black, unselectedItemColor: Colors.black.withValues(alpha: 0.6), showUnselectedLabels: false, showSelectedLabels: false)
      ),
      home: HomePage(),
    );
  }
}
