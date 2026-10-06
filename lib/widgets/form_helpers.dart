import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

InputDecoration formDecoration(String label, {String? hint}) {
  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: AppText.body(15, color: AppColors.muted),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: border(AppColors.sand),
    enabledBorder: border(AppColors.sand),
    focusedBorder: border(AppColors.rose, 1.6),
  );
}