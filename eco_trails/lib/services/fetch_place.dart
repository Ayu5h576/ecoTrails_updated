import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_trails/models/place.dart';

class PlaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Place>> fetchPopularPlaces() async {
    var querySnapshot =
        await _db
            .collection('places')
            .where('isPopular', isEqualTo: true)
            .get();

    return querySnapshot.docs
        .map((doc) => Place.fromFirestore(doc.data()))
        .toList();
  }

  Future<List<Place>> fetchHiddenGems() async {
    var querySnapshot =
        await _db
            .collection('places')
            .where('isHiddenGem', isEqualTo: true)
            .get();

    return querySnapshot.docs
        .map((doc) => Place.fromFirestore(doc.data()))
        .toList();
  }
}
