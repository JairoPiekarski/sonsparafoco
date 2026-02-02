import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class MyAudioHandler extends BaseAudioHandler {
  final Map<String, AudioPlayer> _players = {};

  MyAudioHandler() {
    _updateGlobalState();
  }

  Future<void> setVolume(String fileName, double volume) async {
    await _players[fileName]?.setVolume(volume);
  }

  // Fade Out aprimorado para evitar erros de dispose prematuro
  Future<void> stopSoundWithFade(String fileName) async {
    final player = _players[fileName];
    if (player == null) return;

    try {
      double currentVolume = player.volume;
      const steps = 10;
      final stepValue = currentVolume / steps;

      for (int i = 0; i < steps; i++) {
        currentVolume -= stepValue;
        if (currentVolume < 0) currentVolume = 0;
        await player.setVolume(currentVolume);
        await Future.delayed(const Duration(milliseconds: 50)); // Reduzido para ser mais ágil
      }
    } catch (e) {
      debugPrint("Erro no fade out: $e");
    } finally {
      await player.stop();
      await player.dispose();
      _players.remove(fileName);
      _updateGlobalState();
    }
  }

  Future<void> stopAllWithFade() async {
    // Usamos uma cópia das chaves para evitar erro de concorrência ao remover do mapa
    final keys = _players.keys.toList();
    await Future.wait(keys.map((fileName) => stopSoundWithFade(fileName)));
  }

  Future<void> startSound(String fileName, double volume) async {
    if (_players.containsKey(fileName)) return;

    final player = AudioPlayer();
    try {
      // Carregamento otimizado para OGG
      await player.setAsset(fileName);
      await player.setLoopMode(LoopMode.all); // Loop total do arquivo
      await player.setVolume(volume);
      
      // Inicia o som
      player.play();

      _players[fileName] = player;
      _updateGlobalState();
    } catch (e) {
      debugPrint("Erro ao carregar asset $fileName: $e");
    }
  }

  Future<void> stopSound(String fileName) async {
    final player = _players.remove(fileName);
    if (player != null) {
      await player.stop();
      await player.dispose();
    }
    _updateGlobalState();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'stopAllWithFade') {
      await stopAllWithFade();
      return true;
    }
    return super.customAction(name, extras);
  }

  // Comandos da Notificação
  @override
  Future<void> stop() async {
    // IMPORTANTE: Antes de dar dispose, paramos todos
    for (var player in _players.values) {
      await player.stop();
      await player.dispose();
    }
    _players.clear();
    _updateGlobalState();
    
    // Notifica o sistema que o serviço parou
    await super.stop();
  }

  @override
  Future<void> pause() async {
    for (var player in _players.values) {
      await player.pause();
    }
    _updateGlobalState();
  }

  @override
  Future<void> play() async {
    for (var player in _players.values) {
      await player.play();
    }
    _updateGlobalState();
  }

  void _updateGlobalState() {
    final isPlaying = _players.values.any((p) => p.playing);
    final hasActiveSounds = _players.isNotEmpty;

    playbackState.add(PlaybackState(
      controls: [
        if (isPlaying) MediaControl.pause else if (hasActiveSounds) MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1],
      playing: isPlaying,
      processingState: hasActiveSounds ? AudioProcessingState.ready : AudioProcessingState.idle,
    ));

    if (hasActiveSounds) {
      mediaItem.add(MediaItem(
        id: 'sons_foco',
        album: 'ui.app_title'.tr(), // Usando chave de tradução organizada
        title: 'ui.active_sounds'.tr(),
        artist: 'ui.sounds_playing'.tr(args: [_players.length.toString()]),
      ));
    } else {
      mediaItem.add(null); // Limpa a notificação se não houver sons
    }
  }
}