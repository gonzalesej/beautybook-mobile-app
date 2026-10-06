import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/beauty_models.dart';
import '../utils/format.dart';

/// Uses the NEW 'appointments' collection. Existing collections are untouched.
class AppointmentRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('appointments');

  List<Appointment> _sorted(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map(Appointment.fromDoc).toList();
    list.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.minutes.compareTo(b.minutes);
    });
    return list;
  }

  /// A customer's own bookings.
  Stream<List<Appointment>> watchForUser(String uid) =>
      _col.where('userId', isEqualTo: uid).snapshots().map(_sorted);

  /// Bookings assigned to one staff member (matched by name).
  Stream<List<Appointment>> watchForStaff(String staffName) =>
      _col.where('staffName', isEqualTo: staffName).snapshots().map(_sorted);

  /// All bookings (for the manager later).
  Stream<List<Appointment>> watchAll() => _col.snapshots().map(_sorted);

  /// All non-cancelled, non-declined, non-no-show bookings on a date (used to
  /// grey out taken slots).
  Future<List<Appointment>> bookingsForDate(DateTime date) async {
    final s = await _col.where('dateKey', isEqualTo: dateKey(date)).get();
    return s.docs.map(Appointment.fromDoc).where((a) => !a.isCancelledOrDeclined).toList();
  }

  Future<void> create(Appointment a) => _col.add(a.toMap());

  Future<void> cancel(String id) => updateStatus(id, 'cancelled');

  /// pending | confirmed | declined | completed | cancelled | no-show
  Future<void> updateStatus(String id, String status) =>
      _col.doc(id).update({'status': status});

  /// Marks a confirmed booking as a no-show: the customer never arrived and
  /// gave no notice. Per policy, a no-show cannot simply be rescheduled.
  Future<void> markNoShow(String id) => updateStatus(id, 'no-show');

  /// Saves a customer's rating (1-5) and optional review on a completed booking.
  Future<void> rate(String id, int rating, String review) => _col.doc(id).update({
        'rating': rating,
        'review': review.trim(),
        'ratedAt': FieldValue.serverTimestamp(),
      });

  /// Moves a booking to a new date/time/staff. Keeps its current status
  /// (pending stays pending, confirmed stays confirmed) and bumps
  /// rescheduleCount so the one-reschedule-per-appointment rule can be
  /// enforced by the UI.
  Future<void> reschedule({
    required String id,
    required DateTime newDate,
    required String newTime,
    required String newStaffName,
    required String reason,
    required int currentRescheduleCount,
  }) =>
      _col.doc(id).update({
        'date': Timestamp.fromDate(newDate),
        'dateKey': dateKey(newDate),
        'time': newTime,
        'staffName': newStaffName,
        'rescheduleCount': currentRescheduleCount + 1,
        'rescheduleReason': reason,
        'rescheduledAt': FieldValue.serverTimestamp(),
      });

  /// <24h rule: saves the customer's requested change WITHOUT touching the
  /// real date/time. Staff or a manager must approve it.
  Future<void> requestReschedule({
    required String id,
    required DateTime newDate,
    required String newTime,
    required String newStaffName,
    required String reason,
  }) =>
      _col.doc(id).update({
        'pendingRescheduleDate': Timestamp.fromDate(newDate),
        'pendingRescheduleTime': newTime,
        'pendingRescheduleStaff': newStaffName,
        'pendingRescheduleReason': reason,
        'pendingRescheduleAt': FieldValue.serverTimestamp(),
      });

  static Map<String, dynamic> get _clearPending => {
        'pendingRescheduleDate': FieldValue.delete(),
        'pendingRescheduleTime': FieldValue.delete(),
        'pendingRescheduleStaff': FieldValue.delete(),
        'pendingRescheduleReason': FieldValue.delete(),
        'pendingRescheduleAt': FieldValue.delete(),
      };

  /// Applies the pending request to the real booking and clears it.
  Future<void> approveReschedule(Appointment a) {
    final newDate = a.pendingRescheduleDate!;
    final newStaff =
        a.pendingRescheduleStaff.isEmpty ? a.staffName : a.pendingRescheduleStaff;
    return _col.doc(a.id).update({
      'date': Timestamp.fromDate(newDate),
      'dateKey': dateKey(newDate),
      'time': a.pendingRescheduleTime,
      'staffName': newStaff,
      'rescheduleCount': a.rescheduleCount + 1,
      'rescheduleReason': a.pendingRescheduleReason,
      'rescheduledAt': FieldValue.serverTimestamp(),
      ..._clearPending,
    });
  }

  /// Clears the request; the booking stays exactly as it was.
  Future<void> rejectReschedule(String id) => _col.doc(id).update(_clearPending);

  /// Pay-at-salon: staff/manager confirms the customer handed over payment
  /// at the counter, usually right after the service is completed.
  Future<void> markPaymentReceived(String id) => _col.doc(id).update({
        'paymentReceived': true,
        'paymentReceivedAt': FieldValue.serverTimestamp(),
      });

  /// Beauticians for booking: Employee documents with role == 'staff',
  /// then the optional 'staff' collection, then a default list.
  Future<List<StaffMember>> loadStaff() async {
    try {
      final e = await _db.collection('Employee').where('role', isEqualTo: 'staff').get();
      final list = e.docs
          .map((d) => StaffMember(
                id: d.id,
                name: (d.data()['name'] ?? '').toString(),
                role: (d.data()['position'] ?? 'Beautician').toString(),
              ))
          .where((m) => m.name.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      final s = await _db.collection('staff').get();
      final list = s.docs
          .map((d) => StaffMember(
                id: d.id,
                name: (d.data()['name'] ?? '').toString(),
                role: (d.data()['role'] ?? 'Beautician').toString(),
              ))
          .where((m) => m.name.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return const [
      StaffMember(id: 's1', name: 'Anna', role: 'Hair Stylist'),
      StaffMember(id: 's2', name: 'Bea', role: 'Nail Technician'),
      StaffMember(id: 's3', name: 'Carla', role: 'Skin Therapist'),
    ];
  }
}