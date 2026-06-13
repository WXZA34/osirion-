import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/models/lat_lng.dart';
import '../services/routing_service.dart';

class ArenaMapState {
  final LatLng? focusPosition;
  final List<LatLng> navigationPath;
  final bool isNavigating;

  ArenaMapState({
    this.focusPosition,
    this.navigationPath = const [],
    this.isNavigating = false,
  });

  ArenaMapState copyWith({
    LatLng? focusPosition,
    List<LatLng>? navigationPath,
    bool? isNavigating,
  }) {
    return ArenaMapState(
      focusPosition: focusPosition ?? this.focusPosition,
      navigationPath: navigationPath ?? this.navigationPath,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}

class ArenaMapNotifier extends StateNotifier<ArenaMapState> {
  ArenaMapNotifier() : super(ArenaMapState());

  void setFocus(LatLng position) {
    state = state.copyWith(focusPosition: position);
  }

  Future<void> startNavigation(LatLng start, LatLng end, {String sportType = 'WALKING'}) async {
    state = state.copyWith(isNavigating: true, navigationPath: []);
    final path = await RoutingService.getDirections([start, end], sportType);
    state = state.copyWith(
      navigationPath: path,
      isNavigating: false,
      focusPosition: end,
    );
  }

  void clearNavigation() {
    state = state.copyWith(navigationPath: [], focusPosition: null);
  }
}

final arenaMapProvider = StateNotifierProvider<ArenaMapNotifier, ArenaMapState>((ref) {
  return ArenaMapNotifier();
});
