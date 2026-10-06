import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/format.dart';

num _toNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ?? 0;
}

class Appointment {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String staffName;
  final String timeLabel;
  final String status; // pending | confirmed | declined | completed | cancelled | no-show
  final DateTime date;
  final num price;
  final int duration;
  final String customerName;
  final int rating; // 0 = not rated yet, otherwise 1-5
  final String review;
  final int rescheduleCount;
  final String rescheduleReason;

  // A reschedule request waiting for staff/manager approval (<24h rule).
  final DateTime? pendingRescheduleDate;
  final String pendingRescheduleTime;
  final String pendingRescheduleStaff;
  final String pendingRescheduleReason;

  // Pay-at-salon confirmation: staff/manager marks this once the customer
  // hands over payment at the counter.
  final bool paymentReceived;
  final DateTime? paymentReceivedAt;

  const Appointment({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.staffName,
    required this.timeLabel,
    required this.status,
    required this.date,
    required this.price,
    required this.duration,
    this.customerName = '',
    this.rating = 0,
    this.review = '',
    this.rescheduleCount = 0,
    this.rescheduleReason = '',
    this.pendingRescheduleDate,
    this.pendingRescheduleTime = '',
    this.pendingRescheduleStaff = '',
    this.pendingRescheduleReason = '',
    this.paymentReceived = false,
    this.paymentReceivedAt,
  });

  int get minutes => labelToMinutes(timeLabel);
  DateTime get startAt =>
      DateTime(date.year, date.month, date.day).add(Duration(minutes: minutes));
  DateTime get endAt => startAt.add(Duration(minutes: duration > 0 ? duration : 60));

  bool get isPast => endAt.isBefore(DateTime.now());
  bool get _isActiveStatus => status == 'pending' || status == 'confirmed';

  /// pending or confirmed (not finished, cancelled, declined or no-show).
  bool get isActive => _isActiveStatus;

  bool get isUpcoming => _isActiveStatus && !isPast;
  bool get isStale => _isActiveStatus && isPast;
  bool get isRated => rating > 0;
  bool get isNoShow => status == 'no-show';

  /// True when the booking is no longer active: cancelled by the customer,
  /// declined by staff/manager, or marked as a no-show. All three free up
  /// the slot and stop counting toward "active" bookings.
  bool get isCancelledOrDeclined => status == 'cancelled' || status == 'declined' || isNoShow;

  /// Hours between now and the appointment's start. Used for the 24-hour
  /// reschedule rule. Can be negative if it's already started.
  int get hoursUntilStart => startAt.difference(DateTime.now()).inHours;

  /// BeautyBook policy: only one reschedule per appointment.
  bool get hasRescheduled => rescheduleCount > 0;

  /// True while a <24h reschedule request is waiting for approval.
  bool get hasPendingReschedule =>
      pendingRescheduleDate != null && pendingRescheduleTime.isNotEmpty;

  /// A completed booking still needs someone at the salon to confirm the
  /// customer actually paid.
  bool get paymentPending => status == 'completed' && !paymentReceived;

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final ts = m['date'];
    final pts = m['pendingRescheduleDate'];
    final paidTs = m['paymentReceivedAt'];
    return Appointment(
      id: d.id,
      userId: (m['userId'] ?? '').toString(),
      serviceId: (m['serviceId'] ?? '').toString(),
      serviceName: (m['serviceName'] ?? 'Service').toString(),
      staffName: (m['staffName'] ?? '').toString(),
      timeLabel: (m['time'] ?? '').toString(),
      status: (m['status'] ?? 'pending').toString().toLowerCase(),
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      price: _toNum(m['price']),
      duration: _toNum(m['duration']).toInt(),
      customerName: (m['customerName'] ?? '').toString(),
      rating: _toNum(m['rating']).toInt().clamp(0, 5),
      review: (m['review'] ?? '').toString(),
      rescheduleCount: _toNum(m['rescheduleCount']).toInt(),
      rescheduleReason: (m['rescheduleReason'] ?? '').toString(),
      pendingRescheduleDate: pts is Timestamp ? pts.toDate() : null,
      pendingRescheduleTime: (m['pendingRescheduleTime'] ?? '').toString(),
      pendingRescheduleStaff: (m['pendingRescheduleStaff'] ?? '').toString(),
      pendingRescheduleReason: (m['pendingRescheduleReason'] ?? '').toString(),
      paymentReceived: m['paymentReceived'] == true,
      paymentReceivedAt: paidTs is Timestamp ? paidTs.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'staffName': staffName,
        'time': timeLabel,
        'status': status,
        'date': Timestamp.fromDate(date),
        'dateKey': dateKey(date),
        'price': price,
        'duration': duration,
        'customerName': customerName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class ServiceItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final int duration; // minutes
  final num price;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.duration,
    required this.price,
  });

  /// Built from the maps returned by ServiceRepository.getServices().
  factory ServiceItem.fromMap(Map<String, dynamic> m) {
    final name = (m['name'] ?? m['serviceName'] ?? 'Service').toString();
    final cat = (m['category'] ?? '').toString();
    return ServiceItem(
      id: (m['id'] ?? name).toString(),
      name: name,
      description: (m['description'] ?? '').toString(),
      category: cat.isNotEmpty ? cat : guessCategory(name),
      imageUrl: (m['imageUrl'] ?? m['image'] ?? m['imageURL'] ?? '').toString(),
      duration: _toNum(m['duration'] ?? m['durationMinutes']).toInt(),
      price: _toNum(m['price']),
    );
  }

  /// Used only when a service document has no 'category' field.
  static String guessCategory(String name) {
    final n = name.toLowerCase();
    if (RegExp(r'nail|mani|pedi').hasMatch(n)) return 'Nails';
    if (RegExp(r'massage|spa|body').hasMatch(n)) return 'Massage';
    if (RegExp(r'facial|skin|peel|whiten|derma').hasMatch(n)) return 'Skin';
    if (RegExp(r'hair|cut|color|colour|style|rebond|perm|blow|treatment').hasMatch(n)) {
      return 'Hair';
    }
    return 'Other';
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  const StaffMember({required this.id, required this.name, this.role = 'Beautician'});
}