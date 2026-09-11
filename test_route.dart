import 'package:valerion/core/models/lat_lng.dart';
import 'package:valerion/features/arena/services/routing_service.dart';
import 'package:flutter/material.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final route = await RoutingService.getDirections([LatLng(48.8566, 2.3522), LatLng(48.8600, 2.3600)], 'RUNNING');
  print('ROUTE LENGTH: \');
}
