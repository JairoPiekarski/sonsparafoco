import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_card.dart';
import 'widgets/volume_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _activePlayers = {};
  final Set<String> _selectedSounds = {};
  String? _currentSound;
  Timer? _timer;
  int _remaningSeconds = 0;
  double _volume = 0.5;
  final Map<String, double> _individualVolumes = {
    'rain.mp3': 0.5,
    'burning-bush.mp3': 0.5,
    'wind-draft.mp3': 0.5,
  };

  @override
  void initState() {
    super.initState();
    // Configurar o player para repetir o som continuamente
    //_audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // Função para iniciar o temporizador
  void _startTimer(double minutes) {
    // Se não houver som tocando, não iniciar o temporizador
    if (_selectedSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um som para tocar primeiro.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _timer?.cancel(); // Cancelar qualquer timer existente
    setState(() {
      _remaningSeconds = (minutes * 60).round();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaningSeconds > 0) {
        setState(() {
          _remaningSeconds--;
        });
      } else {
        timer.cancel();

        // Criar lista temporária para não dar erro enquanto remove itens do mapa
        final activeSounds = List<String>.from(_selectedSounds);

        for (var sound in activeSounds) {
          _fadeOutAndStop(sound);
        }

        setState(() {
          _remaningSeconds = 0;
        });
      }
    });
  }

  // Função para alterar o volume

  // Função para volumes individuais dos sons
  void _onVolumeSliderChanged(String fileName, double newVolume) {
    setState(() {
      _individualVolumes[fileName] = newVolume;
    });

    // Verificar se o player está ativo e atualizar o volume
    final player = _activePlayers[fileName];
    if (player != null) {
      player.setVolume(newVolume);
    }
  }

  // Função para formatar o tempo restante
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Função lógica para play/stop
  Future<void> _togglePlay(String fileName) async {
    if (_selectedSounds.contains(fileName)) {
      final player = _activePlayers[fileName];

      // Se o som já estiver tocando, parar
      setState(() {
        _selectedSounds.remove(fileName);
      });

      if (player != null) {
        await player.stop();
        await player.dispose();
        _activePlayers.remove(fileName);
      }
    } else {
      // Limitar a 2 sons simultâneos
      if (_selectedSounds.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você pode tocar no máximo 2 sons ao mesmo tempo.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final newPlayer = AudioPlayer();

      try {
        await newPlayer.setPlayerMode(PlayerMode.lowLatency);
        await newPlayer.setReleaseMode(ReleaseMode.loop);

        final savedVolume = _individualVolumes[fileName] ?? _volume;
        await newPlayer.setVolume(savedVolume);

        await newPlayer.play(AssetSource('sounds/$fileName'));

        setState(() {
          _activePlayers[fileName] = newPlayer;
          _selectedSounds.add(fileName);
        });
      } catch (e) {
        // Em caso de erro, liberar recursos do player
        await newPlayer.dispose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao tocar o som: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
  }

  // Função para fazer o fade out e parar o áudio
  Future<void> _fadeOutAndStop(String fileName) async {
    // Obter o player ativo para o arquivo fornecido
    final player = _activePlayers[fileName];
    if (player == null) return;

    // Remover do visual imediatamente
    setState(() {
      _selectedSounds.remove(fileName);
    });

    double startVolume = _individualVolumes[fileName] ?? _volume;

    const int steps = 10;
    double currentVolume = startVolume;
    final stepValue = startVolume / steps;

    // Loop de fade out
    for (int i = 0; i < steps; i++) {
      // Se o usuario clicar no som novamente, interrompe o fade out
      if (_selectedSounds.contains(fileName)) {
        return;
      }

      currentVolume -= stepValue;
      if (currentVolume < 0) currentVolume = 0;

      await player.setVolume(currentVolume);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Parar e limpar o player
    await player.stop();
    await player.dispose();
    _activePlayers.remove(fileName);
  }

  @override
  void dispose() {
    //_audioPlayer.dispose(); // Liberar recursos do player
    _timer?.cancel();

    // Fechar todos os players ativos
    for (var player in _activePlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sons para focar'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_remaningSeconds > 0)
              Center(
                  child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  _formatTime(_remaningSeconds),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ))
          ],
        ),
        body: Column(children: [
          // Seção do temporizador
          const Text(
            "Desligar o som em:",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botaoRapido(0.1),
              _botaoRapido(30),
              _botaoRapido(60),
              if (_remaningSeconds > 0)
                IconButton(
                  icon: const Icon(
                    Icons.timer_off,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _remaningSeconds = 0;
                    });
                  },
                )
            ],
          ),

          const Divider(
            height: 1,
            color: Colors.white10,
          ),

          // Seção dos cartões de som
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  SoundCard(
                      title: 'Chuva',
                      fileName: 'rain.mp3',
                      icon: Icons.thunderstorm,
                      color: Colors.blue,
                      isPlaying: _selectedSounds.contains('rain.mp3'),
                      volume: _individualVolumes['rain.mp3'] ?? 0.5,
                      onVolumeChanged: (newVolume) =>
                          _onVolumeSliderChanged('rain.mp3', newVolume),
                      onTap: () => _togglePlay('rain.mp3')),
                  SoundCard(
                      title: 'Floresta com figueira',
                      fileName: 'burning-bush.mp3',
                      icon: Icons.forest,
                      color: Colors.green,
                      isPlaying: _selectedSounds.contains('burning-bush.mp3'),
                      volume: _individualVolumes['burning-bush.mp3'] ?? 0.5,
                      onVolumeChanged: (newVolume) =>
                          _onVolumeSliderChanged('burning-bush.mp3', newVolume),
                      onTap: () => _togglePlay('burning-bush.mp3')),
                  SoundCard(
                      title: 'Vento',
                      fileName: 'wind-draft.mp3',
                      icon: Icons.air,
                      color: Colors.teal,
                      isPlaying: _selectedSounds.contains('wind-draft.mp3'),
                      volume: _individualVolumes['wind-draft.mp3'] ?? 0.5,
                      onVolumeChanged: (newVolume) =>
                          _onVolumeSliderChanged('wind-draft.mp3', newVolume),
                      onTap: () => _togglePlay('wind-draft.mp3')),
                ],
              ),
            ),
          ),
        ]));
  }

  // Widget para criar botões rápidos de temporizador
  Widget _botaoRapido(double minutes) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ActionChip(
          label: Text('$minutes min'),
          backgroundColor: Colors.grey.withAlpha(30),
          onPressed: () => _startTimer(minutes),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ));
  }
}
