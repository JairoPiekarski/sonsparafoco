import 'dart:async';
import 'dart:ui';
import 'package:ambient_sound_app/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../main.dart';
import '../widgets/sound_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sound_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  final Map<String, double> _individualVolumes = {};
  bool userIsPremium = false;
  double? _selectedTimerDuration;
  bool _isGlobalPaused = false;

  late TabController _tabController;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });

    for (var sound in allSounds) {
      _individualVolumes[sound.id] = 0.5;
    }
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

    _atualizarStatusPremiumReal();
  }

  Future<void> _atualizarStatusPremiumReal() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      setState(() {
        userIsPremium =
            customerInfo.entitlements.all['Piekarski Studio Pro']?.isActive ??
                false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_is_premium', userIsPremium);
    } catch (e) {
      debugPrint("Erro ao checar assinatura real: $e");
    }
  }

  Future<void> verificarAssinatura() async {
    try {
      // 1. Abre o Paywall oficial.
      // O 'presentPaywall' apenas abre a interface.
      await RevenueCatUI.presentPaywall();

      // 2. Após o Paywall ser fechado (seja por compra ou cancelamento),
      // nós buscamos os dados MAIS RECENTES do servidor do RevenueCat.
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // 3. Verificamos se o plano 'pro' está ativo no objeto customerInfo
      if (customerInfo.entitlements.all['Piekarski Studio Pro']?.isActive ??
          false) {
        setState(() {
          userIsPremium = true;
        });
        _showSnackBar('ui.premium_success'.tr());

        // Opcional: Salva no SharedPreferences para persistência local rápida
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_is_premium', true);
      } else {
        print("Usuário fechou o paywall ou a compra não foi concluída.");
      }
    } catch (e) {
      print("Erro ao processar assinatura: $e");
      _showSnackBar('Erro ao processar compra. Tente novamente.');
    }
  }

  // Função para iniciar o temporizador
  void _startTimer(double minutes) {
    // Se não houver som tocando, não iniciar o temporizador
    if (_selectedSounds.isEmpty) {
      _showSnackBar('alerts.no_sounds_timer'.tr());
      return;
    }

    _timer?.cancel(); // Cancelar qualquer timer existente
    setState(() {
      _selectedTimerDuration = minutes;
      _remaningSeconds = (minutes * 60).round();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaningSeconds > 0) {
        setState(() {
          _remaningSeconds--;
        });
      }

      if (_remaningSeconds == 0) {
        timer.cancel();
        setState(() => _selectedTimerDuration = null);
        _stopAllSounds();
      }
    });
  }

  Future<void> _stopAllSounds() async {
    setState(() {
      _selectedSounds.clear();
      _remaningSeconds = 0;
    });

    try {
      await audioHandler.customAction('stopAllWithFade');
    } catch (e) {
      audioHandler.stop();
      debugPrint("Erro ao rodar fade: $e");
    }
  }

  // Função para volumes individuais dos sons
  void _onVolumeSliderChanged(String soundID, double newVolume) {
    final sound = allSounds.firstWhere((s) => s.id == soundID);

    audioHandler.setVolume(sound.path, newVolume);

    setState(() {
      _individualVolumes[soundID] = newVolume;
    });

    _saveVolumes(soundID, newVolume);
  }

  // Função lógica para play/stop
  Future<void> _togglePlay(String soundID) async {
    final sound = allSounds.firstWhere((s) => s.id == soundID);

    if (sound.isPremium && !userIsPremium) {
      _showPremiumModal();
      return;
    }

    if (_selectedSounds.contains(soundID)) {
      await audioHandler.stopSoundWithFade(sound.path);
      setState(() => _selectedSounds.remove(soundID));

      if (_selectedSounds.isEmpty && _timer != null) {
        _timer?.cancel();
        _remaningSeconds = 0;
        _selectedTimerDuration = null;
        debugPrint("Timer cancelado pois não tem sons ativos");
      }
    } else {
      // Limitar a 2 sons simultâneos
      if (_selectedSounds.length >= 2) {
        _showSnackBar('alerts.limit_reached'.tr());
        return;
      }

      final volume = _individualVolumes[soundID] ?? 0.5;

      if (_isGlobalPaused) {
        setState(() => _isGlobalPaused = false);

        for (var id in _selectedSounds) {
          final activeSound = allSounds.firstWhere((s) => s.id == id);
          await audioHandler.startSound(activeSound.path, _individualVolumes[id] ?? 0.5);
        }
      }

      await audioHandler.startSound(sound.path, volume);
      setState(() => _selectedSounds.add(soundID));
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
      userIsPremium = prefs.getBool('user_is_premium') ?? false;

      for (var fileName in _individualVolumes.keys) {
        double? savedVolume = prefs.getDouble('volume_$fileName');
        if (savedVolume != null) {
          _individualVolumes[fileName] = savedVolume;
        }
      }
    });
  }

  Future<void> _completePurchase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_is_premium', true);
    setState(() {
      userIsPremium = true;
    });
  }

  // Função para salvar volumes
  Future<void> _saveVolumes(String fileName, double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume_$fileName', volume);
  }

  // Função do Modal Premium
  void _showPremiumModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Para podermos arredondar os cantos
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E), // Uma cor escura e elegante
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ajusta o tamanho ao conteúdo
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
              const SizedBox(height: 16),
              Text(
                'ui.premium_title'.tr(), // "Desbloqueie tudo!"
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ui.premium_description'
                    .tr(), // "Sons exclusivos e sem anúncios."
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await verificarAssinatura();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ui.premium_button'.tr(), // "Seja Premium"
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ui.maybe_later'.tr(), // "Talvez mais tarde"
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
      'categories.chuva': [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
      'categories.natureza': [const Color(0xFF134E5E), const Color(0xFF71B280)],
      'categories.fogo': [const Color(0xFFED213A), const Color(0xFF93291E)],
      'categories.foco': [const Color(0xFF232526), const Color(0xFF414345)],
      'categories.ambiente': [const Color(0xFF3E5151), const Color(0xFFDECBA4)],
    };

    // Criamos uma variável para o gradiente atual para simplificar o código abaixo
    final currentGradient = categoryGradients[categories[_currentTabIndex]] ??
        [const Color(0xFF0F2027), const Color(0xFF2C5364)];

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'ui.app_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w300),
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
            IconButton(
              icon: const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
              ),
              onPressed: () {
                verificarAssinatura();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      backgroundGradient: currentGradient,
                    ),
                  ),
                ); // Ponto e vírgula obrigatório aqui
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.orangeAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
            tabs: categories.map((cat) => Tab(text: cat.tr())).toList(),
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
              colors: currentGradient,
            ),
          ),
          child: Stack(
            children: [
              SafeArea (
                child: Column(
                  children: [
                    _buildTimerHeader(),
                    const Divider(height: 20, color: Colors.white10),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: categories.map((categoryName) {
                          final filteredSounds = allSounds
                              .where((sound) => sound.category == categoryName)
                              .toList();

                          return AnimationLimiter(
                            child: GridView.builder(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, _selectedSounds.isEmpty ? 16 : 110),
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

                                return AnimationConfiguration.staggeredGrid(
                                  position: index,
                                  duration: const Duration(milliseconds: 500),
                                  columnCount: 2,
                                  child: ScaleAnimation(
                                    scale: 0.5,
                                    child: FadeInAnimation(
                                      child: SoundCard(
                                        sound: sound,
                                        color:
                                            _getCategoryColor(sound.category),
                                        isPlaying:
                                            _selectedSounds.contains(sound.id),
                                        onTap: () => _togglePlay(sound.id),
                                        volume:
                                            _individualVolumes[sound.id] ?? 0.5,
                                        onVolumeChanged: (newVolume) =>
                                            _onVolumeSliderChanged(
                                                sound.path, newVolume),
                                        userIsPremium: userIsPremium,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildMiniPlayer(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerHeader() {
    return Column(
      children: [
        const SizedBox(
          height: 10,
        ),
        Text(
          'ui.shutdown_timer'.tr(),
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(
          height: 8,
        ),
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
                  setState(() => _remaningSeconds = 0);
                },
              )
          ],
        )
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'categories.chuva': // Adicione o prefixo
        return Colors.blueAccent;
      case 'categories.natureza':
        return Colors.greenAccent;
      case 'categories.fogo':
        return Colors.orangeAccent;
      case 'categories.foco':
        return const Color(0xFF90A4AE);
      case 'categories.ambiente':
        return Colors.blueGrey;
      default:
        return Colors.white70;
    }
  }

  // Widget para criar botões rápidos de temporizador
  Widget _botaoRapido(double minutes) {
    final bool isSelected =
        _selectedTimerDuration == minutes && _remaningSeconds > 0;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ActionChip(
            label: Text('$minutes min'),
            backgroundColor:
                isSelected ? Colors.orangeAccent : Colors.white.withAlpha(15),
            onPressed: () => _startTimer(minutes),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )));
  }

  Widget _buildMiniPlayer() {
    if (_selectedSounds.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      decoration: BoxDecoration(
          color: Colors.grey[900]?.withValues(),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.orangeAccent.withValues()),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isGlobalPaused = !_isGlobalPaused;
                if (_isGlobalPaused) {
                  for (var soundID in _selectedSounds) {
                    final sound = allSounds.firstWhere((s) => s.id == soundID);
                    audioHandler.stopSoundWithFade(sound.path);
                  }
                } else {
                  for (var soundID in _selectedSounds) {
                    final sound = allSounds.firstWhere((s) => s.id == soundID);
                    audioHandler.startSound(sound.path, _individualVolumes[soundID] ?? 0.5);
                  }
                }
              });
            },
            child: Icon(
              _isGlobalPaused ? Icons.play_circle_filled : Icons.pause_circle_filled,
              color: Colors.orangeAccent,
              size: 40,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Row(
              children: _selectedSounds.map((id) {
                final sound = allSounds.firstWhere((s) => s.id == id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    sound.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.tune,
              color: Colors.white70,
            ),
            onPressed: () {
              _showVolumesModal();
            },
          )
        ],
      ),
    );
  }

  void _showVolumesModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Mix Ativo",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20,),
                ..._selectedSounds.map((id) {
                  final sound = allSounds.firstWhere((s) => s.id == id);
                  return ListTile(
                    leading: Text(sound.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(sound.title.tr(), style: const TextStyle(color: Colors.white)),
                    subtitle: Slider(
                      value: _individualVolumes[id] ?? 0.5,
                      activeColor: Colors.orangeAccent,
                      onChanged: (val) {
                        _onVolumeSliderChanged(id, val);
                        setModalState(() {});
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20,),
              ],
            ),
          );
        }
      );
    });
  }
}
