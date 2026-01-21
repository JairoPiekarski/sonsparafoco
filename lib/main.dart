import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'services/audio_handler.dart';
import 'screens/home_page.dart';
import 'package:easy_localization/easy_localization.dart';

late MyAudioHandler audioHandler;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await EasyLocalization.ensureInitialized();

    // Inicializar o serviço de audio e guardar variável global
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.sonsparafoco.channel.audio',
        androidNotificationChannelName: 'Sons para Foco',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pt')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const CalmApp(),
    ));
  } catch (e) {
    debugPrint("Erro na inicialização do áudio: $e");
  }
}

class CalmApp extends StatelessWidget {
  const CalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: HomePage(),
    );
  }
}
