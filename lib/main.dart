import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wawehead/screens/home.dart';

import 'components/audio.dart';

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

  // Audio();

  await Hive.initFlutter();
  // await Hive.openBox<String>('link');
  // await Hive.openBox<int>('bookProgress');
  await Hive.openBox<int>('homePage');
  await Hive.openBox<String>('playerPage');

  // _audioHandler = await AudioService.init(
  //   builder: () => MyAudioHandler(),
  //   config: AudioServiceConfig(
  //     androidNotificationChannelId: 'com.krashkanter.wawehead.channel.audio',
  //     androidNotificationChannelName: 'Music playback',
  //   ),
  // );

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
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black.withValues(alpha: 0.6),
            showUnselectedLabels: false,
            showSelectedLabels: false),
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
