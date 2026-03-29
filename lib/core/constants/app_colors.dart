import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // SSU Brand Colors (accent용)
  static const lightBlue = Color(0xFF6ECFC9); // Pantone 325
  static const mediumBlue = Color(0xFF009DC4); // Pantone 3135
  static const darkBlue = Color(0xFF006B96); // Pantone 308

  // ── Dark Mode Base ──
  static const bgDark = Color(0xFF0D1117); // GitHub-style dark
  static const bgCard = Color(0xFF161B22); // 카드 배경
  static const bgElevated = Color(0xFF1C2128); // 올린 카드
  static const cardFill = Color(0xFF1C2128); // 글래스 카드 기본 fill

  // ── Glass 레이어 (다크 기반) ──
  static const glassWhite = Color(0x0DFFFFFF); // 5% white
  static const glassBorder = Color(0x1AFFFFFF); // 10% white
  static const glassShadow = Color(0x33000000); // 20% black
  static const glassHighlight = Color(0x0DFFFFFF); // 5% white

  // ── Background Gradient (어두운 톤) ──
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D1117),
      Color(0xFF101820),
      Color(0xFF0D2137),
      Color(0xFF0D1117),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  // ── Status colors ──
  static const statusPending = Color(0xFFFFB74D);
  static const statusInProgress = Color(0xFF4FC3F7);
  static const statusCompleted = Color(0xFF81C784);

  // ── Priority colors ──
  static const priorityHigh = Color(0xFFEF5350);
  static const priorityMedium = Color(0xFFFFB74D);
  static const priorityLow = Color(0xFF81C784);

  // ── Text colors ──
  static const textPrimary = Color(0xFFE6EDF3); // 밝은 회색-흰색
  static const textSecondary = Color(0xFF8B949E); // 중간 회색
  static const textHint = Color(0xFF484F58); // 어두운 회색

  // ── Borders / Dividers ──
  static const border = Color(0xFF30363D);
  static const divider = Color(0xFF21262D);
}
