import '../../../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:valerion/core/models/lat_lng.dart' as ll;
import 'package:valerion/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final Color primaryColor;
  final Color surfaceColor;

  const MapPickerScreen({
    super.key,
    required this.primaryColor,
    required this.surfaceColor,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  mb.MapboxMap? _mapboxMap;
  ll.LatLng? _selectedLocation;
  Position? _userPosition;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Set style
    await mapboxMap.loadStyleURI(mb.MapboxStyles.OUTDOORS);

    // Get current location to center map
    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      _userPosition = pos;
      mapboxMap.setCamera(mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(pos.longitude, pos.latitude)),
        zoom: 13.0,
      ));
      
      // Activer le Puck de localisation natif
      await mapboxMap.location.updateSettings(mb.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));
    } catch (e) {
      // fallback
      mapboxMap.setCamera(mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(2.3522, 48.8566)), // Paris
        zoom: 12.0,
      ));
    }
  }

  void _onMapTap(mb.MapContentGestureContext context) {
    setState(() {
      _selectedLocation = ll.LatLng(context.point.coordinates.lat as double, context.point.coordinates.lng as double);
      _searchResults.clear();
      _searchController.clear();
    });
    _updatePin();
  }

  Future<void> _updatePin() async {
    if (_mapboxMap == null || _selectedLocation == null) return;
    
    final geoJsonStr = jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [_selectedLocation!.longitude, _selectedLocation!.latitude]
          },
          "properties": {}
        }
      ]
    });

    final style = _mapboxMap!.style;
    try {
      if (await style.styleSourceExists("pin-source")) {
        await style.setStyleSourceProperty("pin-source", "data", geoJsonStr);
      } else {
        await style.addSource(mb.GeoJsonSource(id: "pin-source", data: geoJsonStr));
        await style.addLayer(mb.CircleLayer(
          id: "pin-layer",
          sourceId: "pin-source",
          circleColor: widget.primaryColor.toARGB32(),
          circleRadius: 8.0,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ));
      }
    } catch (e) {
      debugPrint("Error updating pin layer: $e");
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    String url = 'https://api.mapbox.com/search/geocode/v6/forward?q=${Uri.encodeComponent(query)}&access_token=${AppConstants.mapboxAccessToken}&limit=5';
    if (_userPosition != null) {
      url += '&proximity=${_userPosition!.longitude},${_userPosition!.latitude}';
    }
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _searchResults = decoded['features'] ?? [];
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic feature) {
    FocusScope.of(context).unfocus();
    final coords = feature['geometry']['coordinates'];
    final lng = coords[0] as double;
    final lat = coords[1] as double;
    
    setState(() {
      _selectedLocation = ll.LatLng(lat, lng);
      _searchResults.clear();
      _searchController.text = feature['properties']['full_address'] ?? feature['properties']['name'] ?? "";
    });

    _mapboxMap?.setCamera(mb.CameraOptions(
      center: mb.Point(coordinates: mb.Position(lng, lat)),
      zoom: 15.0,
    ));
    _updatePin();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = widget.surfaceColor.computeLuminance() > 0.5;
    final Color textColor = isLight ? Colors.black : Colors.white;
    final Color hintColor = isLight ? Colors.black54 : Colors.white54;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.surfaceColor,
      body: SizedBox.expand(
        child: Stack(
        children: [
          Positioned.fill(
            child: mb.MapWidget(
              onMapCreated: _onMapCreated,
              onTapListener: _onMapTap,
            ),
          ),
          
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: widget.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: textColor),
                            onChanged: (val) {
                              if (val.length > 2) {
                                _searchAddress(val);
                              } else {
                                setState(() => _searchResults.clear());
                              }
                            },
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.arenaSearchAddress,
                              hintStyle: TextStyle(color: hintColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              suffixIcon: _isSearching
                                  ? Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor),
                                    )
                                  : Icon(Icons.search, color: hintColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final feature = _searchResults[index];
                        final props = feature['properties'];
                        return ListTile(
                          leading: Icon(Icons.location_on, color: widget.primaryColor),
                          title: Text(
                            props['name'] ?? "",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            props['full_address'] ?? props['place_formatted'] ?? "",
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                          onTap: () => _selectSearchResult(feature),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          if (_selectedLocation != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedLocation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                ),
                child: Text(AppLocalizations.of(context)!.arenaValiderLaDestination,
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
