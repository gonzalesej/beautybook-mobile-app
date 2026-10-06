import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'book_appointment_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceItem service;
  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 360,
          child: ServiceImage(
              url: service.imageUrl, category: service.category, height: 360, radius: 0),
        ),
        Positioned.fill(
          top: 310,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(service.category,
                    style: AppText.body(13, color: AppColors.rose, w: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(service.name, style: AppText.display(30)),
                const SizedBox(height: 18),
                Row(children: [
                  _info(Icons.schedule_rounded, 'Duration', '${service.duration} min'),
                  const SizedBox(width: 12),
                  _info(Icons.sell_outlined, 'Price', peso(service.price)),
                ]),
                const SizedBox(height: 24),
                Text('About this service', style: AppText.display(20)),
                const SizedBox(height: 8),
                Text(
                    service.description.isEmpty
                        ? 'No description available.'
                        : service.description,
                    style: AppText.body(15.5, color: AppColors.muted)),
              ]),
            ),
          ),
        ),
        Positioned(
          top: top + 8,
          left: 20,
          child: RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: SafeArea(
            child: PrimaryButton(
              label: 'Book Appointment',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BookAppointmentScreen(service: service))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sand)),
        child: Row(children: [
          Icon(icon, color: AppColors.rose),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppText.body(12, color: AppColors.muted)),
            Text(value, style: AppText.body(16, w: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }
}