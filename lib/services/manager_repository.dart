import 'package:cloud_firestore/cloud_firestore.dart';

num _num(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ?? 0;
}

/// A service as the manager sees it (includes hidden ones).
class AdminService {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final num price;
  final int duration;
  final bool isActive;

  const AdminService({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.duration,
    required this.isActive,
  });

  factory AdminService.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AdminService(
      id: d.id,
      name: (m['name'] ?? m['serviceName'] ?? 'Service').toString(),
      description: (m['description'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? m['image'] ?? '').toString(),
      price: _num(m['price']),
      duration: _num(m['duration'] ?? m['durationMinutes']).toInt(),
      isActive: m['isActive'] == true,
    );
  }
}

/// A beautician stored in the 'Employee' collection with role == 'staff'.
class AdminStaff {
  final String id;
  final String name;
  final String position;
  final String email;

  const AdminStaff({
    required this.id,
    required this.name,
    required this.position,
    required this.email,
  });

  factory AdminStaff.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AdminStaff(
      id: d.id,
      name: (m['name'] ?? '').toString(),
      position: (m['position'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
    );
  }
}

/// Manager-only reads and writes. Your ServiceRepository is not touched.
class AdminRepository {
  final _db = FirebaseFirestore.instance;

  // ---------- services ----------
  Stream<List<AdminService>> watchServices() {
    return _db.collection('services').snapshots().map((s) {
      final list = s.docs.map(AdminService.fromDoc).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> saveService({
    String? id,
    required String name,
    required String description,
    required num price,
    required int duration,
    required String imageUrl,
  }) async {
    final data = {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'imageUrl': imageUrl,
    };
    if (id == null) {
      await _db.collection('services').add({...data, 'isActive': true});
    } else {
      await _db.collection('services').doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> setServiceActive(String id, bool active) async {
    await _db.collection('services').doc(id).update({'isActive': active});
  }

  // ---------- staff ----------
  Stream<List<AdminStaff>> watchStaff() {
    return _db
        .collection('Employee')
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map((s) {
      final list = s.docs.map(AdminStaff.fromDoc).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> saveStaff({
    String? id,
    required String name,
    required String position,
    required String email,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'role': 'staff',
      'position': position,
      if (email.isNotEmpty) 'email': email,
    };
    if (id == null) {
      await _db.collection('Employee').add(data);
    } else {
      await _db.collection('Employee').doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteStaff(String id) async {
    await _db.collection('Employee').doc(id).delete();
  }
}