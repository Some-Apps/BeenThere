// location_repository.dart
import 'package:been_there/models/chunk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepository(this._firestore);

  Stream<List<Chunk>> getLocationChunks(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['locations'] != null) {
        List<dynamic> locationData = data['locations'];
        return locationData.map((item) {
          return Chunk.fromMap(item as Map<String, dynamic>);
        }).toList();
      } else {
        return [];
      }
    });
  }
}
