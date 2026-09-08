import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceChart extends StatelessWidget {
  final List<double> speedProfile;
  final Color accentColor;

  const PerformanceChart({
    super.key,
    required this.speedProfile,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (speedProfile.length < 2) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, color: Colors.white10, size: 40),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.arenaSessionTropCourtePour,
                style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Convert distance increments to speeds (km/h) for the chart
    // speedProfile contains total distance every 10s
    List<FlSpot> spots = [];
    double lastDist = 0;
    for (int i = 0; i < speedProfile.length; i++) {
      double currentDist = speedProfile[i];
      double distInPeriod = currentDist - lastDist;
      // distance in 10s -> speed in km/h
      // (dist / 10s) * 3600s = dist * 360
      double kmh = distInPeriod * 360;
      spots.add(FlSpot(i.toDouble() * 10, kmh));
      lastDist = currentDist;
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: accentColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
