import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  String _locationText = 'Fetching location...';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied)
        return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String place = 'Unknown Location';
    if (placemarks.isNotEmpty) {
      final pm = placemarks.first;
      place = '${pm.locality}, ${pm.administrativeArea}';
    }

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationText = place;
    });

    // After fetching the location, move the map to the new location
    _mapController.move(_currentLocation!, 13);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                _currentLocation ??
                LatLng(37.7749, -122.4194), // default location
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xDD264653),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationText,
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
