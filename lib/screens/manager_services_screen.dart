import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/manager_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/form_helpers.dart';

/// Manager: add, edit, and show or hide services.
/// Hidden services (isActive = false) no longer appear for customers.
class ManagerServicesScreen extends StatelessWidget {
  const ManagerServicesScreen({super.key});

  static void _noop() {}

  void _openForm(BuildContext context, [AdminService? service]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => _ServiceForm(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              Expanded(child: Text('Services', style: AppText.display(30))),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add'),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<AdminService>>(
              stream: repo.watchServices(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.rose));
                }
                if (snap.hasError) {
                  return const ErrorRetry(message: 'Could not load services.', onRetry: _noop);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                      child: Text('No services yet. Tap Add.',
                          style: AppText.body(15, color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = items[i];
                    return GestureDetector(
                      onTap: () => _openForm(context, s),
                      child: Opacity(
                        opacity: s.isActive ? 1 : 0.6,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.sand),
                          ),
                          child: Row(children: [
                            ServiceImage(
                                url: s.imageUrl,
                                category: 'Other',
                                width: 64,
                                height: 64,
                                radius: 16),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.display(17)),
                                const SizedBox(height: 3),
                                Text('${peso(s.price)} · ${s.duration} min',
                                    style: AppText.body(13.5, color: AppColors.rose, w: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(s.isActive ? 'Visible to customers' : 'Hidden from customers',
                                    style: AppText.body(12.5, color: AppColors.muted)),
                              ]),
                            ),
                            Switch(
                              value: s.isActive,
                              onChanged: (v) async {
                                try {
                                  await repo.setServiceActive(s.id, v);
                                } catch (_) {
                                  if (context.mounted) {
                                    showSnack(context, 'Could not update the service.');
                                  }
                                }
                              },
                            ),
                          ]),
                        ),
                      ),
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

class _ServiceForm extends StatefulWidget {
  final AdminService? service;
  const _ServiceForm({this.service});

  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _desc;
  late final TextEditingController _image;
  bool _saving = false;

  // --- image upload state ---
  XFile? _pickedImage;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name = TextEditingController(text: s?.name ?? '');
    _price = TextEditingController(text: s == null ? '' : s.price.toString());
    _duration = TextEditingController(text: s == null ? '' : s.duration.toString());
    _desc = TextEditingController(text: s?.description ?? '');
    _image = TextEditingController(text: s?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _desc.dispose();
    _image.dispose();
    super.dispose();
  }

  // --- pick + upload to Cloudinary ---
  Future<void> _pickAndUploadImage() async {
    final file = await CloudinaryService.pickImage();
    if (file == null) return;
    setState(() {
      _pickedImage = file;
      _uploadingImage = true;
    });
    final url = await CloudinaryService.upload(file);
    if (!mounted) return;
    setState(() => _uploadingImage = false);
    if (url == null) {
      showSnack(context, 'Image upload failed. Please try again.');
      return;
    }
    _image.text = url; // saved with the rest of the form
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminRepository().saveService(
        id: widget.service?.id,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        price: num.parse(_price.text.trim()),
        duration: int.parse(_duration.text.trim()),
        imageUrl: _image.text.trim(),
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
    final editing = widget.service != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'Edit Service' : 'Add Service', style: AppText.display(24)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: formDecoration('Service name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: formDecoration('Price (₱)'),
                    validator: (v) {
                      final n = num.tryParse(v?.trim() ?? '');
                      return (n == null || n <= 0) ? 'Enter a price' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: formDecoration('Minutes'),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return (n == null || n <= 0) ? 'Enter minutes' : null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: formDecoration('Description'),
              ),
              const SizedBox(height: 12),

              // --- photo picker replaces the old "Image link" field ---
              Text('Service photo', style: AppText.body(13.5, color: AppColors.muted)),
              const SizedBox(height: 8),
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _pickedImage != null
                      ? (kIsWeb
                          ? Image.network(_pickedImage!.path, width: 84, height: 84, fit: BoxFit.cover)
                          : Image.file(File(_pickedImage!.path), width: 84, height: 84, fit: BoxFit.cover))
                      : (_image.text.isEmpty
                          ? Container(
                              width: 84,
                              height: 84,
                              color: AppColors.sand,
                              child: const Icon(Icons.image_outlined, color: AppColors.rose),
                            )
                          : Image.network(_image.text,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(width: 84, height: 84, color: AppColors.sand))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadingImage ? null : _pickAndUploadImage,
                    icon: _uploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_rounded, size: 18),
                    label: Text(_uploadingImage ? 'Uploading...' : 'Choose Photo'),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_saving || _uploadingImage) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cream))
                    : Text(editing ? 'Save Changes' : 'Add Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}