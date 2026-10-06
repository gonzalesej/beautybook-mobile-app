import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// One booking with the actions staff and managers can take.
class StaffAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool showStaff;
  const StaffAppointmentCard({super.key, required this.appointment, this.showStaff = false});

  Future<void> _set(BuildContext context, String status, String message) async {
    try {
      await AppointmentRepository().updateStatus(appointment.id, status);
      if (context.mounted) showSnack(context, message);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not update. Please try again.');
    }
  }

  Future<void> _cancel(BuildContext context, {bool decline = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(decline ? 'Decline this booking?' : 'Cancel this appointment?'),
        content: Text('${appointment.serviceName} at ${appointment.timeLabel}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(decline ? 'Decline it' : 'Cancel it')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _set(
        context,
        decline ? 'declined' : 'cancelled',
        decline ? 'Appointment declined.' : 'Appointment cancelled.',
      );
    }
  }

  Future<void> _markNoShow(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Mark as No-Show?'),
        content: Text(
            '${appointment.serviceName} at ${appointment.timeLabel}. This means the customer did not arrive and gave no notice. This cannot be undone or rescheduled by the customer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mark No-Show')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await AppointmentRepository().markNoShow(appointment.id);
        if (context.mounted) showSnack(context, 'Marked as no-show.');
      } catch (_) {
        if (context.mounted) showSnack(context, 'Could not update. Please try again.');
      }
    }
  }

  Future<void> _markPaymentReceived(BuildContext context) async {
    final a = appointment;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Confirm payment received?'),
        content: Text('${a.serviceName} — ${peso(a.price)} paid at the salon.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not yet')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await AppointmentRepository().markPaymentReceived(a.id);
        if (context.mounted) showSnack(context, 'Payment marked as received ✓');
      } catch (_) {
        if (context.mounted) showSnack(context, 'Could not update. Please try again.');
      }
    }
  }

  /// Applies the customer's requested date/time, unless that slot is taken.
  Future<void> _approveReschedule(BuildContext context) async {
    final a = appointment;
    final repo = AppointmentRepository();
    try {
      final target = a.pendingRescheduleStaff.isEmpty ? a.staffName : a.pendingRescheduleStaff;
      final taken = await repo.bookingsForDate(a.pendingRescheduleDate!);
      final clash = taken.any((o) =>
          o.id != a.id && o.staffName == target && o.timeLabel == a.pendingRescheduleTime);
      if (clash) {
        if (context.mounted) {
          showSnack(context,
              'That slot is already taken. Reject the request or ask the customer to pick another time.');
        }
        return;
      }
      await repo.approveReschedule(a);
      if (context.mounted) showSnack(context, 'Reschedule approved ✓');
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not update. Please try again.');
    }
  }

  Future<void> _rejectReschedule(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Reject reschedule request?'),
        content: Text(
            'The booking stays on ${prettyDate(appointment.date)} at ${appointment.timeLabel}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep request')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await AppointmentRepository().rejectReschedule(appointment.id);
        if (context.mounted) showSnack(context, 'Request rejected.');
      } catch (_) {
        if (context.mounted) showSnack(context, 'Could not update. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final customer = a.customerName.isEmpty ? 'Customer' : a.customerName;
    const small = Size(0, 44);
    final showRequest = a.isActive && a.hasPendingReschedule;

    Widget? actions;
    if (showRequest) {
      // A pending reschedule request takes priority over the normal buttons.
      actions = Row(children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: small),
            onPressed: () => _approveReschedule(context),
            child: const Text('Approve'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: small),
            onPressed: () => _rejectReschedule(context),
            child: const Text('Reject'),
          ),
        ),
      ]);
    } else if (a.status == 'pending') {
      actions = Row(children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: small),
            onPressed: () => _set(context, 'confirmed', 'Appointment confirmed ✓'),
            child: const Text('Confirm'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: small),
            onPressed: () => _cancel(context, decline: true),
            child: const Text('Decline'),
          ),
        ),
      ]);
    } else if (a.status == 'confirmed' && a.isStale) {
      actions = Row(children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: small),
            onPressed: () => _set(context, 'completed', 'Marked as completed ✓'),
            child: const Text('Mark completed'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: small),
            onPressed: () => _markNoShow(context),
            child: const Text('No-Show'),
          ),
        ),
      ]);
    } else if (a.status == 'confirmed') {
      actions = Row(children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: small),
            onPressed: () => _set(context, 'completed', 'Marked as completed ✓'),
            child: const Text('Mark completed'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: small),
            onPressed: () => _cancel(context),
            child: const Text('Cancel'),
          ),
        ),
      ]);
    } else if (a.paymentPending) {
      // Completed, but nobody has confirmed the customer paid yet.
      actions = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: small),
          onPressed: () => _markPaymentReceived(context),
          icon: const Icon(Icons.payments_rounded, size: 18),
          label: const Text('Mark payment received'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
                color: AppColors.blush, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text(a.timeLabel,
                  style: AppText.body(14, color: AppColors.cocoa, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${weekdayShort(a.date)}, ${monthShort(a.date)} ${a.date.day}',
                  style: AppText.body(11.5, color: AppColors.muted)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.serviceName, style: AppText.display(18)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.rose),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(customer,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13.5, color: AppColors.muted)),
                ),
              ]),
              if (showStaff) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.badge_outlined, size: 16, color: AppColors.rose),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Beautician: ${a.staffName}',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(13.5, color: AppColors.muted)),
                  ),
                ]),
              ],
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.payments_outlined, size: 16, color: AppColors.rose),
                const SizedBox(width: 6),
                Text('${peso(a.price)} · ${a.duration} min',
                    style: AppText.body(13.5, color: AppColors.muted)),
              ]),
              if (a.status == 'completed') ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(
                    a.paymentReceived
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: a.paymentReceived ? AppColors.success : AppColors.rose,
                  ),
                  const SizedBox(width: 6),
                  Text(a.paymentReceived ? 'Payment received' : 'Payment pending',
                      style: AppText.body(13.5,
                          color: a.paymentReceived ? AppColors.success : AppColors.rose,
                          w: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          StatusChip(a.status),
        ]),
        if (showRequest) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.pending_actions_rounded, size: 18, color: AppColors.rose),
                const SizedBox(width: 8),
                Text('Reschedule requested',
                    style: AppText.body(14, color: AppColors.cocoa, w: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Text(
                  'New time: ${prettyDate(a.pendingRescheduleDate!)} at ${a.pendingRescheduleTime}',
                  style: AppText.body(13.5, color: AppColors.cocoa)),
              if (a.pendingRescheduleStaff.isNotEmpty &&
                  a.pendingRescheduleStaff != a.staffName)
                Text('Beautician: ${a.pendingRescheduleStaff}',
                    style: AppText.body(13.5, color: AppColors.cocoa)),
              if (a.pendingRescheduleReason.isNotEmpty)
                Text('Reason: ${a.pendingRescheduleReason}',
                    style: AppText.body(13.5, color: AppColors.muted)),
            ]),
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: 14),
          actions,
        ],
      ]),
    );
  }
}