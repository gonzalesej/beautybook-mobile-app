import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/staff_appointment_card.dart';

class StaffAppointmentsScreen extends StatelessWidget {
  final EmployeeProfile profile;
  const StaffAppointmentsScreen({super.key, required this.profile});

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
              child: Text('Appointments', style: AppText.display(30)),
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
                stream: AppointmentRepository().watchForStaff(profile.name),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.rose));
                  }
                  if (snap.hasError) {
                    return const ErrorRetry(
                        message: 'Could not load appointments.', onRetry: _noop);
                  }
                  final all = snap.data ?? [];
                  // Staff still needs to act on pending/confirmed bookings even
                  // if the original date/time has already passed, so this uses
                  // status directly instead of isUpcoming (which hides stale ones).
                  final active = all
                      .where((a) => a.status == 'pending' || a.status == 'confirmed')
                      .toList();
                  return TabBarView(children: [
                    _list(active, 'No upcoming appointments.'),
                    _list(all.where((a) => a.status == 'completed').toList(),
                        'No completed appointments yet.'),
                    _list(all.where((a) => a.isCancelledOrDeclined).toList(),
                        'No cancelled appointments.'),
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
      itemBuilder: (_, i) => StaffAppointmentCard(appointment: items[i]),
    );
  }
}