import 'package:flutter/material.dart';

enum AlphaArc { winter, summer, royal }

class ArcData {
  final AlphaArc arcType;
  final String title;
  final String subtitle;
  final String quote;
  final DateTime startDate;
  final DateTime endDate;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color textColor;
  final String buttonLabel;
  final String wisdomLabel;
  final String rewardTitleId;

  const ArcData({
    required this.arcType,
    required this.title,
    required this.subtitle,
    required this.quote,
    required this.startDate,
    required this.endDate,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.textColor,
    required this.buttonLabel,
    required this.wisdomLabel,
    required this.rewardTitleId,
  });

  static ArcData getWinterArc() {
    return _getWinterData(DateTime.now().year, DateTime.now().month);
  }

  static ArcData getSummerArc() {
    return _getSummerData(DateTime.now().year);
  }

  static ArcData getRoyalArc() {
    return _getRoyalData(DateTime.now().year, DateTime.now().month);
  }

  static ArcData getCurrentArc([DateTime? mockDate]) {
    final now = mockDate ?? DateTime.now();
    final year = now.year;
    final int month = now.month;

    if (month == 9 || month == 10) return _getRoyalData(year, month);
    if (month >= 4 && month <= 8) return _getSummerData(year);
    return _getWinterData(year, month);
  }

  static ArcData _getRoyalData(int year, int month) {
    return ArcData(
      arcType: AlphaArc.royal,
      title: "ROYAL ARC",
      subtitle: "LE COURONNEMENT ALPHA",
      quote: "\"La grandeur n'est pas reçue, elle est manifestée.\"",
      startDate: DateTime(month >= 9 ? year : year - 1, 9, 1),
      endDate: DateTime(month >= 9 ? year : year - 1, 10, 31, 23, 59, 59),
      primaryColor: const Color(0xFF8B5CF6),
      secondaryColor: const Color(0xFFF59E0B),
      surfaceColor: const Color(0xFF0F172A),
      onSurfaceColor: const Color(0xFFF59E0B),
      textColor: Colors.white,
      buttonLabel: "RÉGNER SUR SOI",
      wisdomLabel: "SOUVERAINETÉ",
      rewardTitleId: "arc_royal",
    );
  }

  static ArcData _getSummerData(int year) {
    return ArcData(
      arcType: AlphaArc.summer,
      title: "SUMMER BODY",
      subtitle: "L'ÉCLAT DE L'EFFORT",
      quote: "\"La lumière ne se trouve pas, elle se forge.\"",
      startDate: DateTime(year, 4, 1),
      endDate: DateTime(year, 8, 31, 23, 59, 59),
      primaryColor: const Color(0xFFEA580C),
      secondaryColor: const Color(0xFFFACC15),
      surfaceColor: Colors.white,
      onSurfaceColor: const Color(0xFFEA580C),
      textColor: Colors.white,
      buttonLabel: "CONQUÉRIR L'EXTÉRIEUR",
      wisdomLabel: "RAYONNEMENT",
      rewardTitleId: "arc_summer",
    );
  }

  static ArcData _getWinterData(int year, int month) {
    final int startYear = (month <= 3) ? year - 1 : year;
    final int endYear = (month <= 3) ? year : year + 1;

    return ArcData(
      arcType: AlphaArc.winter,
      title: "WINTER ARC",
      subtitle: "LA FORGE DANS L'OMBRE",
      quote: "\"Le progrès n'est pas un don, c'est une conquête.\"",
      startDate: DateTime(startYear, 11, 1),
      endDate: DateTime(endYear, 3, 31, 23, 59, 59),
      primaryColor: Colors.cyan,
      secondaryColor: Colors.blueGrey.shade800,
      surfaceColor: const Color(0xFF0F172A),
      onSurfaceColor: Colors.white,
      textColor: Colors.white,
      buttonLabel: "FORGE DANS L'OMBRE",
      wisdomLabel: "SAGESSE",
      rewardTitleId: "arc_winter",
    );
  }
}
