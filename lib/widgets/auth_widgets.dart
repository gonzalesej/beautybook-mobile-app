import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: AppText.body(16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body(15, color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.rose, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: border(AppColors.sand),
        focusedBorder: border(AppColors.rose, 1.6),
        border: border(AppColors.sand),
      ),
    );
  }
}

class AuthError extends StatelessWidget {
  final String message;
  const AuthError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9E1E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFB04A4A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppText.body(13.5, color: const Color(0xFFB04A4A), w: FontWeight.w500)),
        ),
      ]),
    );
  }
}