import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Temporary text-only logo. Replace with your own image logo later if you like.
class BeautyLogo extends StatelessWidget {
  final double size; // font size of the wordmark
  final bool light; // true on dark backgrounds
  final bool showTagline;
  const BeautyLogo({super.key, this.size = 32, this.light = false, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    final main = light ? AppColors.cream : AppColors.cocoa;
    final accent = light ? AppColors.blush : AppColors.rose;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Beauty', style: AppText.display(size, color: main, w: FontWeight.w500)),
            TextSpan(
              text: 'Book',
              style: AppText.display(size, color: accent, w: FontWeight.w500)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ]),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text('SALON  ·  STUDIO',
              style: AppText.body(size * 0.3, color: accent, w: FontWeight.w600)
                  .copyWith(letterSpacing: 3)),
        ],
      ],
    );
  }
}