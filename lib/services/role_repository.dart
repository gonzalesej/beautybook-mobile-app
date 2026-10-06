import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, staff, manager }

class EmployeeProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

/// Reads your existing 'Employee' collection. A person is staff or manager only
/// if an Employee document has their email AND role == 'staff' / 'manager'.
/// Anyone else is a customer (returns null).
class RoleRepository {
  Future<EmployeeProfile?> findEmployee(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Employee')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      final m = d.data();
      final r = (m['role'] ?? '').toString().toLowerCase().trim();
      final UserRole role;
      if (r == 'manager') {
        role = UserRole.manager;
      } else if (r == 'staff') {
        role = UserRole.staff;
      } else {
        return null;
      }
      return EmployeeProfile(
        id: d.id,
        name: (m['name'] ?? '').toString().trim(),
        email: email.trim(),
        role: role,
      );
    } catch (_) {
      return null;
    }
  }
}