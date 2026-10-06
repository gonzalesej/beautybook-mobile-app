import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/role_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Profile tab. Name and email come from Firebase Authentication.
/// If the Auth display name is empty (new staff accounts), the name falls back
/// to the `name` field in the Firestore `Employee` collection, then the email prefix.
/// Edit Profile updates the Auth display name and, for staff/managers,
/// the matching `Employee` document too.
class ProfileScreen extends StatefulWidget {
  final bool showShortcut;
  const ProfileScreen({super.key, this.showShortcut = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saving = false;
  String _employeeName = '';

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
  }

  Future<void> _loadEmployeeName() async {
    final email = _user?.email ?? '';
    final emp = await RoleRepository().findEmployee(email);
    if (!mounted || emp == null) return;
    setState(() => _employeeName = emp.name);
  }

  String get _name {
    final n = _user?.displayName?.trim() ?? '';
    if (n.isNotEmpty) return n;
    if (_employeeName.isNotEmpty) return _employeeName;
    final e = _user?.email ?? '';
    return e.contains('@') ? e.split('@').first : 'BeautyBook Guest';
  }

  Future<void> _editProfile() async {
    // Do NOT dispose this controller right after the sheet closes: the sheet is
    // still animating away and disposing here causes "_dependents.isEmpty is not true".
    final controller = TextEditingController(text: _name);
    final formKey = GlobalKey<FormState>();

    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: AppText.display(24)),
              const SizedBox(height: 4),
              Text('This name appears on your dashboard.',
                  style: AppText.body(14, color: AppColors.muted)),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                style: AppText.body(16),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: AppText.body(15, color: AppColors.muted),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.rose),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.sand)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.sand)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          const BorderSide(color: AppColors.rose, width: 1.4)),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Please enter your name';
                  if (t.length > 40) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext, controller.text.trim());
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );

    if (newName == null || newName == _name) return;

    setState(() => _saving = true);
    try {
      // 1) Firebase Auth display name (what this screen shows)
      await _user?.updateDisplayName(newName);

      // 2) Keep the Firestore Employee name in sync for staff/managers.
      //    If this fails (e.g. Firestore rules), the Auth update still counts.
      try {
        final emp = await RoleRepository().findEmployee(_user?.email ?? '');
        if (emp != null) {
          await FirebaseFirestore.instance
              .collection('Employee')
              .doc(emp.id)
              .update({'name': newName});
          _employeeName = newName;
        }
      } catch (_) {}

      await _user?.reload();
      if (mounted) showSnack(context, 'Profile updated ✨');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not update profile. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log out?'),
        content:
            const Text('You will need to sign in again to book appointments.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    shellTab.value = 0; // next login starts on Home
    await FirebaseAuth.instance.signOut(); // Authenticator switches to the login page
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
    final name = _name;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            Text('Profile', style: AppText.display(30)),
            const SizedBox(height: 24),
            Center(
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.rose, width: 1.6)),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.blush,
                    child: Text(name[0].toUpperCase(),
                        style: AppText.display(40, color: AppColors.rose)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name,
                    textAlign: TextAlign.center, style: AppText.display(24)),
                const SizedBox(height: 2),
                Text(email, style: AppText.body(14, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.sand)),
              child: Column(children: [
                _tile(Icons.person_outline_rounded, 'Full Name', name),
                const Divider(height: 1, indent: 64, color: AppColors.sand),
                _tile(Icons.mail_outline_rounded, 'Email', email),
                if (widget.showShortcut) ...[
                  const Divider(height: 1, indent: 64, color: AppColors.sand),
                  _tile(Icons.event_note_rounded, 'My Appointments',
                      'View your bookings',
                      onTap: () => shellTab.value = 1),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _editProfile,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.cocoa))
                  : const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: AppColors.border, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.rose, size: 20),
        ),
        title: Text(label, style: AppText.body(12.5, color: AppColors.muted)),
        subtitle: Text(value, style: AppText.body(15.5, w: FontWeight.w600)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ),
    );
  }
}