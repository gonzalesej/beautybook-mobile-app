import 'package:flutter/material.dart';
import '../services/service_list.dart';
import '../theme/app_theme.dart';
import 'appointments_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// 0 Home, 1 Appointments, 2 Services, 3 Profile
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const AppointmentsScreen();
      case 2:
        return const ServiceListPage();
      default:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) => Scaffold(
        body: _page(index),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primaryDark, borderRadius: BorderRadius.circular(34)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _item(0, Icons.home_rounded, 'Home', index),
                _item(1, Icons.event_note_rounded, 'Appointments', index),
                _item(2, Icons.spa_rounded, 'Services', index),
                _item(3, Icons.person_rounded, 'Profile', index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, int current) {
    final selected = i == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => shellTab.value = i,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12, vertical: 10),
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