import 'package:flutter/material.dart';

/// --------------------------------------------------------------
/// 🎨 COLORES: Slider (Joy, Fear, Sadness)
/// --------------------------------------------------------------
const Map<String, Color> sliderEmotionColors = {
  "JOY": Color(0xFFFECA39),
  "FEAR": Color(0xFF944FBC),
  "SADNESS": Color(0xFF2390D3),
};

/// --------------------------------------------------------------
/// 🎨 COLORES: Knob 1 (Anger, Disgust, Anxiety, Envy)
/// --------------------------------------------------------------
const Map<String, Color> knobEmotionColors = {
  "ANGER": Color(0xFFFF595D),
  "DISGUST": Color(0xFF91C836),
  "ANXIETY": Color(0xFFFF924D),
  "ENVY": Color(0xFF34C985),
};

/// --------------------------------------------------------------
/// 🎨 COLORES: Knob 2 (Love, Embarrassment, Boredom)
/// --------------------------------------------------------------
const Map<String, Color> knob2EmotionColors = {
  "LOVE": Color(0xFFB53E8E),
  "EMBARRASSMENT": Color(0xFFB53F5F),
  "BOREDOM": Color(0xFFA08888),
};

/// --------------------------------------------------------------
/// 🧩 TODAS LAS EMOCIONES DIFÍCILES EN MAYÚSCULAS
/// --------------------------------------------------------------
const List<String> hardEmotions = [
  "ANGER",
  "FEAR",
  "ANXIETY",
  "ENVY",
  "SADNESS",
  "DISGUST",
  "LOVE",
  "EMBARRASSMENT",
  "BOREDOM",
];

/// --------------------------------------------------------------
/// 🌫️ Fallbacks estilo sumi-e según emoción
/// --------------------------------------------------------------
const Map<String, String> sumiZenDefaults = {
  "JOY":
      "Like ink blooming on a quiet page, your joy brightens softly.\nBreathe gently.",
  "FEAR":
      "Fear is a dark stroke on the canvas—present, yet not permanent.\nLet the line soften.",
  "SADNESS":
      "Sadness pools like diluted ink, deep but gentle.\nLet the paper hold your feeling.",
  "ANGER":
      "Your anger is a bold stroke of red ink.\nBreathe, and let its edges fade into calm.",
  "DISGUST":
      "Disgust is a stain you wish wasn’t there.\nIn time, all ink dries. Let it pass.",
  "ANXIETY":
      "Your thoughts scatter like restless droplets.\nSlow breaths let them settle.",
  "ENVY":
      "Envy is a shadow beside another's colour.\nYour own canvas remains unique.",
  "LOVE":
      "Love flows like soft ink across the page.\nWarm, steady, and connecting.",
  "EMBARRASSMENT":
      "Embarrassment is a sudden splash.\nBreathe, and watch it fade into soft blush.",
  "BOREDOM":
      "Boredom is a blank sheet waiting.\nOne small breath creates a new line.",
  "UNKNOWN":
      "Your emotions are ink before it touches the page.\nPossibility, waiting.",
};
