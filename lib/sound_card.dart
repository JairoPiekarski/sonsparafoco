import 'package:flutter/material.dart';

class SoundCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isPlaying ? color.withAlpha(50) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPlaying ? color : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isPlaying ? color : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPlaying ? Colors.white : Colors.grey,
                ),
              ),

              // Se estiver tocando, mostrar slider de volume
              if (isPlaying)
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
                        activeTrackColor: color,
                        inactiveTrackColor: color.withAlpha(50),
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: onVolumeChanged,
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
