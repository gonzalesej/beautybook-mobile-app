import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/staff_appointment_card.dart';

/// Every booking in the salon, filtered by status.
class ManagerBookingsScreen extends StatefulWidget {
  const ManagerBookingsScreen({super.key});

  @override
  State<ManagerBookingsScreen> createState() => _ManagerBookingsScreenState();
}

class _ManagerBookingsScreenState extends State<ManagerBookingsScreen> {
  static const _filters = [
    'all',
    'pending',
    'requests',
    'confirmed',
    'completed',
    'declined',
    'cancelled',
    'no-show',
  ];
  String _filter = 'all';

  static void _noop() {}

  static String _label(String f) {
    switch (f) {
      case 'requests':
        return 'Reschedule requests';
      case 'no-show':
        return 'No-Show';
      default:
        return f[0].toUpperCase() + f.substring(1);
    }
  }

  bool _matches(Appointment a) {
    switch (_filter) {
      case 'all':
        return true;
      case 'requests':
        return a.isActive && a.hasPendingReschedule;
      default:
        return a.status == _filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text('All Bookings', style: AppText.display(30)),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryDark : AppColors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(_label(f),
                        style: AppText.body(14,
                            color: sel ? AppColors.cream : AppColors.cocoa, w: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
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
                final items = (snap.data ?? []).where(_matches).toList();
                items.sort((a, b) {
                  final c = b.date.compareTo(a.date);
                  return c != 0 ? c : b.minutes.compareTo(a.minutes);
                });
                if (items.isEmpty) {
                  return Center(
                      child: Text('No bookings found.',
                          style: AppText.body(15, color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      StaffAppointmentCard(appointment: items[i], showStaff: true),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}