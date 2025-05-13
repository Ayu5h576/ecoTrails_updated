import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Place {
  final String title;
  final LatLng location;
  final String description;
  final int crowd;
  final double rating;
  final bool isPopular;
  final bool isHiddenGem;
  final List<String> images;

  Place({
    required this.title,
    required this.location,
    required this.description,
    required this.crowd,
    required this.rating,
    required this.isPopular,
    required this.isHiddenGem,
    required this.images,
  });

  factory Place.fromFirestore(Map<String, dynamic> data) {
    final geoPointData = data['location'];
    LatLng location;

    if (geoPointData != null && geoPointData is GeoPoint) {
      location = LatLng(geoPointData.latitude, geoPointData.longitude);
    } else {
      location = LatLng(0, 0);
    }

    return Place(
      title: data['name'] ?? '',
      location: location,
      description: data['description'] ?? '',
      crowd: data['crowd'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      isPopular: data['isPopular'] ?? false,
      isHiddenGem: data['isHiddenGem'] ?? false,
      images: List<String>.from(data['multiple images'] ?? []),
    );
  }
}
