import 'package:flutter/material.dart';

abstract final class AppColors {
  // Marca — naranja señalización vial
  static const Color amber = Color(0xFFFF8C00);
  static const Color amberLight = Color(0xFFFFAF40);
  static const Color amberDark = Color(0xFFCC7000);

  // Asfalto / carretera
  static const Color asphalt = Color(0xFF0D0D0D);
  static const Color asphaltSurface = Color(0xFF1A1A1A);
  static const Color asphaltCard = Color(0xFF242424);
  static const Color asphaltBorder = Color(0xFF333333);

  // Concreto / fondo claro
  static const Color concrete = Color(0xFFF0F0E8);
  static const Color concreteLight = Color(0xFFFAFAF5);
  static const Color concreteCard = Color(0xFFFFFFFF);

  // Texto
  static const Color textOnDark = Color(0xFFF0F0F0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  static const Color textOnLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);

  // Niveles de operador
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);
  static const Color platinum = Color(0xFFE8E8FF);
  static const Color emerald = Color(0xFF50C878);
  static const Color diamond = Color(0xFF9BD9FF);

  // Feedback
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Estados de canje
  static const Color canjeColorSolicitado = Color(0xFFFF8C00);
  static const Color canjeColorAprobado = Color(0xFF34C759);
  static const Color canjeColorEntregado = Color(0xFF007AFF);
  static const Color canjeColorRechazado = Color(0xFFFF3B30);
  static const Color canjeColorCancelado = Color(0xFF8E8E93);
}
