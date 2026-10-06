import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/main_shell.dart';
import '../screens/manager_shell.dart';
import '../screens/staff_shell.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';

/// Decides which app a signed-in user sees: customer, staff or manager.
class RoleGate extends StatefulWidget {
  final User user;
  const RoleGate({super.key, required this.user});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  late Future<EmployeeProfile?> _future;

  @override
  void initState() {
    super.initState();
    _future = RoleRepository().findEmployee(widget.user.email ?? '');
  }

  @override
  void didUpdateWidget(covariant RoleGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _future = RoleRepository().findEmployee(widget.user.email ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmployeeProfile?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.rose));
        }
        final profile = snap.data;
        if (profile == null) return const MainShell(); // customer
        if (profile.role == UserRole.staff) return StaffShell(profile: profile);
        return ManagerShell(profile: profile);
      },
    );
  }
}