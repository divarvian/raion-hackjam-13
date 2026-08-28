import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/supabase_service.dart';

/// Login Screen — Email/Password + Google Sign-In
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail(String email) async {
    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Link verifikasi baru telah dikirim!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, AppErrorHandler.getMessage(e));
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) context.go('${RouteNames.splash}?skip_delay=true');
    } on AuthException catch (e) {
      if (mounted) {
        if (e.code == 'email_not_confirmed') {
          final email = _emailController.text.trim();
          SnackbarUtils.showError(
            context,
            AppErrorHandler.getMessage(e),
            action: SnackBarAction(
              label: 'Kirim Ulang',
              textColor: Colors.white,
              onPressed: () => _resendEmail(email),
            ),
          );
        } else {
          SnackbarUtils.showError(context, AppErrorHandler.getMessage(e));
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, AppErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // User membatalkan login
      }

      final email = googleUser.email.toLowerCase().trim();
      if (!email.endsWith('.ac.id') && !email.endsWith('.edu')) {
        await googleSignIn.signOut();
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Gunakan email mahasiswa (.ac.id / .edu)',
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Gagal mendapatkan akses token dari Google.');
      }

      await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) context.go('${RouteNames.splash}?skip_delay=true');
    } catch (e) {
      debugPrint('Error Login Google: $e');
      await GoogleSignIn()
          .signOut(); // Clear cached account so user can pick again
      if (mounted) {
        SnackbarUtils.showError(context, AppErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.55, 1.0],
                  colors: [
                    Color(0xFF7F1D1D),
                    Color(0xFFC41E1E),
                    Color(0xFFEF4444),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/mascot_hi.png',
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Halo, selamat datang kembali!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sudah siap ngawal kebijakan hari ini?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'emailkamu@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // Login Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _signInWithEmail,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('atau', style: AppTextStyles.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Google Sign-In Button
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isGoogleLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              SvgPicture.asset(
                                'assets/icons/google_logo.svg',
                                width: 20,
                                height: 20,
                              ),
                            const SizedBox(width: 12),
                            const Text('Masuk dengan Google'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p32),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: AppTextStyles.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.go(RouteNames.register),
                          child: Text(
                            'Daftar sekarang',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
