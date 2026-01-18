import 'package:flutter/material.dart';

class SoundCard extends StatefulWidget {
  final String title;
  final String fileName;
  final IconData icon;
  final Color color;
  final bool isPlaying;
  final VoidCallback onTap;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const SoundCard({
    super.key,
    required this.title,
    required this.fileName,
    required this.icon,
    required this.color,
    required this.isPlaying,
    required this.onTap,
    required this.volume,
    required this.onVolumeChanged,
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
    // Se não estiver tocando, parar a animação
    if (widget.isPlaying) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.value = 0.0;
    }

    return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? widget.color.withAlpha(40)
                : Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  widget.isPlaying ? widget.color : Colors.white.withAlpha(20),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                child: Icon(
                  widget.icon,
                  size: 48,
                  color: widget.isPlaying ? widget.color : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isPlaying ? Colors.white : Colors.grey,
                ),
              ),

              // Se estiver tocando, mostrar slider de volume
              if (widget.isPlaying)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: GestureDetector(
                    onTap:
                        () {}, // Evita que o GestureDetector pai capture o toque
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
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
                    ),
                  ),
                )
              else
                // Manter o espaço reservado para o slider
                const SizedBox(height: 48),
            ],
          ),
        ));
  }
}
