import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/beauty_logo.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  String errorMessage = '';

  Future<void> checkLogin(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Same Firebase email/password login as before.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (!mounted) return;

      // Authenticator shows the dashboard automatically once signed in.
      // Close the Splash/Login pages that are sitting on top of it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email.';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid email or password.';
        } else {
          errorMessage = e.message ?? 'Login failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Something went wrong.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> forgotPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() {
        errorMessage = 'Enter your email above, then tap Forgot Password.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Could not send reset email.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  const Center(child: BeautyLogo(size: 34)),
                  const SizedBox(height: 36),
                  Text('Welcome Back', style: AppText.display(32)),
                  const SizedBox(height: 6),
                  Text('Sign in to book your next visit.',
                      style: AppText.body(15, color: AppColors.muted)),
                  const SizedBox(height: 28),
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
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => checkLogin(_emailController.text, _passwordController.text),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  AuthError(errorMessage),
                  FilledButton(
                    onPressed: isLoading
                        ? null
                        : () => checkLogin(_emailController.text, _passwordController.text),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: AppColors.cream),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: AppText.body(14, color: AppColors.muted)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w700)),
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