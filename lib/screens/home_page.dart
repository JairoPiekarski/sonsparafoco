import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/sound_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sound_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedSounds = {};
  Timer? _timer;
  int _remaningSeconds = 0;
  final Map<String, double> _individualVolumes = {
    'rain.mp3': 0.5,
    'burning-bush.mp3': 0.5,
    'wind-draft.mp3': 0.5,
  };

  late TabController _tabController;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVolumes();

    final categoriesCount =
        allSounds.map((s) => s.category).toSet().toList().length;
    _tabController = TabController(length: categoriesCount, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_currentTabIndex != _tabController.index) {
          setState(() {
            _currentTabIndex = _tabController.index;
          });
        }
      } else {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  // Função para iniciar o temporizador
  void _startTimer(double minutes) {
    // Se não houver som tocando, não iniciar o temporizador
    if (_selectedSounds.isEmpty) {
      _showSnackBar(
          'Por favor, selecione ao menos um som para tocar primeiro.');
      return;
    }

    _timer?.cancel(); // Cancelar qualquer timer existente
    setState(() {
      _remaningSeconds = (minutes * 60).round();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaningSeconds > 0) {
        setState(() => _remaningSeconds--);
      } else {
        timer.cancel();
        _stopAllSounds();
      }
    });
  }

  void _stopAllSounds() {
    audioHandler.stop();
    setState(() {
      _selectedSounds.clear();
      _remaningSeconds = 0;
    });
  }

  // Função para volumes individuais dos sons
  void _onVolumeSliderChanged(String fileName, double newVolume) {
    audioHandler.setVolume(fileName, newVolume);

    setState(() {
      _individualVolumes[fileName] = newVolume;
    });

    _saveVolumes(fileName, newVolume);
  }

  // Função lógica para play/stop
  Future<void> _togglePlay(String fileName) async {
    print("--- DEBUG AUDIO ---");
    print("O que o Flutter recebeu: '$fileName'");

    if (_selectedSounds.contains(fileName)) {
      await audioHandler.stopSoundWithFade(fileName);
      setState(() => _selectedSounds.remove(fileName));
    } else {
      // Limitar a 2 sons simultâneos
      if (_selectedSounds.length >= 2) {
        _showSnackBar('Você pode tocar no máximo 2 sons ao mesmo tempo.');
        return;
      }

      final volume = _individualVolumes[fileName] ?? 0.5;
      await audioHandler.startSound(fileName, volume);

      setState(() => _selectedSounds.add(fileName));
    }
  }

  // Funções auxiliares
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Função para formatar o tempo restante
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Função para carregar volumes salvos
  Future<void> _loadVolumes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var fileName in _individualVolumes.keys) {
        double? savedVolume = prefs.getDouble('volume_$fileName');
        if (savedVolume != null) {
          _individualVolumes[fileName] = savedVolume;
        }
      }
    });
  }

  // Função para salvar volumes
  Future<void> _saveVolumes(String fileName, double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume_$fileName', volume);
  }

  @override
  void dispose() {
    //_audioPlayer.dispose(); // Liberar recursos do player
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = allSounds.map((s) => s.category).toSet().toList();

    final Map<String, List<Color>> categoryGradients = {
      'Chuva': [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
      'Natureza': [const Color(0xFF134E5E), const Color(0xFF71B280)],
      'Fogo': [const Color(0xFFED213A), const Color(0xFF93291E)],
    };

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Sons para Focar',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
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
                        color: Colors.orangeAccent),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.orangeAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: categories.map((cat) => Tab(text: cat)).toList(),
          ),
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: categoryGradients[categories[_currentTabIndex]] ??
                  [const Color(0xFF0F2027), const Color(0xFF2C5364)],
            ),
          ),
          child: SafeArea(
              child: Column(children: [
            const SizedBox(height: 10),
            const Text(
              "Desligar som em:",
              style: TextStyle(color: Colors.white60),
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
              height: 20,
              color: Colors.white10,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((categoryName) {
                  final filteredSounds = allSounds
                      .where((sound) => sound.category == categoryName)
                      .toList();

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredSounds.length,
                    itemBuilder: (context, index) {
                      final sound = filteredSounds[index];

                      return SoundCard(
                        sound: sound,
                        color: _getCategoryColor(sound.category),
                        isPlaying: _selectedSounds.contains(sound.path),
                        onTap: () => _togglePlay(sound.path),
                        volume: _individualVolumes[sound.path] ?? 0.5,
                        onVolumeChanged: (newVolume) =>
                            _onVolumeSliderChanged(sound.path, newVolume),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ])),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Chuva':
        return Colors.blueAccent;
      case 'Natureza':
        return Colors.greenAccent;
      case 'Fogo':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }

  // Widget para criar botões rápidos de temporizador
  Widget _botaoRapido(double minutes) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ActionChip(
          label: Text('$minutes min'),
          backgroundColor: Colors.white.withAlpha(15),
          onPressed: () => _startTimer(minutes),
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ));
  }
}
