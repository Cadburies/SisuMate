import 'package:flutter/material.dart';

/// Small colored tag chip — flavor/cuisine tags on recipe cards (Cocktails,
/// Chef), allergen/flavor tags on ingredient tiles (My Bar, My Pantry). One
/// shared visual language app-wide (#187): red for allergens, orange for
/// flavor profile is the established convention at call sites.
class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const TagChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
