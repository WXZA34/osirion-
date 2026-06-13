import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/models/lat_lng.dart' as ll;


class ArenaMap extends ConsumerStatefulWidget {
  final List<ll.LatLng> generatedLoop;
  final ll.LatLng? userPosition;
  final String mapType;
  final bool is3DMode;
  final double bearing;
  final List<ll.LatLng> obstacles;
  final ll.LatLng? ghostPosition;
  final void Function(mb.MapboxMap)? onMapCreated;

  const ArenaMap({
    super.key,
    this.generatedLoop = const [],
    this.userPosition,
    this.obstacles = const [],
    this.mapType = 'OUTDOORS',
    this.is3DMode = false,
    this.bearing = 0.0,
    this.ghostPosition,
    this.onMapCreated,
  });

  @override
  ConsumerState<ArenaMap> createState() => _ArenaMapState();
}

class _ArenaMapState extends ConsumerState<ArenaMap> {
  mb.MapboxMap? _mapboxMap;
  
  // Mappage des styles natifs
  String _getStyleUri(String type) {
    switch (type) {
      case 'STANDARD':
        return mb.MapboxStyles.STANDARD;
      case 'LIGHT':
        return mb.MapboxStyles.LIGHT;
      case 'OUTDOORS':
        return mb.MapboxStyles.OUTDOORS;
      case 'SATELLITE':
        return mb.MapboxStyles.SATELLITE_STREETS;
      default:
        return mb.MapboxStyles.STANDARD;
    }
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    widget.onMapCreated?.call(mapboxMap);
    
    // Configuration initiale de la caméra
    final pos = widget.userPosition ?? const ll.LatLng(48.5403, 2.6603);
    
    _mapboxMap?.setCamera(mb.CameraOptions(
      center: mb.Point(coordinates: mb.Position(pos.longitude, pos.latitude)),
      zoom: 15.5,
      pitch: widget.is3DMode ? 60.0 : 0.0,
      bearing: widget.bearing,
    ));
  }

  @override
  void didUpdateWidget(ArenaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Mise à jour de l'inclinaison ou du bearing si nécessaire
    if (oldWidget.is3DMode != widget.is3DMode || oldWidget.bearing != widget.bearing) {
      _mapboxMap?.setCamera(mb.CameraOptions(
        pitch: widget.is3DMode ? 60.0 : 0.0,
        bearing: widget.bearing,
      ));
    }

    // Mise à jour du style si nécessaire (Map Type)
    if (oldWidget.mapType != widget.mapType) {
      _mapboxMap?.loadStyleURI(_getStyleUri(widget.mapType));
    }

    // Mise à jour de la route si elle change
    if (oldWidget.generatedLoop != widget.generatedLoop) {
      _updateLoopLayer();
    }

    // Mise à jour des obstacles si ils changent
    if (oldWidget.obstacles != widget.obstacles) {
      _updateObstaclesLayer();
    }

    // Mise à jour du Ghost si il change
    if (oldWidget.ghostPosition != widget.ghostPosition) {
      _updateGhostLayer();
    }
  }

  @override
  void dispose() {
    _mapboxMap = null; // On libère la référence au contrôleur natif
    super.dispose();
  }

  void _onStyleLoaded(mb.StyleLoadedEventData data) async {
    // 1. Éradication du Relief et des POI
    final layersToHide = [
      'poi-label', 
      'transit-label', 
      'road-label-simple',
      'contour-line',
      'contour-label',
      'terrain-rgb',
      'mapbox-terrain-rgb',
      'hillshading',
      'landscape-contour',
      'landscape-contour-label',
      'contour' // ID générique souvent présent
    ];
    
    for (var layerId in layersToHide) {
      try {
        await _mapboxMap?.style.setStyleLayerProperty(layerId, 'visibility', 'none');
      } catch (_) {}
    }

    // 2. Désactivation du Terrain
    try {
      await _mapboxMap?.style.setStyleLayerProperty('hillshade', 'visibility', 'none');
    } catch (_) {}

    // 3. Activer le Puck de localisation natif
    try {
      await _mapboxMap?.location.updateSettings(mb.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));
    } catch (_) {}

    // 4. Tracer la boucle si elle existe
    if (widget.generatedLoop.isNotEmpty) {
      _updateLoopLayer();
    }

    // 5. Tracer les obstacles si ils existent
    if (widget.obstacles.isNotEmpty) {
      _updateObstaclesLayer();
    }

    // 6. Tracer le Ghost si il existe
    if (widget.ghostPosition != null) {
      _updateGhostLayer();
    }
  }

  Future<void> _updateLoopLayer() async {
    if (_mapboxMap == null) return;
    
    final points = widget.generatedLoop.map((p) => [p.longitude, p.latitude]).toList();
    if (points.isEmpty) return;

    final geoJsonStr = jsonEncode({
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": points,
      },
      "properties": {}
    });

    try {
      final style = _mapboxMap!.style;
      if (await style.styleSourceExists("loop-source")) {
        await style.setStyleSourceProperty("loop-source", "data", geoJsonStr);
      } else {
        await style.addSource(mb.GeoJsonSource(id: "loop-source", data: geoJsonStr));
        await style.addLayer(mb.LineLayer(
          id: "loop-layer",
          sourceId: "loop-source",
          lineColor: Colors.cyanAccent.value, 
          lineWidth: 5.0,
          lineCap: mb.LineCap.ROUND,
          lineJoin: mb.LineJoin.ROUND,
        ));
      }
    } catch (e) {
      debugPrint("Error updating loop layer: $e");
    }
  }

  Future<void> _updateObstaclesLayer() async {
    if (_mapboxMap == null) return;
    
    final points = widget.obstacles.map((p) => [p.longitude, p.latitude]).toList();
    
    final geoJsonStr = jsonEncode({
      "type": "FeatureCollection",
      "features": points.map((coord) => {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": coord,
        },
        "properties": {}
      }).toList()
    });

    try {
      final style = _mapboxMap!.style;
      if (await style.styleSourceExists("obstacles-source")) {
        await style.setStyleSourceProperty("obstacles-source", "data", geoJsonStr);
      } else {
        await style.addSource(mb.GeoJsonSource(id: "obstacles-source", data: geoJsonStr));
        
        // Couche de base (Cercle de danger)
        await style.addLayer(mb.CircleLayer(
          id: "obstacles-layer",
          sourceId: "obstacles-source",
          circleColor: Colors.redAccent.value,
          circleRadius: 15.0, 
          circleOpacity: 0.4,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.red.value,
        ));

        // Couche de halo (Glow externe)
        await style.addLayer(mb.CircleLayer(
          id: "obstacles-halo-layer",
          sourceId: "obstacles-source",
          circleColor: Colors.red.value,
          circleRadius: 25.0,
          circleOpacity: 0.15,
          circleStrokeWidth: 0.0,
        ));
      }
    } catch (e) {
      debugPrint("Error updating obstacles layer: $e");
    }
  }

  Future<void> _updateGhostLayer() async {
    if (_mapboxMap == null || widget.ghostPosition == null) return;

    final pos = widget.ghostPosition!;
    final geoJsonStr = jsonEncode({
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [pos.longitude, pos.latitude],
      },
      "properties": {}
    });

    try {
      final style = _mapboxMap!.style;
      if (await style.styleSourceExists("ghost-source")) {
        await style.setStyleSourceProperty("ghost-source", "data", geoJsonStr);
      } else {
        await style.addSource(mb.GeoJsonSource(id: "ghost-source", data: geoJsonStr));
        
        // Aura Orange/Rouge pour le Ghost
        await style.addLayer(mb.CircleLayer(
          id: "ghost-layer",
          sourceId: "ghost-source",
          circleColor: Colors.orangeAccent.value,
          circleRadius: 10.0,
          circleOpacity: 0.8,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
        ));
        
        // Halo de "vibration" pour le Ghost
        await style.addLayer(mb.CircleLayer(
          id: "ghost-glow",
          sourceId: "ghost-source",
          circleColor: Colors.orangeAccent.value,
          circleRadius: 18.0,
          circleOpacity: 0.2,
        ));
      }
    } catch (e) {
      debugPrint("Error updating ghost layer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return mb.MapWidget(
      key: const ValueKey("mapbox_map"),
      cameraOptions: mb.CameraOptions(
        zoom: 15.5,
        pitch: widget.is3DMode ? 60.0 : 0.0,
      ),
      styleUri: _getStyleUri(widget.mapType),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
