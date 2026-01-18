import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'home_page.dart';

late MyAudioHandler audioHandler;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

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

    runApp(const CalmApp());
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
      title: 'Sons para Foco',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: HomePage(),
    );
  }
}
