import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final List<Color> backgroundGradient;

  const SettingsPage({super.key, required this.backgroundGradient});

  // Função para abrir links externos (Créditos e Privacidade)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ui.settings'.tr(), style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Seção Premium
              _buildSectionTitle('ui.subscription'.tr()),
              ListTile(
                leading: const Icon(Icons.stars, color: Colors.amber),
                title: Text('ui.premium_button'.tr(), style: const TextStyle(color: Colors.white)),
                subtitle: Text('ui.premium_description'.tr(), style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  // Aqui você pode chamar o mesmo Modal de venda que criou
                },
              ),
              const Divider(color: Colors.white10),

              // Seção Créditos
              _buildSectionTitle('ui.credits'.tr()),
              ListTile(
                leading: const Icon(Icons.library_music, color: Colors.white70),
                title: const Text('Orange Free Sounds', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Alexander - Creative Commons', style: TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white38),
                onTap: () => _launchURL('https://orangefreesounds.com'),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white70),
                title: const Text('Freesound.org', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Community Contributors', style: TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white38),
                onTap: () => _launchURL('https://freesound.org'),
              ),
              
              const Divider(color: Colors.white10),

              // Seção Legal
              _buildSectionTitle('ui.legal'.tr()),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.white70),
                title: Text('ui.privacy_policy'.tr(), style: const TextStyle(color: Colors.white)),
                onTap: () => _launchURL('https://seusite.com/privacy'), // Link fictício por enquanto
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }
}