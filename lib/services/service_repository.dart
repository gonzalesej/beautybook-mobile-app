import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getServices() async {
    final snapshot = await _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}