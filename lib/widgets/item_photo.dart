import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// A rounded photo, or a placeholder with the item's first letter.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({super.key, this.photo, required this.name, this.size = 48});

  final Uint8List? photo;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    if (photo != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          photo!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: OrdoColors.background,
          border: Border.all(color: OrdoColors.outline),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: OrdoColors.textMuted,
          ),
        ),
      ),
    );
  }
}
