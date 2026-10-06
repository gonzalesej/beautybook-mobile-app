import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/service_list.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _firstName(User? u) {
    final n = u?.displayName?.trim() ?? '';
    if (n.isNotEmpty) return n.split(' ').first;
    final e = u?.email ?? '';
    return e.contains('@') ? e.split('@').first : 'there';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snap) => _body(context, snap.data),
    );
  }

  Widget _body(BuildContext context, User? user) {
    final name = _firstName(user);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${greeting()},', style: AppText.body(15, color: AppColors.textSecondary)),
                  Text(name, style: AppText.display(30)),
                ]),
              ),
              GestureDetector(
                onTap: () => shellTab.value = 3,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: AppText.display(20, color: AppColors.white)),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Plan your perfect beauty day ✨', style: AppText.body(15, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Text('Quick Actions', style: AppText.display(20)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final c in const ['Hair', 'Nails', 'Skin', 'Massage']) _quick(context, c)],
            ),
            const SizedBox(height: 26),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text('Upcoming Appointment',
                    style: AppText.display(20), overflow: TextOverflow.ellipsis),
              ),
              TextButton(onPressed: () => shellTab.value = 1, child: const Text('See all')),
            ]),
            const SizedBox(height: 6),
            _upcoming(context, user),
          ],
        ),
      ),
    );
  }

  Widget _quick(BuildContext context, String c) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ServiceListPage(initialCategory: c))),
      child: Column(children: [
        Container(
          width: 66,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(33), bottom: Radius.circular(18)),
          ),
          child: Icon(categoryIcon(c), color: AppColors.primary, size: 26),
        ),
        const SizedBox(height: 8),
        Text(c, style: AppText.body(13, w: FontWeight.w600)),
      ]),
    );
  }

  Widget _upcoming(BuildContext context, User? user) {
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<List<Appointment>>(
      stream: AppointmentRepository().watchForUser(user.uid),
      builder: (context, snap) {
        final list = (snap.data ?? []).where((a) => a.isUpcoming).toList();
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.accent.withAlpha(35), borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              const Icon(Icons.event_available_outlined, color: AppColors.primary, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text('No upcoming appointments yet. Treat yourself!',
                    style: AppText.body(14.5, color: AppColors.textSecondary)),
              ),
            ]),
          );
        }
        final a = list.first;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  Text(monthShort(a.date).toUpperCase(),
                      style: AppText.body(11, color: AppColors.primary, w: FontWeight.w700)),
                  Text('${a.date.day}', style: AppText.display(22)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.serviceName, style: AppText.display(18)),
                  const SizedBox(height: 3),
                  Text('${prettyDate(a.date)} · ${a.timeLabel}',
                      style: AppText.body(13, color: AppColors.textSecondary)),
                ]),
              ),
              StatusChip(a.status),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'View Details', outlined: true, onPressed: () => showAppointmentDetails(context, a)),
          ]),
        );
      },
    );
  }
}

void showAppointmentDetails(BuildContext context, Appointment a) {
  Widget row(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(i, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(t, style: AppText.body(15.5))),
        ]),
      );
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        // starts at 45% of the screen, can be dragged up to 90%, and
        // will never be forced taller than the content needs.
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(children: [
                      Expanded(child: Text(a.serviceName, style: AppText.display(24))),
                      StatusChip(a.status),
                    ]),
                    const SizedBox(height: 18),
                    row(Icons.calendar_today_outlined, prettyDate(a.date)),
                    row(Icons.schedule_rounded, '${a.timeLabel} · ${a.duration} min'),
                    row(Icons.person_outline_rounded, 'with ${a.staffName}'),
                    row(Icons.payments_outlined, peso(a.price)),
                    if (a.hasRescheduled) row(Icons.event_repeat_rounded, 'Already rescheduled once'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}