import '../models/sound_model.dart';

final List<SoundModel> allSounds = [
  SoundModel(
      id: 'rain',
      title: 'Chuva',
      icon: '🌧️',
      path: 'assets/sounds/rain.mp3',
      category: 'Chuva'),
  SoundModel(
      id: 'wind',
      title: 'Vento',
      icon: '💨',
      path: 'assets/sounds/wind-draft.mp3',
      category: 'Natureza'),
  SoundModel(
      id: 'fire',
      title: 'Fogueira na floresta',
      icon: '🔥',
      path: 'assets/sounds/burning-bush.mp3',
      category: 'Fogo'),
];
