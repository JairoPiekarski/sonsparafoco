import 'package:flutter/material.dart';

class VolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const VolumeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(value == 0 ? Icons.volume_mute : Icons.volume_down,
              color: Colors.grey),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.grey.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}
