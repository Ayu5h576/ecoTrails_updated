// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String?> getCurrentAddress() async {
    // Check and request permission
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.location.request();
      if (!status.isGranted) return null;
    }

    // Ensure location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Convert to placemark
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return '${placemark.locality}, ${placemark.administrativeArea}';
    }

    return null;
  }
}
