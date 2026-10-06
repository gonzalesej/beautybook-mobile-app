import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/service_mapper.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class BookAppointmentScreen extends StatefulWidget {
  final ServiceItem? service;
  /// When set, this screen is in reschedule mode: it edits [rescheduling]
  /// instead of creating a new appointment.
  final Appointment? rescheduling;
  final String? rescheduleReason;
  const BookAppointmentScreen({
    super.key,
    this.service,
    this.rescheduling,
    this.rescheduleReason,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _repo = AppointmentRepository();
  static const _stepTitles = ['Service', 'Date & Time', 'Beautician', 'Confirm'];

  bool get _isReschedule => widget.rescheduling != null;

  int _step = 0;
  ServiceItem? _service;
  DateTime? _date;
  String? _time;
  StaffMember? _staff;

  late Future<List<ServiceItem>> _servicesFuture;
  List<StaffMember> _staffList = [];
  List<Appointment> _dayBookings = [];
  bool _loadingSlots = false;
  bool _saving = false;

  // 9:00 AM - 5:00 PM, hourly
  final List<int> _slotMinutes = [for (var m = 540; m <= 1020; m += 60) m];

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _servicesFuture = loadServices();
    _repo.loadStaff().then((s) {
      if (mounted) setState(() => _staffList = s);
    });
    if (widget.service != null) _step = 1; // service already chosen

    // select today by default so the calendar and the time list start in sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = DateTime.now();
      _pickDate(DateTime(t.year, t.month, t.day));
    });
  }

  bool get _canNext {
    switch (_step) {
      case 0:
        return _service != null;
      case 1:
        return _date != null && _time != null;
      case 2:
        return _staff != null;
      default:
        return true;
    }
  }

  // ---------- availability (duration-aware) ----------

  /// Length of the chosen service in minutes (60 if unknown).
  int get _serviceMinutes {
    final d = _service?.duration ?? 0;
    return d > 0 ? d : 60;
  }

  /// True if an existing booking overlaps a booking that would start at
  /// [startMin] and last as long as the chosen service.
  bool _overlaps(Appointment b, int startMin) {
    final bStart = b.minutes;
    final bEnd = bStart + (b.duration > 0 ? b.duration : 60);
    return startMin < bEnd && bStart < startMin + _serviceMinutes;
  }

  bool _staffBusy(StaffMember s, String time) {
    final start = labelToMinutes(time);
    return _dayBookings.any((b) => b.staffName == s.name && _overlaps(b, start));
  }

  bool _slotDisabled(int minutes) {
    final label = minutesToLabel(minutes);
    if (_staffList.isNotEmpty && _staffList.every((s) => _staffBusy(s, label))) return true;
    final now = DateTime.now();
    if (_date != null && dateKey(_date!) == dateKey(now)) {
      return minutes <= now.hour * 60 + now.minute + 30;
    }
    return false;
  }

  /// Drops the booking being rescheduled from a list so it never counts as
  /// busy against itself.
  List<Appointment> _excludeSelf(List<Appointment> list) {
    final selfId = widget.rescheduling?.id;
    if (selfId == null) return list;
    return list.where((x) => x.id != selfId).toList();
  }

  Future<void> _pickDate(DateTime d) async {
    if (!mounted) return;
    setState(() {
      _date = d;
      _time = null;
      _staff = null;
      _loadingSlots = true;
    });
    try {
      final b = await _repo.bookingsForDate(d);
      if (mounted) setState(() => _dayBookings = _excludeSelf(b));
    } catch (_) {
      if (mounted) setState(() => _dayBookings = []);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _service == null || _date == null || _time == null || _staff == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      // re-check right before saving so two people can't take the same slot
      final latest = _excludeSelf(await _repo.bookingsForDate(_date!));
      final start = labelToMinutes(_time!);
      final taken =
          latest.any((b) => b.staffName == _staff!.name && _overlaps(b, start));
      if (taken) {
        if (mounted) {
          setState(() {
            _dayBookings = latest;
            _step = 1;
            _time = null;
            _staff = null;
          });
          showSnack(context, 'Sorry, that slot was just taken. Please pick another.');
        }
        return;
      }

      if (_isReschedule) {
        final original = widget.rescheduling!;
        await _repo.reschedule(
          id: original.id,
          newDate: _date!,
          newTime: _time!,
          newStaffName: _staff!.name,
          reason: widget.rescheduleReason ?? '',
          currentRescheduleCount: original.rescheduleCount,
        );
        if (!mounted) return;
        shellTab.value = 1;
        Navigator.of(context).popUntil((r) => r.isFirst);
        showSnack(context, 'Appointment rescheduled ✓');
      } else {
        await _repo.create(Appointment(
          id: '',
          userId: user.uid,
          customerName: user.displayName ?? user.email ?? '',
          serviceId: _service!.id,
          serviceName: _service!.name,
          staffName: _staff!.name,
          timeLabel: _time!,
          status: 'pending',
          date: _date!,
          price: _service!.price,
          duration: _service!.duration,
        ));
        if (!mounted) return;
        shellTab.value = 1;
        Navigator.of(context).popUntil((r) => r.isFirst);
        showSnack(context, 'Appointment booked! ✨');
      }
    } catch (_) {
      if (mounted) {
        showSnack(context,
            _isReschedule ? 'Could not reschedule. Please try again.' : 'Could not book. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == 3) {
      _confirm();
    } else {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step == 0 || (_step == 1 && widget.service != null)) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: _back),
              const SizedBox(width: 14),
              Expanded(
                child: Text(_isReschedule ? 'Reschedule Appointment' : 'Book Appointment',
                    style: AppText.display(24)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.rose : AppColors.sand,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_stepTitles[i],
                        style: AppText.body(11.5,
                            color: i == _step ? AppColors.cocoa : AppColors.muted,
                            w: i == _step ? FontWeight.w700 : FontWeight.w500)),
                  ]),
                ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
            child: FilledButton(
              onPressed: (_canNext && !_saving) ? _next : null,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cream))
                  : Text(_step == 3
                      ? (_isReschedule ? 'Confirm Reschedule' : 'Confirm Appointment')
                      : 'Continue'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _serviceStep();
      case 1:
        return _dateTimeStep();
      case 2:
        return _staffStep();
      default:
        return _reviewStep();
    }
  }

  Widget _heading(String t, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: AppText.display(24)),
          const SizedBox(height: 4),
          Text(sub, style: AppText.body(14, color: AppColors.muted)),
        ]),
      );

  Widget _selectable({required bool selected, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.border : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: child,
      ),
    );
  }

  Widget _serviceStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Choose a service', 'What would you like today?'),
      FutureBuilder<List<ServiceItem>>(
        future: _servicesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.rose)));
          }
          if (snap.hasError) {
            return ErrorRetry(
                message: 'Could not load services.',
                onRetry: () => setState(() => _servicesFuture = loadServices()));
          }
          return Column(children: [
            for (final s in snap.data ?? <ServiceItem>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _selectable(
                  selected: _service?.id == s.id,
                  onTap: () => setState(() => _service = s),
                  child: Row(children: [
                    ServiceImage(
                        url: s.imageUrl, category: s.category, width: 56, height: 56, radius: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: AppText.body(16, w: FontWeight.w700)),
                        Text('${s.duration} min',
                            style: AppText.body(13, color: AppColors.muted)),
                      ]),
                    ),
                    Text(peso(s.price),
                        style: AppText.body(16, color: AppColors.rose, w: FontWeight.w700)),
                  ]),
                ),
              ),
          ]);
        },
      ),
    ]);
  }

  Widget _dateTimeStep() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Pick a date & time', 'Open hours: 9:00 AM – 5:00 PM'),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.sand),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: scheme.copyWith(
                  primary: AppColors.rose,
                  onPrimary: AppColors.white,
                  onSurface: AppColors.cocoa,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _date ?? first,
                firstDate: first,
                lastDate: first.add(const Duration(days: 60)),
                onDateChanged: _pickDate,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text('Available times', style: AppText.display(18)),
      const SizedBox(height: 10),
      if (_date == null)
        Text('Select a date first.', style: AppText.body(14, color: AppColors.muted))
      else if (_loadingSlots)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.rose)))
      else
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final m in _slotMinutes) _slotChip(m),
        ]),
    ]);
  }

  Widget _slotChip(int m) {
    final label = minutesToLabel(m);
    final disabled = _slotDisabled(m);
    final sel = _time == label;
    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(() {
                _time = label;
                _staff = null;
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.rose : (disabled ? AppColors.sand : AppColors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: sel ? AppColors.rose : AppColors.sand),
        ),
        child: Text(
          label,
          style: AppText.body(14,
                  color: sel
                      ? AppColors.white
                      : (disabled ? AppColors.muted.withAlpha(140) : AppColors.cocoa),
                  w: FontWeight.w600)
              .copyWith(decoration: disabled ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }

  Widget _staffStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Choose your beautician', 'Available at $_time'),
      for (final s in _staffList)
        Builder(builder: (_) {
          final busy = _time != null && _staffBusy(s, _time!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Opacity(
              opacity: busy ? 0.45 : 1,
              child: _selectable(
                selected: _staff?.id == s.id,
                onTap: busy ? null : () => setState(() => _staff = s),
                child: Row(children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.blush,
                    child: Text(s.name[0].toUpperCase(),
                        style: AppText.display(22, color: AppColors.rose)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.name, style: AppText.body(16, w: FontWeight.w700)),
                      Text(busy ? 'Not available' : s.role,
                          style: AppText.body(13, color: AppColors.muted)),
                    ]),
                  ),
                  if (_staff?.id == s.id)
                    const Icon(Icons.check_circle_rounded, color: AppColors.rose),
                ]),
              ),
            ),
          );
        }),
    ]);
  }

  Widget _reviewStep() {
    final s = _service!;
    Widget row(IconData i, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Icon(i, size: 20, color: AppColors.rose),
            const SizedBox(width: 12),
            Text(label, style: AppText.body(14, color: AppColors.muted)),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right, style: AppText.body(15, w: FontWeight.w700)),
            ),
          ]),
        );
    const div = Divider(height: 1, color: AppColors.sand);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Review & confirm', 'Make sure everything looks right.'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.sand)),
        child: Column(children: [
          row(Icons.spa_outlined, 'Service', s.name),
          div,
          if (_isReschedule) ...[
            row(Icons.edit_calendar_outlined, 'Reason', widget.rescheduleReason ?? ''),
            div,
          ],
          row(Icons.calendar_today_outlined, 'Date', prettyDate(_date!)),
          div,
          row(Icons.schedule_rounded, 'Time', '$_time'),
          div,
          row(Icons.person_outline_rounded, 'Beautician', _staff!.name),
          div,
          row(Icons.timelapse_rounded, 'Duration', '${s.duration} min'),
          div,
          row(Icons.payments_outlined, 'Total', peso(s.price)),
        ]),
      ),
      const SizedBox(height: 14),
      Text('Payment is settled at the salon.', style: AppText.body(13, color: AppColors.muted)),
    ]);
  }
}