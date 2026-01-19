import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  // Mapa para tocar vários sons ao mesmo tempo internamente
  final Map<String, AudioPlayer> _players = {};

  MyAudioHandler() {
    _updateGlobalState();
  }

  Future<void> setVolume(String fileName, double volume) async {
    _players[fileName]?.setVolume(volume);
  }

  Future<void> stopSoundWithFade(String fileName) async {
    final player = _players[fileName];
    if (player == null) return;

    double currentVolume = player.volume;
    const steps = 10;
    final stepValue = currentVolume / steps;

    for (int i = 0; i < steps; i++) {
      currentVolume -= stepValue;
      if (currentVolume < 0) currentVolume = 0;
      await player.setVolume(currentVolume);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await player.stop();
    await player.dispose();
    _players.remove(fileName);
    _updateGlobalState();
  }

  // Método para a HomePage usar quando ligar um som
  Future<void> startSound(String fileName, double volume) async {
    if (_players.containsKey(fileName)) return;

    final player = AudioPlayer();
    try {
      // O just_audio precisa do caminho completo
      await player.setAsset(fileName);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(volume);
      player.play();

      _players[fileName] = player;
      _updateGlobalState();
    } catch (e) {
      print("Erro ao tocar: $e");
    }
  }

  // Método para a HomePage usar quando desligar um som
  Future<void> stopSound(String fileName) async {
    final player = _players.remove(fileName);
    if (player != null) {
      await player.stop();
      await player.dispose();
    }
    _updateGlobalState();
  }

  // Comandos da Notificação (O que acontece quando clica no botão da barra do Android)
  @override
  Future<void> stop() async {
    for (var player in _players.values) {
      await player.stop();
      await player.dispose();
    }
    _players.clear();
    _updateGlobalState();
    // Aqui você também pode avisar a UI para desmarcar os cards,
    // mas vamos focar na notificação primeiro.
  }

  @override
  Future<void> pause() async {
    for (var player in _players.values) {
      player.pause();
    }
    _updateGlobalState();
  }

  @override
  Future<void> play() async {
    for (var player in _players.values) {
      player.play();
    }
    _updateGlobalState();
  }

  // Atualiza como a notificação aparece no Android
  void _updateGlobalState() {
    final isPlaying = _players.values.any((p) => p.playing);
    final hasActiveSounds = _players.isNotEmpty;

    playbackState.add(PlaybackState(
      controls: [
        if (isPlaying)
          MediaControl.pause
        else if (hasActiveSounds)
          MediaControl.play,
        MediaControl.stop,
      ],
      // Define quais botões aparecem na notificação "encolhida"
      androidCompactActionIndices: const [0, 1],
      playing: isPlaying,
      processingState: hasActiveSounds
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
    ));

    // Informação que aparece na notificação (Título e Subtítulo)
    if (hasActiveSounds) {
      mediaItem.add(MediaItem(
        id: 'sons_foco',
        album: 'Seu App de Foco',
        title: 'Sons Ativos',
        artist: '${_players.length} som(ns) tocando',
      ));
    }
  }
}
