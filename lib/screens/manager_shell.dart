import 'package:flutter/material.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import 'manager_bookings_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_services_screen.dart';
import 'manager_staff_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation for the manager.
class ManagerShell extends StatefulWidget {
  final EmployeeProfile profile;
  const ManagerShell({super.key, required this.profile});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  Widget _page() {
    switch (_index) {
      case 0:
        return ManagerDashboardScreen(profile: widget.profile);
      case 1:
        return const ManagerBookingsScreen();
      case 2:
        return const ManagerServicesScreen();
      case 3:
        return const ManagerStaffScreen();
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primaryDark, borderRadius: BorderRadius.circular(34)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _item(0, Icons.dashboard_rounded, 'Overview'),
              _item(1, Icons.event_note_rounded, 'Bookings'),
              _item(2, Icons.spa_rounded, 'Services'),
              _item(3, Icons.groups_rounded, 'Staff'),
              _item(4, Icons.person_rounded, 'Profile'),
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
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: selected ? AppColors.primaryDark : AppColors.accent),
          if (selected) ...[
            const SizedBox(width: 6),
            Text(label, style: AppText.body(12.5, color: AppColors.primaryDark, w: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}