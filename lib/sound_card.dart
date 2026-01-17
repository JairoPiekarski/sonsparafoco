import 'package:flutter/material.dart';

class SoundCard extends StatelessWidget {
  final String title;
  final String fileName;
  final IconData icon;
  final Color color;
  final bool isPlaying;
  final VoidCallback onTap;

  const SoundCard({
    super.key,
    required this.title,
    required this.fileName,
    required this.icon,
    required this.color,
    required this.isPlaying,
    required this.onTap,
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
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                )
            ],
          ),
        ));
  }
}
