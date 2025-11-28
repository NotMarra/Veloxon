import 'package:flutter/material.dart';

/// Parser pro ASS/SSA titulky
class AssParser {
  /// Parsuje ASS/SSA soubor a extrahuje styling informace
  static AssStyle parseStyle(String assContent) {
    final style = AssStyle();

    // Najít sekci [V4+ Styles] nebo [V4 Styles]
    final stylesSection = RegExp(
      r'\[V4\+? Styles\](.*?)(?=\[|$)',
      multiLine: true,
      dotAll: true,
    ).firstMatch(assContent);

    if (stylesSection == null) return style;

    // Najít "Style: Default" nebo první style
    final styleMatch = RegExp(
      r'Style:\s*Default[^,]*,([^,]+),(\d+),(&H[\dA-Fa-f]+).*?Alignment[,:](\d+)',
      multiLine: true,
    ).firstMatch(stylesSection.group(1) ?? '');

    if (styleMatch != null) {
      // Font name
      style.fontName = styleMatch.group(1)?.trim() ?? 'Arial';

      // Font size
      style.fontSize = double.tryParse(styleMatch.group(2) ?? '32') ?? 32;

      // Color (ASS používá &HAABBGGRR formát)
      final colorHex = styleMatch.group(3) ?? '&H00FFFFFF';
      style.color = _parseAssColor(colorHex);

      // Alignment (ASS používá numpad alignment)
      final alignment = int.tryParse(styleMatch.group(4) ?? '2') ?? 2;
      style.textAlign = _parseAlignment(alignment);
      style.padding = _getPaddingForAlignment(alignment);
    }

    return style;
  }

  /// Převede ASS color (&HAABBGGRR) na Flutter Color
  static Color _parseAssColor(String assColor) {
    try {
      // Odstranit &H prefix
      final hex = assColor.replaceAll(RegExp(r'&H|&h'), '');

      if (hex.length >= 6) {
        // ASS format: AABBGGRR
        final bb = int.parse(hex.substring(0, 2), radix: 16);
        final gg = int.parse(hex.substring(2, 4), radix: 16);
        final rr = int.parse(hex.substring(4, 6), radix: 16);
        final aa = hex.length >= 8
            ? 255 - int.parse(hex.substring(6, 8), radix: 16)
            : 255;

        return Color.fromARGB(aa, rr, gg, bb);
      }
    } catch (e) {
      debugPrint('Error parsing ASS color: $e');
    }

    return Colors.white;
  }

  /// Převede ASS alignment (numpad) na TextAlign
  static TextAlign _parseAlignment(int alignment) {
    // ASS alignment je jako numpad:
    // 1 = bottom-left, 2 = bottom-center, 3 = bottom-right
    // 4 = middle-left, 5 = middle-center, 6 = middle-right
    // 7 = top-left, 8 = top-center, 9 = top-right

    switch (alignment % 3) {
      case 1:
        return TextAlign.left;
      case 0:
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  /// Určí padding podle ASS alignmentu
  static EdgeInsets _getPaddingForAlignment(int alignment) {
    // Vertikální pozice
    if (alignment <= 3) {
      // Bottom
      return const EdgeInsets.only(left: 40, right: 40, bottom: 80);
    } else if (alignment <= 6) {
      // Middle
      return const EdgeInsets.symmetric(horizontal: 40);
    } else {
      // Top
      return const EdgeInsets.only(left: 40, right: 40, top: 80);
    }
  }
}

/// Třída pro uložení ASS stylu
class AssStyle {
  String fontName = 'Arial';
  double fontSize = 32;
  Color color = Colors.white;
  TextAlign textAlign = TextAlign.center;
  EdgeInsets padding = const EdgeInsets.only(left: 40, right: 40, bottom: 80);

  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: fontName,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(offset: Offset(1.5, 1.5), blurRadius: 4.0, color: Colors.black),
        Shadow(
          offset: Offset(-1.5, -1.5),
          blurRadius: 4.0,
          color: Colors.black,
        ),
      ],
    );
  }
}
