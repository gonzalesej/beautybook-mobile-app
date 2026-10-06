import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../services/appointment_repository.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

enum _Range { today, week, month, all, custom }

/// Overview and simple reports for the manager.
class ManagerDashboardScreen extends StatefulWidget {
  final EmployeeProfile profile;
  const ManagerDashboardScreen({super.key, required this.profile});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  static void _noop() {}

  // Created once so tapping a filter chip doesn't reload the stream.
  final Stream<List<Appointment>> _stream = AppointmentRepository().watchAll();

  _Range _preset = _Range.month;
  DateTimeRange? _custom;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _short(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// The selected range as (start, end) dates, or null for "all time".
  DateTimeRange? get _range {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (_preset) {
      case _Range.today:
        return DateTimeRange(start: today, end: today);
      case _Range.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: monday, end: monday.add(const Duration(days: 6)));
      case _Range.month:
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0),
        );
      case _Range.custom:
        return _custom;
      case _Range.all:
        return null;
    }
  }

  String get _rangeLabel {
    final r = _range;
    if (r == null) return 'Showing all time';
    if (r.start == r.end) return 'Showing ${_short(r.start)}, ${r.start.year}';
    return 'Showing ${_short(r.start)} – ${_short(r.end)}, ${r.end.year}';
  }

  bool _inRange(Appointment a) {
    final r = _range;
    if (r == null) return true;
    final d = DateTime(a.date.year, a.date.month, a.date.day);
    return !d.isBefore(r.start) && !d.isAfter(r.end);
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _custom,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.rose,
                onPrimary: AppColors.white,
                onSurface: AppColors.cocoa,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _custom = DateTimeRange(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        );
        _preset = _Range.custom;
      });
    }
  }

  List<MapEntry<String, int>> _rank(Iterable<Appointment> list, String Function(Appointment) key) {
    final counts = <String, int>{};
    for (final a in list) {
      final k = key(a).trim().isEmpty ? 'Unknown' : key(a);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Average rating per service (only rated bookings), best first.
  /// The label includes the number of reviews, like "Facial (5)".
  List<MapEntry<String, double>> _avgByService(Iterable<Appointment> rated) {
    final sums = <String, int>{};
    final counts = <String, int>{};
    for (final a in rated) {
      final k = a.serviceName.trim().isEmpty ? 'Unknown' : a.serviceName;
      sums[k] = (sums[k] ?? 0) + a.rating;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final entries = [
      for (final k in sums.keys) MapEntry('$k (${counts[k]})', sums[k]! / counts[k]!),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final first = profile.name.isNotEmpty ? profile.name.split(' ').first : 'Manager';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Appointment>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.rose));
            }
            if (snap.hasError) {
              return const ErrorRetry(message: 'Could not load the overview.', onRetry: _noop);
            }
            final all = snap.data ?? [];
            final now = DateTime.now();
            final todayKey = dateKey(now);

            // Live snapshot (not affected by the date filter)
            final today = all
                .where((a) => dateKey(a.date) == todayKey && !a.isCancelledOrDeclined)
                .length;
            final pending = all.where((a) => a.status == 'pending').length;
            final requests = all.where((a) => a.isActive && a.hasPendingReschedule).length;

            // Everything below follows the selected date range
            final scoped = all.where(_inRange).toList();
            final rangeBookings = scoped.where((a) => !a.isCancelledOrDeclined).length;
            final revenue = scoped
                .where((a) => a.status == 'completed')
                .fold<num>(0, (sum, a) => sum + a.price);

            // Ratings
            final rated = scoped.where((a) => a.isRated).toList();
            final reviewCount = rated.length;
            final avgRating = reviewCount == 0
                ? null
                : rated.fold<int>(0, (sum, a) => sum + a.rating) / reviewCount;
            final avgLabel = avgRating == null ? '—' : '${avgRating.toStringAsFixed(1)} ★';
            final ratingByService = _avgByService(rated);

            final byStatus = <MapEntry<String, int>>[
              for (final s in const [
                'pending', 'confirmed', 'completed', 'declined', 'cancelled', 'no-show'
              ])
                MapEntry(
                    s == 'no-show' ? 'No-Show' : s[0].toUpperCase() + s.substring(1),
                    scoped.where((a) => a.status == s).length),
            ];
            final active = scoped.where((a) => !a.isCancelledOrDeclined);
            final topServices = _rank(active, (a) => a.serviceName);
            final byStaff = _rank(active, (a) => a.staffName);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${greeting()},', style: AppText.body(15, color: AppColors.muted)),
                      Text(first, style: AppText.display(30)),
                    ]),
                  ),
                  Text('Manager',
                      style: AppText.body(14, color: AppColors.rose, w: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(prettyDate(now), style: AppText.body(15, color: AppColors.muted)),
                const SizedBox(height: 20),
                Row(children: [
                  _stat('Today', '$today', Icons.today_rounded),
                  const SizedBox(width: 10),
                  _stat('Pending', '$pending', Icons.hourglass_bottom_rounded),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _stat('Reschedule requests', '$requests', Icons.event_repeat_rounded),
                ]),
                const SizedBox(height: 22),

                // ---- Date filter ----
                Text('Report period', style: AppText.display(20)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('Today', _Range.today),
                  _chip('This week', _Range.week),
                  _chip('This month', _Range.month),
                  _chip('All time', _Range.all),
                  _chip('Custom', _Range.custom, icon: Icons.date_range_rounded),
                ]),
                const SizedBox(height: 8),
                Text(_rangeLabel, style: AppText.body(13.5, color: AppColors.muted)),
                const SizedBox(height: 14),

                Row(children: [
                  _stat('Bookings', '$rangeBookings', Icons.event_available_rounded),
                  const SizedBox(width: 10),
                  _stat('Income', peso(revenue), Icons.payments_outlined),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _stat('Average rating', avgLabel, Icons.star_rounded),
                  const SizedBox(width: 10),
                  _stat('Reviews', '$reviewCount', Icons.rate_review_outlined),
                ]),
                const SizedBox(height: 26),
                _section('Bookings by status', byStatus),
                _section('Top services', topServices),
                _section('Bookings per beautician', byStaff),
                _ratingSection('Average rating per service', ratingByService),
                _reviewsSection(rated),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, _Range value, {IconData? icon}) {
    final selected = _preset == value;
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) {
        if (value == _Range.custom) {
          _pickCustom();
        } else {
          setState(() => _preset = value);
        }
      },
      selectedColor: AppColors.primaryDark,
      backgroundColor: AppColors.white,
      side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.sand),
      avatar: icon == null
          ? null
          : Icon(icon, size: 18, color: selected ? AppColors.white : AppColors.cocoa),
      label: Text(
        label,
        style: AppText.body(13.5,
            color: selected ? AppColors.white : AppColors.cocoa, w: FontWeight.w600),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.sand),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.rose, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(13.5, color: AppColors.muted)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppText.display(24)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _section(String title, List<MapEntry<String, int>> items) {
    final maxValue = items.isEmpty ? 1 : items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.display(20)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.sand),
          ),
          child: items.isEmpty || items.every((e) => e.value == 0)
              ? Text('No data for this period.', style: AppText.body(14, color: AppColors.muted))
              : Column(children: [
                  for (final e in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: Text(e.key,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(14, w: FontWeight.w600))),
                          Text('${e.value}',
                              style: AppText.body(14, color: AppColors.rose, w: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: maxValue == 0 ? 0 : e.value / maxValue,
                            minHeight: 8,
                            backgroundColor: AppColors.sand,
                            valueColor: const AlwaysStoppedAnimation(AppColors.rose),
                          ),
                        ),
                      ]),
                    ),
                ]),
        ),
      ]),
    );
  }

  /// Same look as _section, but for average ratings (0-5) instead of counts.
  Widget _ratingSection(String title, List<MapEntry<String, double>> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.display(20)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.sand),
          ),
          child: items.isEmpty
              ? Text('No ratings for this period.',
                  style: AppText.body(14, color: AppColors.muted))
              : Column(children: [
                  for (final e in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: Text(e.key,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(14, w: FontWeight.w600))),
                          Text('${e.value.toStringAsFixed(1)} ★',
                              style: AppText.body(14, color: AppColors.rose, w: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (e.value / 5).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.sand,
                            valueColor: const AlwaysStoppedAnimation(AppColors.rose),
                          ),
                        ),
                      ]),
                    ),
                ]),
        ),
      ]),
    );
  }

  /// Latest customer reviews (written comments) for the selected period.
  Widget _reviewsSection(List<Appointment> rated) {
    final sorted = [...rated]..sort((a, b) => b.date.compareTo(a.date));
    final shown = sorted.take(10).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Customer reviews', style: AppText.display(20)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.sand),
          ),
          child: shown.isEmpty
              ? Text('No reviews for this period.',
                  style: AppText.body(14, color: AppColors.muted))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 26, color: AppColors.sand),
                    _reviewTile(shown[i]),
                  ],
                  if (sorted.length > shown.length) ...[
                    const SizedBox(height: 14),
                    Text('Showing the latest ${shown.length} of ${sorted.length} reviews',
                        style: AppText.body(12.5, color: AppColors.muted)),
                  ],
                ]),
        ),
      ]),
    );
  }

  Widget _reviewTile(Appointment a) {
    final customer = a.customerName.trim();
final text = a.review.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(customer.isEmpty ? 'Customer' : customer,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(14.5, w: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Text(prettyDate(a.date), style: AppText.body(12.5, color: AppColors.muted)),
      ]),
      const SizedBox(height: 2),
      Text('${a.serviceName} · Staff: ${a.staffName}',
          style: AppText.body(13, color: AppColors.muted)),
      const SizedBox(height: 8),
      Row(children: [
        for (var s = 1; s <= 5; s++)
          Icon(s <= a.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18, color: AppColors.rose),
      ]),
      const SizedBox(height: 8),
      Text(
        text.isEmpty ? 'No written review.' : text,
        style: text.isEmpty
            ? AppText.body(14, color: AppColors.muted)
            : AppText.body(14),
      ),
    ]);
  }
}