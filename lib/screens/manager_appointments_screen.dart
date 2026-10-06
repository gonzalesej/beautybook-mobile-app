import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Manager-wide view of every appointment, across all staff.
/// Read-only: confirming/completing/cancelling stays with Staff.
class ManagerAppointmentsScreen extends StatelessWidget {
  const ManagerAppointmentsScreen({super.key});

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text('Bookings', style: AppText.display(30)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration:
                  BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(28)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: AppColors.primaryDark, borderRadius: BorderRadius.circular(24)),
                labelColor: AppColors.cream,
                unselectedLabelColor: AppColors.cocoa,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed'), Tab(text: 'Cancelled')],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Appointment>>(
                stream: AppointmentRepository().watchAll(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.rose));
                  }
                  if (snap.hasError) {
                    return const ErrorRetry(message: 'Could not load bookings.', onRetry: _noop);
                  }
                  final all = snap.data ?? [];
                  return TabBarView(children: [
                    _list(all.where((a) => a.isUpcoming).toList(), 'No upcoming bookings.'),
                    _list(all.where((a) => a.status == 'completed').toList(),
                        'No completed bookings yet.'),
                    _list(all.where((a) => a.status == 'cancelled').toList(),
                        'No cancelled bookings.'),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _list(List<Appointment> items, String empty) {
    if (items.isEmpty) {
      return Center(child: Text(empty, style: AppText.body(15, color: AppColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _BookingCard(appointment: items[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Appointment appointment;
  const _BookingCard({required this.appointment});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.rose;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return AppColors.muted;
      default:
        return AppColors.blush;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a.serviceName, style: AppText.body(16, w: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(a.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              a.status[0].toUpperCase() + a.status.substring(1),
              style: AppText.body(11.5, color: _statusColor(a.status), w: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _row(Icons.calendar_today_rounded, DateFormat('EEE, MMM d, yyyy').format(a.date)),
        _row(Icons.access_time_rounded, a.timeLabel),
        _row(Icons.person_rounded,
            'Customer: ${a.customerName.isEmpty ? 'Unknown' : a.customerName}'),
        _row(Icons.badge_rounded, 'Staff: ${a.staffName.isEmpty ? 'Unassigned' : a.staffName}'),
        _row(Icons.payments_rounded, '₱${a.price} · ${a.duration} min'),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(text, style: AppText.body(13, color: AppColors.muted)),
        ]),
      );
}