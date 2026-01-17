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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentSound;
  Timer? _timer;
  int _remaningSeconds = 0;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    // Configurar o player para repetir o som continuamente
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // Função para iniciar o temporizador
  void _startTimer(int minutes) {
    // Se não houver som tocando, não iniciar o temporizador
    if (_currentSound == null) {
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
      _remaningSeconds = minutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaningSeconds > 0) {
        setState(() {
          _remaningSeconds--;
        });
      } else {
        _audioPlayer.stop();
        timer.cancel();
        setState(() {
          _currentSound = null;
        });
      }
    });
  }

  void _changeVolume(double newVolume) {
    setState(() {
      _volume = newVolume;
    });
    _audioPlayer.setVolume(newVolume);
  }

  // Função para formatar o tempo restante
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Função lógica para play/stop
  Future<void> _togglePlay(String fileName) async {
    if (_currentSound == fileName) {
      // Se clicar no som atual , parar a reprodução
      await _audioPlayer.stop();

      _timer?.cancel(); // Cancelar o temporizador se estiver ativo

      setState(() {
        _currentSound = null;
        _remaningSeconds = 0;
      });
    } else {
      // Para qualquer outro som, tocar o novo som
      await _audioPlayer.stop();
      _timer?.cancel(); // Cancelar o temporizador se estiver ativo
      _remaningSeconds = 0;

      await _audioPlayer.play(AssetSource('sounds/$fileName'));
      await _audioPlayer.setVolume(_volume);

      setState(() {
        _currentSound = fileName;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Liberar recursos do player
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
              _botaoRapido(1),
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

          // Seção do controle de volume
          VolumeSlider(
            value: _volume,
            onChanged: _changeVolume,
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
                      isPlaying: _currentSound == 'rain.mp3',
                      onTap: () => _togglePlay('rain.mp3')),
                  SoundCard(
                      title: 'Floresta com figueira',
                      fileName: 'burning-bush.mp3',
                      icon: Icons.forest,
                      color: Colors.green,
                      isPlaying: _currentSound == 'burning-bush.mp3',
                      onTap: () => _togglePlay('burning-bush.mp3')),
                  SoundCard(
                      title: 'Vento',
                      fileName: 'wind-draft.mp3',
                      icon: Icons.air,
                      color: Colors.teal,
                      isPlaying: _currentSound == 'wind-draft.mp3',
                      onTap: () => _togglePlay('wind-draft.mp3')),
                ],
              ),
            ),
          ),
        ]));
  }

  // Widget para criar botões rápidos de temporizador
  Widget _botaoRapido(int minutes) {
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
