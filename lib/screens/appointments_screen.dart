import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/service_mapper.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  static void _noop() {}

  static const _reasons = [
    'Personal emergency',
    'Illness',
    'School/work conflict',
    'Transportation problem',
    'Other',
  ];

  /// Formats a price like ₱500 (or ₱500.50 when it has cents).
  static String _peso(num v) => '₱${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = AppointmentRepository();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text('My Appointments', style: AppText.display(30)),
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
              child: user == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<List<Appointment>>(
                      stream: repo.watchForUser(user.uid),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(color: AppColors.rose));
                        }
                        if (snap.hasError) {
                          return const ErrorRetry(
                              message: 'Could not load appointments.', onRetry: _noop);
                        }
                        final all = snap.data ?? [];
                        return TabBarView(children: [
                          _list(all.where((a) => a.isUpcoming).toList(),
                              'No upcoming appointments.', repo, true),
                          _list(all.where((a) => a.status == 'completed').toList(),
                              'No completed visits yet.', repo, false),
                          _list(all.where((a) => a.isCancelledOrDeclined).toList(),
                              'No cancelled appointments.', repo, false),
                        ]);
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _list(List<Appointment> items, String empty, AppointmentRepository repo, bool canCancel) {
    if (items.isEmpty) {
      return Center(child: Text(empty, style: AppText.body(15, color: AppColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _card(context, items[i], repo, canCancel),
    );
  }

  /// Looks up the current live ServiceItem by serviceId, falling back to
  /// what was saved on the old booking if that service no longer exists.
  Future<ServiceItem> _findService(Appointment a) async {
    try {
      final services = await loadServices();
      for (final s in services) {
        if (s.id == a.serviceId) return s;
      }
    } catch (_) {}
    return ServiceItem(
      id: a.serviceId,
      name: a.serviceName,
      description: '',
      category: ServiceItem.guessCategory(a.serviceName),
      imageUrl: '',
      duration: a.duration,
      price: a.price,
    );
  }

  /// Opens the booking flow with the same service already chosen.
  Future<void> _bookAgain(BuildContext context, Appointment a) async {
    final service = await _findService(a);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookAppointmentScreen(service: service)),
    );
  }

  /// Asks for a reason (dropdown + "Other" text). Returns null if cancelled.
  Future<String?> _askReason(BuildContext context, Appointment a,
      {required String title, String? note}) async {
    String reason = _reasons.first;
    String otherText = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cream,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${a.serviceName} on ${prettyDate(a.date)} at ${a.timeLabel}.',
                  style: AppText.body(13.5, color: AppColors.muted)),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(note, style: AppText.body(13.5, color: AppColors.muted)),
              ],
              const SizedBox(height: 14),
              Text('Reason for rescheduling', style: AppText.body(14, w: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: reason,
                isExpanded: true,
                items: [
                  for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => reason = v ?? _reasons.first),
              ),
              if (reason == 'Other') ...[
                const SizedBox(height: 10),
                TextField(
                  maxLines: 2,
                  maxLength: 120,
                  onChanged: (v) => setState(() => otherText = v),
                  decoration: const InputDecoration(hintText: 'Please specify'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: (reason == 'Other' && otherText.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return reason == 'Other' ? otherText.trim() : reason;
  }

  /// 9:00 AM style label, same shape as the time slots in the booking screen.
  static String _timeLabel(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  /// <24h rule: the customer asks, staff/manager approves or rejects.
  Future<void> _requestReschedule(
      BuildContext context, Appointment a, AppointmentRepository repo) async {
    final reason = await _askReason(
      context,
      a,
      title: 'Request a reschedule',
      note:
          'This booking starts in under 24 hours, so the salon has to approve any change. Next, pick the date and time you would like.',
    );
    if (reason == null || !context.mounted) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !context.mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (t == null || !context.mounted) return;

    final start = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    if (!start.isAfter(now)) {
      showSnack(context, 'Please pick a time in the future.');
      return;
    }

    try {
      await repo.requestReschedule(
        id: a.id,
        newDate: date,
        newTime: _timeLabel(t),
        newStaffName: a.staffName,
        reason: reason,
      );
      if (context.mounted) showSnack(context, 'Request sent. The salon will review it.');
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not send the request. Try again.');
    }
  }

  /// Reschedule flow. 24h+ notice: goes straight to the booking screen.
  /// Under 24h: becomes a request that staff/manager must approve.
  Future<void> _reschedule(BuildContext context, Appointment a, AppointmentRepository repo) async {
    if (a.hasPendingReschedule) {
      showSnack(context, 'You already have a reschedule request waiting for approval.');
      return;
    }
    if (a.hoursUntilStart < 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.cream,
          title: const Text('Reschedule not available'),
          content: const Text(
              'This appointment has already started. Please contact the salon directly.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext), child: const Text('Got it')),
          ],
        ),
      );
      return;
    }
    if (a.hoursUntilStart < 24) {
      await _requestReschedule(context, a, repo);
      return;
    }

    final reason = await _askReason(context, a, title: 'Reschedule appointment');
    if (reason == null) return;
    final service = await _findService(a);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          service: service,
          rescheduling: a,
          rescheduleReason: reason,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Appointment a, AppointmentRepository repo, bool canCancel) {
    const small = Size(0, 42);
    // One info row: icon + text. Text is Expanded so long text wraps
    // instead of overflowing.
    Widget line(IconData i, String t, {Color? color}) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Icon(i, size: 16, color: color ?? AppColors.rose),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t, style: AppText.body(13.5, color: color ?? AppColors.muted)),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.sand)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a.serviceName, style: AppText.display(19))),
          StatusChip(a.status),
        ]),
        const SizedBox(height: 4),
        line(Icons.calendar_today_outlined, prettyDate(a.date)),
        line(Icons.schedule_rounded, a.timeLabel),
        line(Icons.person_outline_rounded, 'Staff: ${a.staffName}'),
        // Price and duration (skipped for old bookings saved without them).
        if (a.price > 0 || a.duration > 0)
          line(
            Icons.payments_outlined,
            [
              if (a.price > 0) _peso(a.price),
              if (a.duration > 0) '${a.duration} min',
            ].join(' · '),
          ),
        // Status message so the customer knows what happened to the booking.
        if (a.status == 'pending')
          line(Icons.hourglass_top_rounded, 'Waiting for confirmation'),
        if (a.status == 'confirmed')
          line(Icons.check_circle_outline_rounded, 'Confirmed by the salon'),
        if (a.status == 'declined')
          line(Icons.info_outline_rounded, 'Declined by the salon'),
        if (a.isNoShow)
          line(Icons.event_busy_rounded, 'Marked as a no-show'),
        if (a.hasRescheduled)
          line(Icons.event_repeat_rounded, 'Already rescheduled once'),
        if (a.hasPendingReschedule)
          line(
            Icons.pending_actions_rounded,
            'Reschedule requested for ${prettyDate(a.pendingRescheduleDate!)} at ${a.pendingRescheduleTime}. Awaiting approval.',
          ),
        // Rating: show stars + review if rated, otherwise a button to rate.
        if (a.status == 'completed') ...[
          const SizedBox(height: 10),
          if (a.isRated) ...[
            Row(children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= a.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: AppColors.rose,
                ),
            ]),
            if (a.review.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(a.review, style: AppText.body(13.5, color: AppColors.muted)),
            ],
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _rate(context, a, repo),
                icon: const Icon(Icons.star_outline_rounded, size: 20),
                label: const Text('Rate this visit'),
              ),
            ),
        ],
        // Book again: for finished bookings (completed, cancelled, declined, no-show).
        if (a.status == 'completed' || a.isCancelledOrDeclined)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _bookAgain(context, a),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text('Book again'),
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (!a.hasRescheduled && !a.hasPendingReschedule) ...[
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: small),
                  onPressed: () => _reschedule(context, a, repo),
                  icon: const Icon(Icons.event_repeat_rounded, size: 18),
                  label: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: small),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.cream,
                      title: const Text('Cancel appointment?'),
                      content:
                          Text('${a.serviceName} on ${prettyDate(a.date)} at ${a.timeLabel}.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Keep it')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Cancel it')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await repo.cancel(a.id);
                    } catch (_) {
                      if (context.mounted) showSnack(context, 'Could not cancel. Try again.');
                    }
                  }
                },
                child: const Text('Cancel'),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  /// Star + review dialog for a completed booking.
  Future<void> _rate(BuildContext context, Appointment a, AppointmentRepository repo) async {
    int stars = 0;
    String review = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cream,
          title: const Text('Rate your visit'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(a.serviceName, style: AppText.body(14, color: AppColors.muted)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 36,
                  onPressed: () => setState(() => stars = i),
                  icon: Icon(
                    i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.rose,
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              maxLength: 200,
              onChanged: (v) => review = v,
              decoration: const InputDecoration(hintText: 'Write a review (optional)'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Not now')),
            TextButton(
                onPressed: stars == 0 ? null : () => Navigator.pop(dialogContext, true),
                child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await repo.rate(a.id, stars, review);
        if (context.mounted) showSnack(context, 'Thanks for your feedback!');
      } catch (_) {
        if (context.mounted) showSnack(context, 'Could not save your rating. Try again.');
      }
    }
  }
}