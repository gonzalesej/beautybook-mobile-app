import 'package:flutter/material.dart';
import '../services/manager_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/form_helpers.dart';

/// Manager: add, edit and remove beauticians (Employee documents with role 'staff').
class ManagerStaffScreen extends StatelessWidget {
  const ManagerStaffScreen({super.key});

  static void _noop() {}

  void _openForm(BuildContext context, [AdminStaff? staff]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => _StaffForm(staff: staff),
    );
  }

  Future<void> _delete(BuildContext context, AdminStaff s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Remove this beautician?'),
        content: Text('${s.name} will no longer appear when customers book. '
            'Existing bookings are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminRepository().deleteStaff(s.id);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not remove. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              Expanded(child: Text('Staff', style: AppText.display(30))),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add'),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<AdminStaff>>(
              stream: AdminRepository().watchStaff(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.rose));
                }
                if (snap.hasError) {
                  return const ErrorRetry(message: 'Could not load staff.', onRetry: _noop);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                      child: Text('No beauticians yet. Tap Add.',
                          style: AppText.body(15, color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.sand),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.blush,
                          child: Text(s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                              style: AppText.display(22, color: AppColors.rose)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, style: AppText.display(18)),
                            Text(s.position.isEmpty ? 'Beautician' : s.position,
                                style: AppText.body(13.5, color: AppColors.rose, w: FontWeight.w600)),
                            Text(s.email.isEmpty ? 'No login email' : s.email,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(12.5, color: AppColors.muted)),
                          ]),
                        ),
                        IconButton(
                          onPressed: () => _openForm(context, s),
                          icon: const Icon(Icons.edit_outlined, color: AppColors.cocoa),
                        ),
                        IconButton(
                          onPressed: () => _delete(context, s),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _StaffForm extends StatefulWidget {
  final AdminStaff? staff;
  const _StaffForm({this.staff});

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _position;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff?.name ?? '');
    _position = TextEditingController(text: widget.staff?.position ?? '');
    _email = TextEditingController(text: widget.staff?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _position.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminRepository().saveStaff(
        id: widget.staff?.id,
        name: _name.text.trim(),
        position: _position.text.trim(),
        email: _email.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.staff != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'Edit Beautician' : 'Add Beautician', style: AppText.display(24)),
              const SizedBox(height: 4),
              Text('The name must match what shows on bookings.',
                  style: AppText.body(13.5, color: AppColors.muted)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: formDecoration('Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _position,
                textCapitalization: TextCapitalization.words,
                decoration: formDecoration('Position (e.g. Hair Stylist)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: formDecoration('Login email (optional)',
                    hint: 'Only if they will log in to the staff app'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  return (t.isNotEmpty && !t.contains('@')) ? 'Enter a valid email' : null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cream))
                    : Text(editing ? 'Save Changes' : 'Add Beautician'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}