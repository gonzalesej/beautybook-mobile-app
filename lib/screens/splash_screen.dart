import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../auth/register.dart';
import '../theme/app_theme.dart';
import '../widgets/beauty_logo.dart';

/// Optional: add a salon photo to assets/images/ (declare it in pubspec.yaml)
/// and set the path here, e.g. 'assets/images/salon.jpg'.
const String? kSplashAsset = null;

/// First screen a signed-out user sees.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (kSplashAsset != null)
            Image.asset(kSplashAsset!, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.background, Color(0xFFFCEEF1)],
                ),
              ),
            ),
          if (kSplashAsset != null) Container(color: AppColors.background.withAlpha(200)),
          // soft decorative circles
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 230,
              height: 230,
              decoration:
                  BoxDecoration(color: AppColors.primary.withAlpha(60), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration:
                  BoxDecoration(color: AppColors.accent.withAlpha(45), shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // arch frame with the text logo
                      Container(
                        width: 230,
                        height: 250,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(115), bottom: Radius.circular(26)),
                          border: Border.all(color: AppColors.primary.withAlpha(90), width: 1.4),
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const BeautyLogo(size: 34, light: false, showTagline: true),
                      ),
                      const Spacer(),
                      Text('Look Good.\nFeel Great.',
                          textAlign: TextAlign.center,
                          style:
                              AppText.display(38, color: AppColors.textPrimary, w: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Text('Salon Appointment & Service Management',
                          textAlign: TextAlign.center,
                          style: AppText.body(14, color: AppColors.textSecondary)),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.white),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('Get Started'),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: AppText.body(14, color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: AppText.body(14,
                                        color: AppColors.primaryDark, w: FontWeight.w700)
                                    .copyWith(decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}