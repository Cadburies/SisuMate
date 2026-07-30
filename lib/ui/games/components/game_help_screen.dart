import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_router.dart';
import '../../../core/colors.dart';

class HelpSection {
  final String title;
  final List<String> bullets;
  const HelpSection(this.title, this.bullets);
}

class GameHelpData {
  final String gameName;
  final String iconPath;
  final String tagline;
  final List<HelpSection> sections;
  const GameHelpData({
    required this.gameName,
    required this.iconPath,
    required this.tagline,
    required this.sections,
  });
}

class GameHelpScreen extends StatelessWidget {
  final GameHelpData data;
  const GameHelpScreen(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xCC000000),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Image.asset(data.iconPath, height: 32,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.help_outline, size: 32, color: Colors.white)),
          const SizedBox(width: 10),
          Text('${data.gameName} — Rules',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/games/common/longship_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _taglineCard(data.tagline),
              const SizedBox(height: 8),
              ...data.sections.map(_sectionCard),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taglineCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SisuColors.darkAppBackground.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SisuColors.darkTextSecondary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(text,
            style: TextStyle(
                color: SisuColors.darkTextPrimary,
                fontSize: 15,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      );

  Widget _sectionCard(HelpSection section) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: SisuColors.darkSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title,
                style: TextStyle(
                    color: SisuColors.completedText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...section.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: SisuColors.darkTextSecondary, fontSize: 13)),
                    Expanded(
                      child: Text(b,
                          style: TextStyle(
                              color: SisuColors.darkTextPrimary,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

void showGameHelp(BuildContext context, GameHelpData data) {
  context.push(AppRoutes.gameHelp, extra: data);
}
