import 'package:flutter/material.dart';
import '../models/sound_model.dart';
import 'package:easy_localization/easy_localization.dart';

class SoundCard extends StatefulWidget {
  final SoundModel sound;
  final Color color;
  final bool isPlaying;
  final VoidCallback onTap;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final bool userIsPremium; // Adicionei para saber se deve mostrar o cadeado

  const SoundCard({
    super.key,
    required this.sound,
    required this.color,
    required this.isPlaying,
    required this.onTap,
    required this.volume,
    required this.onVolumeChanged,
    this.userIsPremium = false, // Padrão falso
  });

  @override
  State<SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends State<SoundCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.value = 0.0;
    }

    final bool showLock = widget.sound.isPremium && !widget.userIsPremium;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // ENTRA: Positioned.fill para forçar todos os cards a terem o mesmo tamanho
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? widget.color.withAlpha(60)
                    : Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isPlaying ? widget.color : Colors.white.withAlpha(20),
                  width: 1.5,
                ),
                boxShadow: widget.isPlaying
                    ? [
                        BoxShadow(
                          color: widget.color.withAlpha(80),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center( // Centraliza o conteúdo internamente
                child: Opacity(
                  opacity: showLock ? 0.6 : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical
                    children: [
                      ScaleTransition(
                        scale: widget.isPlaying
                            ? Tween(begin: 1.0, end: 1.12).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeInOut,
                                ),
                              )
                            : const AlwaysStoppedAnimation(1.0),
                        child: Text(
                          widget.sound.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.sound.title.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isPlaying ? Colors.white : Colors.white.withAlpha(200),
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 4.0,
                              color: Colors.black.withAlpha(150)
                            )
                          ]
                        ),
                      ),
                      // Ajuste: SizedBox fixo para o slider não deformar o card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: SizedBox(
                          height: 48, 
                          child: widget.isPlaying
                              ? SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    thumbColor: Colors.white,
                                    activeTrackColor: widget.color,
                                    inactiveTrackColor: widget.color.withAlpha(50),
                                  ),
                                  child: Slider(
                                    value: widget.volume,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: widget.onVolumeChanged,
                                  ),
                                )
                              : null, // Fica vazio mas mantém o espaço se não estiver tocando
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // O CADEADO (continua como estava, mas com posição fixa)
          if (showLock)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.amber,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
