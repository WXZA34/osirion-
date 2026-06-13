import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:valerion/core/models/lat_lng.dart';
import 'performance_chart.dart';

class PerformanceCard extends StatelessWidget {
  final String sportType;
  final double distanceKm;
  final String duration;
  final String speed;
  final double pace;
  final List<LatLng> path;
  final List<double> speedProfile;
  final Color primaryColor;
  final String? staticMapUrl;

  const PerformanceCard({
    super.key,
    required this.sportType,
    required this.distanceKm,
    required this.duration,
    required this.speed,
    required this.pace,
    required this.path,
    required this.speedProfile,
    required this.primaryColor,
    this.staticMapUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, // Fixed width for sharing
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Deep Slate/Black
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OSIRION PERFORMANCE",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    sportType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.bolt, color: primaryColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mini Map (The path)
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: staticMapUrl != null 
                ? CachedNetworkImage(
                    imageUrl: staticMapUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.map, color: Colors.white24, size: 40),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white24, size: 48),
                        SizedBox(height: 8),
                        Text(
                          "AUCUN TRACÉ DISPONIBLE",
                          style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Speed Chart
          PerformanceChart(
            speedProfile: speedProfile,
            accentColor: primaryColor,
          ),
          const SizedBox(height: 24),

          // Stats Grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("DISTANCE", "$distanceKm", "KM"),
                _buildStatItem("TEMPS", duration, ""),
                _buildStatItem("VITESSE", speed, "KM/H"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Branding Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ENGINEERED BY VALERION",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: " $unit",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
