import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.outlined = false});

  @override
  Widget build(BuildContext context) => outlined
      ? OutlinedButton(onPressed: onPressed, child: Text(label))
      : FilledButton(onPressed: onPressed, child: Text(label));
}

/// Status shown as plain colored text (no bubble).
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        break;
      case 'completed':
        color = AppColors.textSecondary;
        break;
      case 'cancelled':
      case 'declined':
      case 'no-show':
        color = AppColors.error;
        break;
      default:
        color = AppColors.primary;
    }
    final label = switch (status) {
      'no-show' => 'No-Show',
      '' => '',
      _ => status[0].toUpperCase() + status.substring(1),
    };
    return Text(label, style: AppText.body(13, color: color, w: FontWeight.w700));
  }
}

IconData categoryIcon(String c) {
  switch (c) {
    case 'Hair':
      return Icons.content_cut_rounded;
    case 'Nails':
      return Icons.back_hand_outlined;
    case 'Skin':
      return Icons.face_retouching_natural;
    case 'Massage':
      return Icons.spa_outlined;
    default:
      return Icons.auto_awesome_outlined;
  }
}

class ServiceImage extends StatelessWidget {
  final String url;
  final String category;
  final double? width;
  final double? height;
  final double radius;
  const ServiceImage({
    super.key,
    required this.url,
    required this.category,
    this.width,
    this.height,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.border,
      child: Icon(categoryIcon(category), color: AppColors.primary, size: 32),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? placeholder
          : Image.network(url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (c, child, p) => p == null ? child : placeholder),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppText.body(15, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}