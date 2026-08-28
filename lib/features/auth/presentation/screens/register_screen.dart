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

/// Register Screen — Daftar akun baru
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateOfBirth == null) {
      SnackbarUtils.showError(context, 'Tanggal lahir wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // 2. Lanjut daftar ke Supabase Auth
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'date_of_birth': _selectedDateOfBirth!.toIso8601String().split(
            'T',
          )[0],
        },
      );

      if (mounted) {
        // 3. Trik khusus Supabase: Jika identities kosong, berarti emailnya SUDAH terdaftar!
        if (response.user != null &&
            response.user!.identities != null &&
            response.user!.identities!.isEmpty) {
          SnackbarUtils.showInfo(
            context,
            'Email sudah terdaftar. Silakan login',
          );
          return;
        }

        if (response.session == null) {
          // Email confirmation is enabled
          SnackbarUtils.showSuccess(context, 'Cek email untuk verifikasi');
          context.go(RouteNames.login);
        } else {
          // Auto login (email confirmation disabled)
          SnackbarUtils.showSuccess(
            context,
            'Akun berhasil dibuat! Selamat datang 🎉',
          );
          if (mounted) context.go('${RouteNames.splash}?skip_delay=true');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, AppErrorHandler.getMessage(e));
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
      debugPrint('Error Register Google: $e');
      await GoogleSignIn().signOut();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
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
                      'Halo, salam kenal!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Langkah pertamamu buat mulai peduli sama negara.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Raka Pratama',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Tanggal Lahir
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        hintText: 'Pilih tanggal lahir',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixText: _selectedDateOfBirth != null
                            ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                            : null,
                      ),
                      controller: TextEditingController(
                        text: _selectedDateOfBirth != null
                            ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                            : '',
                      ),
                      validator: (v) => _selectedDateOfBirth == null
                          ? 'Tanggal lahir wajib diisi'
                          : null,
                      readOnly: true,
                      onTap: () async {
                        final now = DateTime.now();
                        final initialDate =
                            _selectedDateOfBirth ??
                            DateTime(now.year - 20, now.month, now.day);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(1950),
                          lastDate: now,
                          helpText: 'Pilih Tanggal Lahir',
                          cancelText: 'Batal',
                          confirmText: 'OK',
                        );
                        if (picked != null) {
                          setState(() => _selectedDateOfBirth = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'mahasiswa@kampus.ac.id',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email wajib diisi';
                        if (!v.contains('@')) return 'Format email tidak valid';

                        final lower = v.toLowerCase().trim();
                        if (!lower.endsWith('.ac.id') &&
                            !lower.endsWith('.edu')) {
                          return 'Hanya menerima email mahasiswa (.ac.id / .edu)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimal 6 karakter',
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
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.p32),

                    // Register Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Daftar Sekarang'),
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
                            const Text('Daftar dengan Google'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p32),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: AppTextStyles.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: Text(
                            'Masuk di sini',
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
