import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'services/audio_handler.dart';
import 'screens/home_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

late MyAudioHandler audioHandler;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await EasyLocalization.ensureInitialized();

    await Purchases.configure(
      PurchasesConfiguration("goog_IuEDkCpnysheWYwftPWepMxImSb")
    );
    
    // Inicializar o serviço de audio e guardar variável global
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.jairo.ambientsounds.audio',
        androidNotificationChannelName: 'Sons para Foco',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: const Color(0xFF0F0F0F),
      ),
    );

    runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const CalmApp(),
    ));

    //FlutterNativeSplash.remove();

  } catch (e) {
    FlutterNativeSplash.remove();
    debugPrint("Erro na inicialização do áudio: $e");
  }
}

class CalmApp extends StatelessWidget {
  const CalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ui.app_title'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const HomePage(),
    );
  }
}
