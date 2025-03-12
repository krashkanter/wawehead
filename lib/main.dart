import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wawehead/screens/home.dart';

final mediaStorePlugin = MediaStore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    List<Permission> permissions = [
      Permission.storage,
    ];

    if ((await mediaStorePlugin.getPlatformSDKInt()) >= 33) {
      permissions.add(Permission.audio);
    }

    await permissions.request();
    MediaStore.appFolder = "MediaStorePlugin";
    requestAudioPermissionOnLaunch();
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();

  await Hive.openBox<int>('homePage');
  await Hive.openBox<String>('playerPage');
  await Hive.openBox<bool>('repeatState');

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
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.laila().fontFamily,
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle:
              WidgetStatePropertyAll(TextStyle(color: Colors.blue.shade50)),
          indicatorColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.blue.shade50,
        ),
        dataTableTheme: DataTableThemeData(
          dividerThickness: 2,
          headingRowColor: WidgetStateProperty.all(Colors.black),
          headingTextStyle: TextStyle(fontSize: 20),
          dataRowColor: WidgetStateProperty.all(Colors.black.withAlpha(100)),
          dataTextStyle: TextStyle(fontSize: 16, color: Colors.blue.shade50),
        ),
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      ),
      home: HomePage(),
    );
  }
}

Future<void> requestAudioPermissionOnLaunch() async {
  if (await Permission.audio.isGranted) {
    return;
  } else {
    if (await Permission.audio.isDenied) {
      openAppSettings();
    } else {
      await Permission.audio.request();
    }
  }
}
