import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/beauty_logo.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  String errorMessage = '';

  Future<void> register() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    // Check required fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    // Check password match
    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Create Firebase account (same as before)
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the user's name in Firebase Authentication (same as before)
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      // Firebase signs the new user in automatically, so Authenticator
      // already shows the dashboard. Close the pages on top of it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already registered.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else {
          errorMessage = e.message ?? 'Registration failed.';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BeautyLogo(size: 30)),
                  const SizedBox(height: 28),
                  Text('Create Account', style: AppText.display(32)),
                  const SizedBox(height: 6),
                  Text('Join BeautyBook and pamper yourself.',
                      style: AppText.body(15, color: AppColors.muted)),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: hidePassword,
                    textInputAction: TextInputAction.next,
                    suffix: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_reset_rounded,
                    obscure: hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => register(),
                    suffix: IconButton(
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword = !hideConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthError(errorMessage),
                  FilledButton(
                    onPressed: isLoading ? null : register,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: AppColors.cream),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: AppText.body(14, color: AppColors.muted)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}