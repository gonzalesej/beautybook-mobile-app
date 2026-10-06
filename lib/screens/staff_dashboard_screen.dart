import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/staff_appointment_card.dart';

class StaffDashboardScreen extends StatelessWidget {
  final EmployeeProfile profile;
  final VoidCallback onSeeAll;
  const StaffDashboardScreen({super.key, required this.profile, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final first = profile.name.isNotEmpty ? profile.name.split(' ').first : 'there';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Appointment>>(
          stream: AppointmentRepository().watchForStaff(profile.name),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snap.hasError) {
              return const ErrorRetry(message: 'Could not load your schedule.', onRetry: _noop);
            }
            final all = snap.data ?? [];
            final todayKey = dateKey(DateTime.now());
            final today = all
                .where((a) => dateKey(a.date) == todayKey && a.status != 'cancelled')
                .toList();
            final pending = all.where((a) => a.status == 'pending').toList();
            final doneToday = today.where((a) => a.status == 'completed').length;
            final awaiting =
                pending.where((a) => dateKey(a.date) != todayKey).take(3).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${greeting()},',
                          style: AppText.body(15, color: AppColors.textSecondary)),
                      Text(first, style: AppText.display(30)),
                    ]),
                  ),
                  Text('Staff',
                      style: AppText.body(14, color: AppColors.primaryDark, w: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(prettyDate(DateTime.now()),
                    style: AppText.body(15, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(children: [
                  _stat('Today', '${today.length}', Icons.today_rounded),
                  const SizedBox(width: 10),
                  _stat('Pending', '${pending.length}', Icons.hourglass_bottom_rounded),
                  const SizedBox(width: 10),
                  _stat('Done today', '$doneToday', Icons.check_circle_outline_rounded),
                ]),
                const SizedBox(height: 26),
                Text("Today's schedule", style: AppText.display(20)),
                const SizedBox(height: 12),
                if (profile.name.isEmpty)
                  _note('Your Employee record has no name yet, so no bookings can be matched.')
                else if (today.isEmpty)
                  _note('No appointments scheduled for today.')
                else
                  for (final a in today) ...[
                    StaffAppointmentCard(appointment: a),
                    const SizedBox(height: 12),
                  ],
                if (awaiting.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Awaiting confirmation', style: AppText.display(20)),
                    TextButton(onPressed: onSeeAll, child: const Text('See all')),
                  ]),
                  const SizedBox(height: 6),
                  for (final a in awaiting) ...[
                    StaffAppointmentCard(appointment: a),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static void _noop() {}

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppText.display(28)),
          Text(label, style: AppText.body(12.5, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _note(String text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Icon(Icons.event_available_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: AppText.body(14.5, color: AppColors.textSecondary))),
        ]),
      );
}