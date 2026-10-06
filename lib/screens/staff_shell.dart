import 'package:flutter/material.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'staff_appointments_screen.dart';
import 'staff_dashboard_screen.dart';

/// Bottom navigation for staff: Dashboard, Appointments, Profile.
class StaffShell extends StatefulWidget {
  final EmployeeProfile profile;
  const StaffShell({super.key, required this.profile});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  Widget _page() {
    switch (_index) {
      case 0:
        return StaffDashboardScreen(
          profile: widget.profile,
          onSeeAll: () => setState(() => _index = 1),
        );
      case 1:
        return StaffAppointmentsScreen(profile: widget.profile);
      default:
        return const ProfileScreen(showShortcut: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primaryDark, borderRadius: BorderRadius.circular(34)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _item(0, Icons.dashboard_rounded, 'Dashboard'),
              _item(1, Icons.event_note_rounded, 'Appointments'),
              _item(2, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final selected = i == _index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _index = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: selected ? AppColors.primaryDark : Colors.white70),
          if (selected) ...[
            const SizedBox(width: 6),
            Text(label, style: AppText.body(12.5, color: AppColors.primaryDark, w: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}